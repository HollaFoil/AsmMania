.global load_config

config: .asciz "config.txt"

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
    # -16(%rbp) pointer to hitsound file name
    # -24(%rbp) the offset
    # -32(%rbp) pointer to song file name
    # -40(%rbp) read_bytes for map file
    # -48(%rbp) pointer to allocated memory for hit objects
    # -56(%rbp) read_bytes for wav file
    # -64(%rbp) pointer to allocated memory for music wav bytes
    # -72(%rbp) preview_time

    pushq %rbp
    movq %rsp, %rbp

    subq $80, %rsp

    movq %rdi, -8(%rbp)

    # read the config file
    leaq -16(%rbp), %rsi
    movq $config, %rdi
    call read_file
    testq %rax, %rax
    jz read_failed

    # decode the string
    leaq -32(%rbp), %rsi
    movq %rax, %rdi
    call decode_config

    # read the map file and place it into memory
    leaq -40(%rbp), %rsi
    movq %rax, %rdi
    call read_file
    testq %rax, %rax
    jz read_failed
    movq (%rax), %rdi # copy the preview_time
    movq %rdi, -72(%rbp)
    addq $8, %rax # move the pointer to hit objects
    movq %rax, -48(%rbp)
    

    # read the wav file and place it into memory
    leaq -56(%rbp), %rsi
    movq -32(%rbp), %rdi
    call read_file
    testq %rax, %rax
    jz read_failed
    movq %rax, -64(%rbp)

    # divide read_bytes of map file by 16 to get the number of hit objects
    movq -40(%rbp), %rax
    shr $4, %rax # 16 = 2^4 so just shift bits to the left by 4
    
    # finally return everything
    
    movq -8(%rbp), %rdi # get the address of return struct
    movq %rax, (%rdi) # return number of hit objects

    movq -64(%rbp), %rax
    movq %rax, 8(%rdi)

    movq -56(%rbp), %rax
    movq %rax, 16(%rdi)

    movq -24(%rbp), %rax
    movq %rax, 24(%rdi)

    movq -72(%rbp), %rax
    movq %rax, 32(%rdi)

    movq -48(%rbp), %rax

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
decode_config:
# stack:
# -8(%rbp) stores arg %rsi
# -16(%rbp) stores arg %rdi
# -24(%rbp) stores pointer to map file name
    pushq %rbp
    movq %rsp, %rbp

    movq %rsi, -8(%rbp)
    movq %rdi, -16(%rbp)
    
    subq $32, %rsp

    leaq -16(%rbp), %rdi
    call get_next_variable
    movq %rax, -24(%rbp) # temporarily save pointer to map file name

    leaq -16(%rbp), %rdi
    call get_next_variable
    movq -8(%rbp), %rsi
    movq %rax, (%rsi) # return the pointer to wav file name
    
    # get offset convert it to an integer
    leaq -16(%rbp), %rdi
    call get_next_variable 
    movq %rax, %rdi
    call convert_string_to_int
    movq -8(%rbp), %rsi
    movq %rax, 8(%rsi) # return the offset

    movq -24(%rbp), %rax # move map file pointer to %rax
    
    movq %rbp, %rsp
    popq %rbp
    ret

# argument: address of pointer to config, which gets updated
# returns a pointer to the next variable in %rax
get_next_variable:
    pushq %rbp
    movq %rsp, %rbp
    
    skip_to_string_start_loop:
        movq (%rdi), %rsi
        movb (%rsi), %dl
        incq (%rdi)
        cmpb $58, %dl # check if :
        jne skip_to_string_start_loop
        
    movq (%rdi), %rax # save the pointer to string

    skip_to_string_end_loop:
        incq (%rdi)
        movq (%rdi), %rsi
        movb (%rsi), %dl
        cmpb $10, %dl # check if \n
        jne skip_to_string_end_loop

    # replace the newline with a null byte so that the relevant info becomes a string :D
    movq (%rdi), %rsi
    movb $0, (%rsi)
    incq (%rdi) # move pointer to the next line

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
