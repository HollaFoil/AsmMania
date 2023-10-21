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
    movw $0x7FFF, %r10w # INT_MAX
    movw $0x8001, %r11w # INT_MIN

    # adds the sound waves
    loop:
        movw (%rdi), %r8w
        
        shlw %r8w # double the volume of hit sound
        jno no_overflow_shifting
        cmovncw %r10w, %r8w
        cmovcw %r11w, %r8w
        no_overflow_shifting:
        movw (%rdx, %rcx, 1), %r9w
        #sarw $1, %r9w
        addw %r8w, %r9w
        jno no_overflow
        andw $0x8000, %r8w # get the sign bit
        cmovzw %r10w, %r9w # if sign was 0, then MAX_INT
        cmovnzw %r11w, %r9w # if sign was 1, then MIN_INT
        no_overflow:
        movw %r9w, (%rdx, %rcx, 1)
        addq $2, %rcx
        addq $2, %rdi
        subq $2, %rsi
        jg loop

    movq %rbp, %rsp
    popq %rbp
    ret
