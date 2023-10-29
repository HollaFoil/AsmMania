.global load_config
.global load_map

config: .asciz "config.txt"
song_string: .asciz "audio.wav"
song_string_end: .equ song_string_len, song_string_end - song_string
metadata_string: .asciz "metadata.txt"
metadata_string_end: .equ metadata_string_len, metadata_string_end - metadata_string
map_string: .asciz "map"
map_string_end: .equ map_string_len, map_string_end - map_string - 1
sus_string: .asciz ".sus"
sus_string_end: .equ sus_string_len, sus_string_end - sus_string
malloc_error_msg: .asciz "Error while decoding the config file"
highscore_string: .asciz "highscore.txt"
highscore_string_end: .equ highscore_string_len, highscore_string_end - highscore_string - 1
txt_string: .asciz ".txt"
txt_string_end: .equ txt_string_len, txt_string_end - txt_string


# This function loads the config.txt parameters
# return struct:
# %rax offset
# (%rdi) read_bytes for hit sound file
# 8(%rdi) pointer to allocated memory for hit sound wav
load_config:
    # stack:
    # -8(%rbp) return address
    # -16(%rbp) volume
    # -24(%rbp) offset
    # -32(%rbp) read_bytes for hit sound file
    # -40(%rbp) pointer to allocated memory for hit sound wav
    # -48(%rbp) pointer to memory allocated for config file
    pushq %rbp
    movq %rsp, %rbp
    movq %rdi, -8(%rbp)

    subq $48, %rsp

    # Read the config file
    movq $1, %rcx
    movq $0, %rdx
    movq %rsp, %rsi
    movq $config, %rdi
    call read_file
    testq %rax, %rax
    jz read_failed
    movq %rax, -48(%rbp)

    # Decode the string
    leaq -24(%rbp), %rsi
    movq %rax, %rdi
    call decode_config

    # Read the hit_sound file, place it into memory and save the pointer in stack
    movq $1, %rcx
    movq $0, %rdx
    leaq -32(%rbp), %rsi
    movq %rax, %rdi
    call read_file
    movq %rax, -40(%rbp) 

    # Set the volume
    movq -16(%rbp), %rdx
    movq -32(%rbp), %rsi
    movq -40(%rbp), %rdi
    call set_hit_sound_volume

    # Deallocate memory of config file
    movq -48(%rbp), %rdi
    call free

    # Return the hit sound file and size
    movq -8(%rbp), %rdi
    movq -32(%rbp), %rax
    movq %rax, (%rdi)
    movq -40(%rbp), %rax
    movq %rax, 8(%rdi)
    movq -24(%rbp), %rax

    movq %rbp, %rsp
    popq %rbp
    ret

# This function loads the specified map
# args:
# %rdi - address to return the struct
# %rsi - map folder name
# %rdx - beatmap variant
# return struct:
# %rax pointer to a list of hit objects
# (%rdi) number of hit objects
# 8(%rdi) pointer to song file in memory
# 16(%rdi) size of song wav in bytes
# 24(%rdi) metadata
# 32(%rdi) metadata size
# 40(%rdi) highscore file name
# 48(%rdi) max combo
# 56(%rdi) highscore
# 64(%rdi) highest accuracy
load_map:
    # stack:
    # -8(%rbp) pointer to return struct
    # -16(%rbp) map folder name
    # -24(%rbp) beatmap variant
    # -32(%rbp) metadata file
    # -40(%rbp) metada size
    # -48(%rbp) read_bytes for map file
    # -56(%rbp) pointer to allocated memory for hit objects
    # -64(%rbp) read_bytes for song file
    # -72(%rbp) pointer to allocated memory for music wav
    # -80(%rbp) highscore file
    # -88(%rbp) highscore file size
    # -96(%rbp) highscore file name
    # -104(%rbp) temp name pointer
    pushq %rbp
    movq %rsp, %rbp

    pushq %rdi
    pushq %rsi
    pushq %rdx

    subq $88, %rsp

    # Concatenate the map folder and variant name strings
    pushq $sus_string
    pushq %rdx
    pushq %rsi
    movq %rsp, %rsi
    movq $3, %rdi
    call concatenate_string
    addq $24, %rsp
    movq %rax, -104(%rbp)

    # Read the map file and place it into memory and save the pointer in stack
    movq $1, %rcx
    movq $0, %rdx
    leaq -48(%rbp), %rsi
    movq %rax, %rdi
    call read_file
    testq %rax, %rax
    jz read_failed
    # Move the pointer to hit objects
    addq $8, %rax
    movq %rax, -56(%rbp)

    # Deallocate memory of string
    movq -104(%rbp), %rdi
    call free

    # Concatenate the full metadata name
    pushq $metadata_string
    pushq -16(%rbp)
    movq %rsp, %rsi
    movq $2, %rdi
    call concatenate_string
    addq $16, %rsp
    movq %rax, -104(%rbp)

    # Read the metadata file and return it
    movq $1, %rcx
    movq $0, %rdx
    leaq -40(%rbp), %rsi
    movq %rax, %rdi
    call read_file
    testq %rax, %rax
    jz read_failed
    movq %rax, -32(%rbp)

    # Deallocate memory of string
    movq -104(%rbp), %rdi
    call free
    
    # Print the metadata to terminal
    movq -40(%rbp), %rdx # how many bytes to print
    movq %rax, %rsi # load the char address
    movq $1, %rdi # 1 for stdout
    movq $1, %rax # 1 for sys_write
    syscall

    
    # Concatenate the full highscore name
    pushq $highscore_string
    pushq -24(%rbp)
    pushq -16(%rbp)
    movq %rsp, %rsi
    movq $3, %rdi
    call concatenate_string
    addq $24, %rsp
    movq %rax, -96(%rbp)

    # Read the highscore file and place it into memory
    movq $1, %rcx
    movq $0, %rdx
    leaq -88(%rbp), %rsi
    movq %rax, %rdi
    call read_file
    testq %rax, %rax
    jnz highscore_file_exists

    # Set the highscore and max combo to zero
    movq -8(%rbp), %rdi
    movq $0, 48(%rdi)
    movq $0, 56(%rdi)
    movq $0, 64(%rdi)
    jmp skip_reading_highscore_file

    highscore_file_exists:
    # Put the pointer to highscore file contents in stack
    movq %rax, -80(%rbp)
    movq %rax, -104(%rbp)

    # Get max combo and return it
    leaq -80(%rbp), %rdi
    call get_next_variable 
    movq %rax, %rdi
    call convert_string_to_int
    movq -8(%rbp), %rdi
    movq %rax, 48(%rdi)

    # Get highscore and return it
    leaq -80(%rbp), %rdi
    call get_next_variable 
    movq %rax, %rdi
    call convert_string_to_int
    movq -8(%rbp), %rdi
    movq %rax, 56(%rdi)

    # Get highest accuracy and return it
    leaq -80(%rbp), %rdi
    call get_next_variable 
    movq %rax, %rdi
    call convert_string_to_int
    movq -8(%rbp), %rdi
    movq %rax, 64(%rdi)

    # Deallocate memory of highscore file
    movq -104(%rbp), %rdi
    call free

    skip_reading_highscore_file:
    # Concatenate the song file name
    pushq $song_string
    pushq -16(%rbp)
    movq %rsp, %rsi
    movq $2, %rdi
    call concatenate_string
    addq $16, %rsp
    
    # Read the song.wav file, place it into memory and save the pointer in stack
    movq $1024, %rcx
    movq $0, %rdx
    leaq -64(%rbp), %rsi
    movq %rax, %rdi
    call read_file
    testq %rax, %rax
    jz read_failed
    movq %rax, -72(%rbp)

    # Finally return everything
    movq -8(%rbp), %rdi

    # Divide read_bytes of map file by 16 to get the number of hit objects
    movq -48(%rbp), %rax
    shrq $4, %rax # 16 = 2^4 so just shift bits to the right by 4
    movq %rax, (%rdi)

    movq -72(%rbp), %rax
    movq %rax, 8(%rdi)

    movq -64(%rbp), %rax
    movq %rax, 16(%rdi)

    movq -32(%rbp), %rax
    movq %rax, 24(%rdi)

    movq -40(%rbp), %rax
    movq %rax, 32(%rdi)
    
    movq -96(%rbp), %rax
    movq %rax, 40(%rdi)

    movq -56(%rbp), %rax

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
# %rdi config file
# %rsi address for returning struct
# return:
# %rax - hit sound file name
# (%rsi) the offset
# 8(%rsi) volume
decode_config:
    # stack:
    # -8(%rbp) address for returning struct
    # -16(%rbp) config
    # -24(%rbp) stores hit sound file name
    pushq %rbp
    movq %rsp, %rbp

    movq %rsi, -8(%rbp)
    movq %rdi, -16(%rbp)
    
    subq $48, %rsp
    
    # Get offset, convert it to an integer and return it
    leaq -16(%rbp), %rdi
    call get_next_variable 
    movq %rax, %rdi
    call convert_string_to_int
    movq -8(%rbp), %rsi
    movq %rax, (%rsi)

    # Get hit sound file name
    leaq -16(%rbp), %rdi
    call get_next_variable 
    movq %rax, -24(%rbp)

    # Get volume, convert it to an integer and return it
    leaq -16(%rbp), %rdi
    call get_next_variable 
    movq %rax, %rdi
    call convert_string_to_int
    movq -8(%rbp), %rsi
    movq %rax, 8(%rsi)

    # Return hit sound file name
    movq -24(%rbp), %rax

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
# return - allocated memory address for the new string
concatenate_string:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rdi # -8(%rbp)
    pushq %rsi # -16(%rbp)
    movq $1, %r10 # total length

    movq $0, %rax
    loop_get_total_length:
        movq (%rsi, %rax, 8), %rcx 
        # Move the pointer to a null byte
        subq $32, %rcx # set up the pointer
        loop_scan:
            addq $32, %rcx # increment the pointer by 32 bytes
            vpxor %ymm0, %ymm0, %ymm0 # make a mask of 0s
            vpcmpeqb (%rcx), %ymm0, %ymm0 # this instruct sets a corresponding byte in %ymm0 to 1s if there is a null byte
            vpmovmskb %ymm0, %r8 # move the MSB bit of every byte to a general register
            
            testl %r8d, %r8d # check if we found a null byte, by checking if there are any bits set to 1
            jz loop_scan # continue the loop if not

        bsf %r8, %r8 # find the least significant set bit
        addq %r8, %rcx # add its index the pointer

        # Get the string length
        subq (%rsi, %rax, 8), %rcx
        addq %rcx, %r10
        incq %rax
        cmpq %rdi, %rax
        jne loop_get_total_length
    
    # Allocate memory
    movq %r10, %rdi
	call malloc
	test %rax, %rax
	jz malloc_failed
	movq %rax, %r10

    # Initiate a string counter
    movq $0, %rax
    movq -8(%rbp), %rdi
    movq -16(%rbp), %rsi
    movq %r10, %rdx
    loop_concatenate_string:
        # Get the next string
        movq (%rsi, %rax, 8), %rcx 
        # Copy the string on top of the new string
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

    # Put a null byte at the end
    movb $0, (%rdx)
    movq %r10, %rax
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
    