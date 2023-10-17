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
format: .asciz "%ld\n"

.global draw_play_area
.global draw_hit_object

/*
-8rbp %r12
-16rbp %r13
-24rbp %r14
-32rbp %r15

rdi    = gc     = -88  rbp
rdi+8  = wi     = -80 rbp
rdi+16 = di     = -72 rbp

rsi lane1pressed -40
rdx lane2pressed
rcx lane3pressed
r8  lane4pressed -64
*/
draw_play_area:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    subq $96, %rsp

    movq %rsi, -40(%rbp)
    movq %rdx, -48(%rbp)
    movq %rcx, -56(%rbp)
    movq %r8, -64(%rbp)

    movq (%rdi), %rax
    movq %rax, -88(%rbp)
    movq 8(%rdi), %rax
    movq %rax, -80(%rbp)
    movq 16(%rdi), %rax
    movq %rax, -72(%rbp)

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


    cmpq $0, -40(%rbp)
    je dont_draw_button_1

    movq	-72(%rbp), %rdi	
    movq	-88(%rbp), %rsi	
	movq	$16745097, %rdx	# White
	call	XSetForeground@PLT

    movq -72(%rbp), %rdi
    movq -80(%rbp), %rsi
    movq -88(%rbp), %rdx
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

    cmpq $0, -48(%rbp)
    je dont_draw_button_2

    movq	-72(%rbp), %rdi	
    movq	-88(%rbp), %rsi	
	movq	$16777215, %rdx	# White
	call	XSetForeground@PLT

    movq -72(%rbp), %rdi
    movq -80(%rbp), %rsi
    movq -88(%rbp), %rdx
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

    cmpq $0, -56(%rbp)
    je dont_draw_button_3

    movq	-72(%rbp), %rdi	
    movq	-88(%rbp), %rsi	
	movq	$16777215, %rdx	# White
	call	XSetForeground@PLT

    movq -72(%rbp), %rdi
    movq -80(%rbp), %rsi
    movq -88(%rbp), %rdx
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

    cmpq $0, -64(%rbp)
    je dont_draw_button_4

    movq	-72(%rbp), %rdi	
    movq	-88(%rbp), %rsi	
	movq	$16745097, %rdx	# White
	call	XSetForeground@PLT

    movq -72(%rbp), %rdi
    movq -80(%rbp), %rsi
    movq -88(%rbp), %rdx
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

    movq	-72(%rbp), %rdi	
    movq	-88(%rbp), %rsi	
	movq	$16777215, %rdx	# White
	call	XSetForeground@PLT

    #Left wall
    movq -72(%rbp), %rdi
    movq -80(%rbp), %rsi
    movq -88(%rbp), %rdx
    movq $TOP_LEFT_X, %rcx
    movq $TOP_LEFT_Y, %r8
    movq $BORDER_WIDTH, %r9
    movq $LANE_HEIGHT, %r10
    addq $BORDER_WIDTH, %r10
    pushq %r10
    call XFillRectangle@PLT

    #Right wall
    movq -72(%rbp), %rdi
    movq -80(%rbp), %rsi
    movq -88(%rbp), %rdx
    movq %r15, %rcx
    movq $TOP_LEFT_Y, %r8
    movq $BORDER_WIDTH, %r9
    movq $LANE_HEIGHT, %r10
    addq $BORDER_WIDTH, %r10
    pushq %r10
    call XFillRectangle@PLT

    #Lane separator 1
    movq -72(%rbp), %rdi
    movq -80(%rbp), %rsi
    movq -88(%rbp), %rdx
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
    movq -72(%rbp), %rdi
    movq -80(%rbp), %rsi
    movq -88(%rbp), %rdx
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
    movq -72(%rbp), %rdi
    movq -80(%rbp), %rsi
    movq -88(%rbp), %rdx
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
    movq -72(%rbp), %rdi
    movq -80(%rbp), %rsi
    movq -88(%rbp), %rdx
    movq $TOP_LEFT_X, %rcx
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    movq $TOTAL_WIDTH, %r9
    movq $BORDER_WIDTH, %r10
    pushq %r10
    call XFillRectangle@PLT

    #Above buttons wall
    movq -72(%rbp), %rdi
    movq -80(%rbp), %rsi
    movq -88(%rbp), %rdx
    movq $TOP_LEFT_X, %rcx
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    subq $BUTTON_HEIGHT, %r8
    movq $TOTAL_WIDTH, %r9
    movq $BORDER_WIDTH, %r10
    pushq %r10
    call XFillRectangle@PLT

    leaq -32(%rbp), %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    movq %rbp, %rsp
    popq %rbp
ret

draw_hit_object:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r12 # -8(%rbp)
    pushq %r13 # -16(%rbp)
    pushq %r14 # -24(%rbp)
    pushq %r15 # -32(%rbp)

    subq $80, %rsp

    movq %rsi, -40(%rbp) # lane of hit object
    movq %rdx, -48(%rbp) # offset of hit object

    movq (%rdi), %rax
    movq %rax, -72(%rbp) # gc
    movq 8(%rdi), %rax
    movq %rax, -64(%rbp) # window
    movq 16(%rdi), %rax
    movq %rax, -56(%rbp) # display

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



    movq	-56(%rbp), %rdi	
    movq	-72(%rbp), %rsi	
	movq	$16045097, %rdx
	call	XSetForeground@PLT

    movq -40(%rbp), %rax
    cmpb $0, %al
    je first_lane
    cmpb $1, %al
    je second_lane
    cmpb $2, %al
    je third_lane
    cmpb $3, %al
    je fourth_lane
    jmp error


    first_lane:
    movq -56(%rbp), %rdi
    movq -64(%rbp), %rsi
    movq -72(%rbp), %rdx
    movq $TOP_LEFT_X, %rcx
    addq $BORDER_WIDTH, %rcx
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    subq -48(%rbp), %r8
    subq $BUTTON_HEIGHT, %r8
    movq $LANE_WIDTH, %r9
    movq $BUTTON_HEIGHT, %r10
    pushq %r10
    jmp finish_drawing


    second_lane:
    movq -56(%rbp), %rdi
    movq -64(%rbp), %rsi
    movq -72(%rbp), %rdx
    movq %r12, %rcx
    #addq $BORDER_WIDTH, %rcx
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    subq -48(%rbp), %r8
    subq $BUTTON_HEIGHT, %r8
    movq $LANE_WIDTH, %r9
    movq $BUTTON_HEIGHT, %r10
    pushq %r10
    jmp finish_drawing

    third_lane:
    movq -56(%rbp), %rdi
    movq -64(%rbp), %rsi
    movq -72(%rbp), %rdx
    movq %r13, %rcx
    #addq $BORDER_WIDTH, %rcx
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    subq -48(%rbp), %r8
    subq $BUTTON_HEIGHT, %r8
    movq $LANE_WIDTH, %r9
    movq $BUTTON_HEIGHT, %r10
    pushq %r10
    jmp finish_drawing


    fourth_lane:
    movq -56(%rbp), %rdi
    movq -64(%rbp), %rsi
    movq -72(%rbp), %rdx
    movq %r14, %rcx
    #addq $BORDER_WIDTH, %rcx
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    subq -48(%rbp), %r8
    subq $BUTTON_HEIGHT, %r8
    movq $LANE_WIDTH, %r9
    movq $BUTTON_HEIGHT, %r10
    pushq %r10

    finish_drawing:

    call XFillRectangle@PLT

    leaq -32(%rbp), %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    movq %rbp, %rsp
    popq %rbp
ret

error:
        movq $format, %rdi
        movq %rax, %rsi
        movq $0, %rax
        call printf
        movq $0, %rcx
        divq %rcx
