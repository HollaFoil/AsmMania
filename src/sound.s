.global play_sound_fx
.global set_hit_sound_volume

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
    loop_overlay:
        movw (%rdi), %r8w
        movw (%rdx, %rcx, 1), %r9w
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
        jg loop_overlay

    movq %rbp, %rsp
    popq %rbp
    ret

# arguments:
# %rdi: sound fx address
# %rsi: sound fx size in bytes
# %rdx: volume
set_hit_sound_volume:
    pushq %rbp
    movq %rsp, %rbp

    movq %rdx, %rcx
    movw $100, %r9w
    loop_volume:
        movw (%rdi), %ax
        imulw %cx
        idivw %r9w
        movw %ax, (%rdi)
        addq $2, %rdi
        subq $2, %rsi
        jg loop_volume

    movq %rbp, %rsp
    popq %rbp
    ret
