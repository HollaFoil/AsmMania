.text
.equ BUTTON_HEIGHT, 40
.equ LANE_WIDTH, 75
.equ LANE_HEIGHT, 720
.equ TOP_LEFT_X, 150
.equ TOP_LEFT_Y, 100
.equ BORDER_WIDTH, 5
.equ LANE_SEPARATOR_WIDTH, 1
.equ LANE_HEIGHT_OFFSET, 10
.equ TOTAL_WIDTH, LANE_WIDTH*4+LANE_SEPARATOR_WIDTH*3+BORDER_WIDTH

.global draw_play_area

/*
rdi    = gc     = -8  rbp
rdi+8  = wi     = -16 rbp
rdi+16 = di     = -24 rbp

rsi lane1pressed
rdx lane2pressed
rcx lane3pressed
r8  lane4pressed
*/
draw_play_area:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    subq $64, %rsp

    movq %rsi, -32(%rbp)
    movq %rdx, -40(%rbp)
    movq %rcx, -48(%rbp)
    movq %r8, -56(%rbp)

    movq (%rdi), %rax
    movq %rax, -24(%rbp)
    movq 8(%rdi), %rax
    movq %rax, -16(%rbp)
    movq 16(%rdi), %rax
    movq %rax, -8(%rbp)

    #1x offset
    movq $TOP_LEFT_X, %r12
    addq $LANE_WIDTH, %r12
    addq $BORDER_WIDTH, %r12
    #2x offset
    movq %r12, %r13
    addq $LANE_WIDTH, %r13
    addq $LANE_SEPARATOR_WIDTH, %r13
    #3x offset
    movq %r13, %r14
    addq $LANE_WIDTH, %r14
    addq $LANE_SEPARATOR_WIDTH, %r14
    #4x offset
    movq %r14, %r15
    addq $LANE_WIDTH, %r15
    addq $LANE_SEPARATOR_WIDTH, %r15


    cmpq $0, -32(%rbp)
    je dont_draw_button_1

    movq	-8(%rbp), %rdi	
    movq	-24(%rbp), %rsi	
	movq	$16745097, %rdx	# White
	call	XSetForeground@PLT

    movq -8(%rbp), %rdi
    movq -16(%rbp), %rsi
    movq -24(%rbp), %rdx
    movq $TOP_LEFT_X, %rcx
    addq $BORDER_WIDTH, %rcx
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    subq $BUTTON_HEIGHT, %r8
    movq $LANE_WIDTH, %r9
    movq $BUTTON_HEIGHT, %r10
    pushq %r10

    call XFillRectangle@PLT
    dont_draw_button_1:

    cmpq $0, -40(%rbp)
    je dont_draw_button_2

    movq	-8(%rbp), %rdi	
    movq	-24(%rbp), %rsi	
	movq	$16777215, %rdx	# White
	call	XSetForeground@PLT

    movq -8(%rbp), %rdi
    movq -16(%rbp), %rsi
    movq -24(%rbp), %rdx
    movq %r12, %rcx
    addq $LANE_SEPARATOR_WIDTH, %rcx
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    subq $BUTTON_HEIGHT, %r8
    movq $LANE_WIDTH, %r9
    movq $BUTTON_HEIGHT, %r10
    pushq %r10

    call XFillRectangle@PLT
    dont_draw_button_2:

    cmpq $0, -48(%rbp)
    je dont_draw_button_3

    movq	-8(%rbp), %rdi	
    movq	-24(%rbp), %rsi	
	movq	$16777215, %rdx	# White
	call	XSetForeground@PLT

    movq -8(%rbp), %rdi
    movq -16(%rbp), %rsi
    movq -24(%rbp), %rdx
    movq %r13, %rcx
    addq $LANE_SEPARATOR_WIDTH, %rcx
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    subq $BUTTON_HEIGHT, %r8
    movq $LANE_WIDTH, %r9
    movq $BUTTON_HEIGHT, %r10
    pushq %r10

    call XFillRectangle@PLT
    dont_draw_button_3:

    cmpq $0, -56(%rbp)
    je dont_draw_button_4

    movq	-8(%rbp), %rdi	
    movq	-24(%rbp), %rsi	
	movq	$16745097, %rdx	# White
	call	XSetForeground@PLT

    movq -8(%rbp), %rdi
    movq -16(%rbp), %rsi
    movq -24(%rbp), %rdx
    movq %r14, %rcx
    addq $LANE_SEPARATOR_WIDTH, %rcx
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    subq $BUTTON_HEIGHT, %r8
    movq $LANE_WIDTH, %r9
    movq $BUTTON_HEIGHT, %r10
    pushq %r10

    call XFillRectangle@PLT
    dont_draw_button_4:

    movq	-8(%rbp), %rdi	
    movq	-24(%rbp), %rsi	
	movq	$16777215, %rdx	# White
	call	XSetForeground@PLT

    #Left wall
    movq -8(%rbp), %rdi
    movq -16(%rbp), %rsi
    movq -24(%rbp), %rdx
    movq $TOP_LEFT_X, %rcx
    movq $TOP_LEFT_Y, %r8
    movq $BORDER_WIDTH, %r9
    movq $LANE_HEIGHT, %r10
    addq $BORDER_WIDTH, %r10
    pushq %r10
    call XFillRectangle@PLT

    #Right wall
    movq -8(%rbp), %rdi
    movq -16(%rbp), %rsi
    movq -24(%rbp), %rdx
    movq %r15, %rcx
    movq $TOP_LEFT_Y, %r8
    movq $BORDER_WIDTH, %r9
    movq $LANE_HEIGHT, %r10
    addq $BORDER_WIDTH, %r10
    pushq %r10
    call XFillRectangle@PLT

    #Lane separator 1
    movq -8(%rbp), %rdi
    movq -16(%rbp), %rsi
    movq -24(%rbp), %rdx
    movq %r12, %rcx
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT_OFFSET, %r8
    movq $LANE_SEPARATOR_WIDTH, %r9
    movq $LANE_HEIGHT, %r10
    addq $BORDER_WIDTH, %r10
    subq $LANE_HEIGHT_OFFSET, %r10
    pushq %r10
    call XFillRectangle@PLT

    #Lane separator 2
    movq -8(%rbp), %rdi
    movq -16(%rbp), %rsi
    movq -24(%rbp), %rdx
    movq %r13, %rcx
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT_OFFSET, %r8
    movq $LANE_SEPARATOR_WIDTH, %r9
    movq $LANE_HEIGHT, %r10
    addq $BORDER_WIDTH, %r10
    subq $LANE_HEIGHT_OFFSET, %r10
    pushq %r10
    call XFillRectangle@PLT

    #Lane separator 3
    movq -8(%rbp), %rdi
    movq -16(%rbp), %rsi
    movq -24(%rbp), %rdx
    movq %r14, %rcx
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT_OFFSET, %r8
    movq $LANE_SEPARATOR_WIDTH, %r9
    movq $LANE_HEIGHT, %r10
    addq $BORDER_WIDTH, %r10
    subq $LANE_HEIGHT_OFFSET, %r10
    pushq %r10
    call XFillRectangle@PLT

    #Bottom wall
    movq -8(%rbp), %rdi
    movq -16(%rbp), %rsi
    movq -24(%rbp), %rdx
    movq $TOP_LEFT_X, %rcx
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    movq $TOTAL_WIDTH, %r9
    movq $BORDER_WIDTH, %r10
    pushq %r10
    call XFillRectangle@PLT

    #Above buttons wall
    movq -8(%rbp), %rdi
    movq -16(%rbp), %rsi
    movq -24(%rbp), %rdx
    movq $TOP_LEFT_X, %rcx
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    subq $BUTTON_HEIGHT, %r8
    movq $TOTAL_WIDTH, %r9
    movq $BORDER_WIDTH, %r10
    pushq %r10
    call XFillRectangle@PLT

    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    movq %rbp, %rsp
    popq %rbp
ret
