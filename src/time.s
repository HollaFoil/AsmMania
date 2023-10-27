.global time_since

# Gets the time difference between current time and given time object, in microseconds
# %RDI - pointer to time object, gotten from call gettimeofday
# %RAX - return value, difference between two time values, in microseconds
time_since:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp

    pushq %rdi
    leaq 8(%rsp), %rdi
    movq $0, %rsi
    call gettimeofday
    popq %rdi
    
    movq $0, %r8
    movq $0, %r9
    movq $0, %r10
    movq $0, %r11

    movl (%rsp), %r8d
    movl (%rdi), %r10d

    subq %r10, %r8
    movq %r8, %rax
    
    movl 8(%rsp), %r9d
    movl 8(%rdi), %r11d

    movq $1000000, %rdx
    mulq %rdx
    subq %r11, %r9
    addq %r9, %rax

    movq %rbp, %rsp
    popq %rbp
ret   
