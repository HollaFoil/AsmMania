.global time_since


# %RAX - return value, difference between two time values, in microseconds
# %RDI - pointer to time object, gotten from call gettimeofday
time_since:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp

    pushq %rdi
    leaq 8(%rsp), %rdi
    movq $0, %rsi
    call gettimeofday
    popq %rdi
    
    movq (%rsp), %r8
    movq (%rdi), %r10

    subq %r10, %r8
    movq %r8, %rax
    
    movq 8(%rsp), %r9
    movq 8(%rdi), %r11

    movq $1000000, %rdx
    mulq %rdx
    subq %r11, %r9
    addq %r9, %rax

    movq %rbp, %rsp
    popq %rbp
ret   
