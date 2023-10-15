.equ BITRATE, 44100
.equ CHANNELS, 2

DEFAULT_TYPE: .asciz "default"
SONG: .asciz "b.wav"
format: .asciz "%ld\n"

.global create_pcm_handle
#.global main

create_pcm_handle:
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    pushq %rbp
    movq %rsp, %rbp

    subq $48, %rsp

    leaq -40(%rbp), %rdi
    movq $DEFAULT_TYPE, %rsi
    movq $0, %rdx
    movq $0, %rcx
    call snd_pcm_open@PLT
    movq $0, -48(%rbp)
    movl %eax, -48(%rbp)

    call snd_pcm_hw_params_sizeof@PLT
    leaq 8(%rax), %rdx
    movl $16, %eax
    subq $1, %rax
    addq %rdx, %rax
    movl $16, %ecx
    movl $0, %edx
    divq %rcx
    imulq $16, %rax, %rax
    subq %rax, %rsp
    movq %rsp, %rax
    addq $15, %rax
    shrq $4, %rax
    salq $4, %rax
    movq %rax, -32(%rbp)
    call snd_pcm_hw_params_sizeof@PLT
    movq %rax, %rdx

    movq -32(%rbp), %rdi
    movq $0, %rsi
    call memset@PLT

    movq -32(%rbp), %rsi
    movq -40(%rbp), %rdi
    call snd_pcm_hw_params_any@PLT

    movq -32(%rbp), %rsi
    movq -40(%rbp), %rdi
    movl $3, %edx
    call snd_pcm_hw_params_set_access@PLT

    movq -32(%rbp), %rsi
    movq -40(%rbp), %rdi
    movl $2, %edx
    call snd_pcm_hw_params_set_format@PLT

    movq -32(%rbp), %rsi
    movq -40(%rbp), %rdi
    movl $CHANNELS, %edx
    call snd_pcm_hw_params_set_channels@PLT

    movq -32(%rbp), %rsi
    movq -40(%rbp), %rdi
    movl $BITRATE, -48(%rbp)
    leaq -48(%rbp), %rdx
    movq $0, %rcx
    call snd_pcm_hw_params_set_rate_near@PLT

    movq -32(%rbp), %rsi
    movq -40(%rbp), %rdi
    call snd_pcm_hw_params@PLT

    movq -32(%rbp), %rdi
    leaq -16(%rbp), %rsi
    movq $0, %rdx
    call snd_pcm_hw_params_get_period_size@PLT

    movq $4096, -16(%rbp)

    movq $SONG, %rdi
    leaq -8(%rbp), %rsi
    call read_file
    movq %rax, %r12
    movq $0, %r13

    movq $0, %r14

    loop:
        movq $1024, %rdx
        movq -40(%rbp), %rdi
        leaq (%r12, %r13, 1), %rsi
        addq $4096, %r13
        call snd_pcm_writei@PLT

        movq $format, %rdi
        movq %rax, %rsi
        movq $0, %rax

        call printf

        incq %r14
        cmp %r13, -8(%rbp)
        jl end


        jmp loop
    end:

    movq %rbp, %rsp
    popq %rbp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
ret
