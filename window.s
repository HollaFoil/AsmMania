.text
displayenv: .string "DISPLAY"
name: .asciz "AsmMania"

.global init_window

# %RDI - pointer to stack where to insert 3 objects. 
# 16(%RDI) = display 
#  8(%RDI) = window
#   (%RDI) = gc

# %RSI - width
# %RDX - height
init_window:
    pushq %rbp
    movq %rsp, %rbp

    subq $80, %rsp

    movq %rsi, -8(%rbp) #width, RBP-8
    movq %rdx, -16(%rbp) #height, RBP-16
    movq %r12, -24(%rbp)
    movq %r13, -32(%rbp)
    movq %r14, -40(%rbp)
    movq %r15, -48(%rbp)
    movq %rdi, %r12

    # Create display object
    movq $displayenv, %rdi
    call getenv@PLT
    movq %rax, %rdi
    call XOpenDisplay@PLT
    movq %rax, 16(%r12) # = Display *display;
    
    # Default screen
    movq $0, -40(%rbp)
    movl 224(%rax), %r15d
    movl %r15d, -40(%rbp) #int sc
    movq 232(%rax), %r13
    movq 224(%rax), %r14
    pushq %rax
    movq %r14, %rax
    cltq
    movq %rax, %r14
    popq %rax
    salq $7, %r14
    addq %r13, %r14
    movq 16(%r14), %r15
    movq %r15, -54(%rbp) # = Window window();

    movq 232(%rax), %r13
    movl -40(%rbp), %edx
    movslq %edx, %rdx
    salq $7, %rdx
    addq %rdx, %r13
    movq 96(%r13), %r8 # BlackPixel(di, sc)

    movq $1, %rdi
    movq -8(%rbp), %r10
    movq -16(%rbp), %r11
    movq $0, %rcx
    movq $0, %rdx
    movq -54(%rbp), %rsi
    movq %r8, %r9

    pushq %r9	
	pushq %r8	
	pushq %rdi

    movq %r11, %r9
	movq %r10, %r8
	movq %rax, %rdi

    call XCreateSimpleWindow@PLT
    movq %rax, 8(%r12)

    movq 8(%r12), %rsi
    movq 16(%r12), %rdi
    call XMapWindow@PLT
    
    movq 8(%r12), %rsi
    movq 16(%r12), %rdi
    movq $name, %rdx
    call XStoreName@PLT

    movq 8(%r12), %rsi
    movq 16(%r12), %rdi
    movq $32771, %rdx #Subscribe to events here.
    call XSelectInput@PLT

    movq 8(%r12), %rsi
    movq 16(%r12), %rdi
    movq $0, %rdx
    movq $0, %rcx
    call XCreateGC@PLT
    movq %rax, (%r12) # = GC gc()

    

    movq %r12, -24(%rbp)
    movq %r13, -32(%rbp)
    movq %r14, -40(%rbp)
    movq %r15, -48(%rbp)

    movq %rbp, %rsp
    popq %rbp
ret
