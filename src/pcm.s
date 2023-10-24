.equ BITRATE, 44100
.equ CHANNELS, 2

DEFAULT_TYPE: .asciz "default"
format: .asciz "%ld\n"

.global create_pcm_handle
#.global main

/*
(%RDI) = pcm handle
(%RSI) = frame (period, should be 1024)
*/
create_pcm_handle:
    pushq %rbp
    movq %rsp, %rbp
    movq %r12, -72(%rbp)
    movq %r13, -80(%rbp)
    movq %r14, -88(%rbp)
    movq %r15, -96(%rbp)

    subq $128, %rsp

    movq %rdi, -64(%rbp)
    movq %rsi, -56(%rbp)

    leaq -40(%rbp), %rdi
    movq $DEFAULT_TYPE, %rsi
    movq $0, %rdx
    movq $1, %rcx
    call snd_pcm_open@PLT
    movq $0, -48(%rbp)
    movl %eax, -48(%rbp)

    movq -64(%rbp), %rdi
    movq -40(%rbp), %rsi
    movq %rsi, (%rdi)

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

    movq $512, -104(%rbp)
    leaq -104(%rbp), %rdx
    movq -32(%rbp), %rsi
    movq -40(%rbp), %rdi
    call snd_pcm_hw_params_set_buffer_size_near@PLT

    movq $0, -112(%rbp)
    movq $4, -104(%rbp)
    leaq -112(%rbp), %rcx
    leaq -104(%rbp), %rdx
    movq -32(%rbp), %rsi
    movq -40(%rbp), %rdi
    call snd_pcm_hw_params_set_periods_near@PLT

    movq -32(%rbp), %rsi
    movq -40(%rbp), %rdi
    call snd_pcm_hw_params@PLT

    movq -56(%rbp), %rdi
    movq -16(%rbp), %rsi
    movq %rsi, (%rdi)

    movq -72(%rbp), %r12
    movq -80(%rbp), %r13
    movq -88(%rbp), %r14
    movq -96(%rbp), %r15

    movq %rbp, %rsp
    popq %rbp
ret

