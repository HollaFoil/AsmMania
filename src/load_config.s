.global load_config

config: .asciz "config.txt"
song_string: .asciz "/audio.wav"
song_string_end: .equ song_string_len, song_string_end - song_string
metadata_string: .asciz "/metadata.txt"
metadata_string_end: .equ metadata_string_len, metadata_string_end - metadata_string
map_string: .asciz "/map"
map_string_end: .equ map_string_len, map_string_end - map_string - 1
sus_string: .asciz ".sus"
sus_string_end: .equ sus_string_len, sus_string_end - sus_string
malloc_error_msg: .asciz "Error while decoding the config file"


# this function reads the config and loads the specified files to allocated
# memory and returns a struct of 4 quadwords:
# %rax pointer to a list of hit objects
# (%rdi) number of hit objects
# 8(%rdi) pointer to song file in memory
# 16(%rdi) size of song wav in bytes
# 24(%rdi) offset
# 32(%rdi) preview_time
# 40(%rdi) pointer to hit sound file in memory
# 48(%rdi) size of hitsound wav file in bytes

load_config:
    # stack:
    # -8(%rbp) pointer to return struct
    # -16(%rbp) read_bytes of metadata
    # -24(%rbp) metadata.txt
    # -32(%rbp) volume
    # -40(%rbp) pointer to hitsound file name
    # -48(%rbp) the offset
    # -56(%rbp) pointer to song file name
    # -64(%rbp) read_bytes for map file
    # -72(%rbp) pointer to allocated memory for hit objects
    # -80(%rbp) read_bytes for song file
    # -88(%rbp) pointer to allocated memory for music wav
    # -96(%rbp) preview_time
    # -104(%rbp) read_bytes for hit sound file
    # -112(%rbp) pointer to allocated memory for hit sound wav 

    pushq %rbp
    movq %rsp, %rbp

    subq $120, %rsp

    movq %rdi, -8(%rbp)

    # Read the config file
    movq $1, %rcx
    movq $0, %rdx
    leaq -64(%rbp), %rsi
    movq $config, %rdi
    call read_file
    testq %rax, %rax
    jz read_failed

    # Decode the string
    leaq -56(%rbp), %rsi
    movq %rax, %rdi
    call decode_config

    # Read the map file and place it into memory and save the pointer in stack
    movq $1, %rcx
    movq $0, %rdx
    leaq -64(%rbp), %rsi
    movq %rax, %rdi
    call read_file
    testq %rax, %rax
    jz read_failed
    # Get the preview_time (not used)
    movq (%rax), %rdi 
    movq %rdi, -96(%rbp)
    # Move the pointer to hit objects
    addq $8, %rax 
    movq %rax, -72(%rbp)

    # Read the metadata file and place it into memory and save the pointer in stack
    movq $1, %rcx
    movq $0, %rdx
    leaq -16(%rbp), %rsi
    movq -24(%rbp), %rdi
    call read_file
    testq %rax, %rax
    jz read_failed
    movq %rax, -24(%rbp)
    
    movq -16(%rbp), %rdx # how many bytes to print
    movq %rax, %rsi # load the char address
    movq $1, %rdi # 1 for stdout
    movq $1, %rax # 1 for sys_write
    syscall
    
    # Read the song.wav file, place it into memory and save the pointer in stack
    movq $1024, %rcx
    movq -48(%rbp), %rdx
    leaq -80(%rbp), %rsi
    movq -56(%rbp), %rdi
    call read_file
    testq %rax, %rax
    jz read_failed
    movq %rax, -88(%rbp)

    # Read the hit_sound file, place it into memory and save the pointer in stack
    movq $1, %rcx
    movq $0, %rdx
    leaq -104(%rbp), %rsi
    movq -40(%rbp), %rdi
    call read_file
    movq %rax, -112(%rbp) 

    movq -32(%rbp), %rdx
    movq -104(%rbp), %rsi
    movq -112(%rbp), %rdi
    call set_hit_sound_volume

    # finally return everything
    movq -8(%rbp), %rdi # get the address of return struct

    # divide read_bytes of map file by 16 to get the number of hit objects
    movq -64(%rbp), %rax
    shr $4, %rax # 16 = 2^4 so just shift bits to the left by 4
    movq %rax, (%rdi) # return number of hit objects

    movq -88(%rbp), %rax
    movq %rax, 8(%rdi)

    movq -80(%rbp), %rax
    movq %rax, 16(%rdi)

    movq -48(%rbp), %rax
    movq %rax, 24(%rdi)

    movq -96(%rbp), %rax
    movq %rax, 32(%rdi)

    movq -112(%rbp), %rax
    movq %rax, 40(%rdi)

    movq -104(%rbp), %rax
    movq %rax, 48(%rdi)

    movq -24(%rbp), %rax
    movq %rax, 56(%rdi)

    movq -16(%rbp), %rax
    movq %rax, 64(%rdi)

    movq -72(%rbp), %rax

    movq %rbp, %rsp
    popq %rbp
    ret

read_failed:
    # return 0
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    ret

# returns pointer to the first relevant character in specified line
# and the length of the string
# arguments:
# %rdi config string pointer
# %rsi address for returning struct
# return:
# %rax pointer to map file name
# (%rsi) pointer to song file name
# 8(%rsi) the offset
# 16(%rsi) pointer to hitsound file name
# 24(%rsi) volume
# 32(%rsi) metadata.txt
decode_config:
    # stack:
    # -8(%rbp) stores arg %rsi
    # -16(%rbp) stores arg %rdi
    # -24(%rbp) stores pointer to map folder name
    # -32(%rbp) folder path length
    # -40(%rbp) map variant
    pushq %rbp
    movq %rsp, %rbp

    movq %rsi, -8(%rbp)
    movq %rdi, -16(%rbp)
    
    subq $48, %rsp

    # Get the pointer to map folder name and save it in stack
    leaq -16(%rbp), %rdi
    call get_next_variable
    movq %rax, -24(%rbp)

    # Move the pointer to a null byte
    subq $32, %rax # set up the pointer
    loop_scan:
        addq $32, %rax # increment the pointer by 32 bytes
        vpxor %ymm0, %ymm0, %ymm0 # make a mask of 0s
        vpcmpeqb (%rax), %ymm0, %ymm0 # this instruct sets a corresponding byte in %ymm0 to 1s if there is a cell of 0s
        vpmovmskb %ymm0, %r8 # move the MSB bit of every byte to a general register
        
        testl %r8d, %r8d # check if we found a 0 cell, by checking if there are any bits set to 1
        jz loop_scan # continue the loop if not

    bsf %r8, %r8 # find the least significant set bit
    addq %r8, %rax # add its index to cell pointer

    # Get the string length
    subq -24(%rbp), %rax
    movq %rax, -32(%rbp)

    # Get the map variant
    leaq -16(%rbp), %rdi
    call get_next_variable
    movq %rax, -40(%rbp)
    
    # allocate memory for song path
    movq -32(%rbp), %rdi
    addq $song_string_len, %rdi
	call malloc
	test %rax, %rax
	jz malloc_failed
    movq -8(%rbp), %rsi
	movq %rax, (%rsi)

    movq %rax, %rdx
    pushq $song_string
    movq -24(%rbp), %rdi
    pushq %rdi
    movq %rsp, %rsi 
    movq $2, %rdi
    call concatenate_string

    # allocate memory for metadata path
    movq -32(%rbp), %rdi
    addq $metadata_string_len, %rdi
	call malloc
	test %rax, %rax
	jz malloc_failed
    movq -8(%rbp), %rsi
	movq %rax, 32(%rsi)

    movq %rax, %rdx
    pushq $metadata_string
    movq -24(%rbp), %rdi
    pushq %rdi
    movq %rsp, %rsi
    movq $2, %rdi
    call concatenate_string
    
    # Get offset, convert it to an integer and return it
    leaq -16(%rbp), %rdi
    call get_next_variable 
    movq %rax, %rdi
    call convert_string_to_int
    movq -8(%rbp), %rsi
    movq %rax, 8(%rsi)

    # Get hit sound file path
    leaq -16(%rbp), %rdi
    call get_next_variable 
    movq -8(%rbp), %rsi
    movq %rax, 16(%rsi)

    # Get volume, convert it to an integer and return it
    leaq -16(%rbp), %rdi
    call get_next_variable 
    movq %rax, %rdi
    call convert_string_to_int
    movq -8(%rbp), %rsi
    movq %rax, 24(%rsi)

    # allocate memory for map path
    movq -32(%rbp), %rdi
    addq $map_string_len, %rdi
    addq $1, %rdi
    addq $sus_string_len, %rdi
	call malloc
	test %rax, %rax
	jz malloc_failed
	movq %rax, -48(%rbp)

    movq %rax, %rdx
    pushq $sus_string
    pushq -40(%rbp)
    pushq $map_string
    movq -24(%rbp), %rdi
    pushq %rdi
    movq %rsp, %rsi
    movq $4, %rdi
    call concatenate_string

    movq -48(%rbp), %rax

    movq %rbp, %rsp
    popq %rbp
    ret

    malloc_failed:
    movq $malloc_error_msg, %rdi
    movq $0, %rax
    call printf
    movq $-1, %rdi
    call exit

# %rdi - how many strings
# (%rsi) - struct of strings
# (%rdx) - allocated memory address for the new string
concatenate_string:
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rax
    loop_concatenate_string:
        movq (%rsi, %rax, 8), %rcx 
        loop_copy_char:
            movb (%rcx), %r8b
            movb %r8b, (%rdx)
            incq %rdx
            incq %rcx
            cmpb $0, (%rcx)
            jne loop_copy_char
        incq %rax
        cmpq %rdi, %rax
        jne loop_concatenate_string

    movb $0, (%rdx)
    movq %rbp, %rsp
    popq %rbp
    ret


# Argument: address of pointer to config, which gets updated
# Returns a pointer to the next variable in %rax
get_next_variable:
    pushq %rbp
    movq %rsp, %rbp
    
    skip_to_string_start_loop:
        movq (%rdi), %rsi
        movb (%rsi), %dl
        incq (%rdi)
        # check if char is ':'
        cmpb $58, %dl 
        jne skip_to_string_start_loop
    
    # Save the pointer to string
    movq (%rdi), %rax

    skip_to_string_end_loop:
        incq (%rdi)
        movq (%rdi), %rsi
        movb (%rsi), %dl
        cmpb $10, %dl # check if \n
        jne skip_to_string_end_loop

    # Replace the newline with a null byte so that the relevant info becomes a string :D
    movq (%rdi), %rsi
    movb $0, (%rsi)
    # Move pointer to the next line
    incq (%rdi) 

    movq %rbp, %rsp
    popq %rbp
    ret

convert_string_to_int:
    pushq %rbp
    movq %rsp, %rbp

    xorq %rax, %rax # set %rax to 0
    xorq %rdx, %rdx # set %rdx to 0
    movq $10, %r8 # initialize the multiplicant

    convert_loop:
        imulq %r8 # push all digits to the left
        movzxb (%rdi), %rcx # get char
        subq $48, %rcx # convert char to a digit
        addq %rcx, %rax # set the first digit
        incq %rdi
        cmpb $0, (%rdi) # check if string ended
        jne convert_loop

    movq %rbp, %rsp
    popq %rbp
    ret
