.global play_sound_fx

# arguments:
# %rdi: sound fx address
# %rsi: sound fx size in bytes
# %rdx: music address
# %rcx: current song offset

play_sound_fx:
    pushq %rbp
    movq %rsp, %rbp

    addq $242, %rdi
    subq $242, %rsi

    # adds the sound waves
    loop:
        movw (%rdi), %r8w
        sarw $1, %r8w
        movw (%rdx, %rcx, 1), %r9w
        sarw $1, %r9w
        addw %r8w, %r9w
        movw %r9w, (%rdx, %rcx, 1)
        addq $2, %rcx
        addq $2, %rdi
        subq $2, %rsi
        jg loop

    movq %rbp, %rsp
    popq %rbp
    ret
