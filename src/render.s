.text
.equ BUTTON_HEIGHT, 40
.equ LANE_WIDTH, 75
.equ LANE_HEIGHT, 820
.equ LANE_VISUAL_HEIGHT, 900
.equ GRADIENT_HEIGHT_UP_TO, 500
.equ GRADIENT_DENOMINATOR, (LANE_VISUAL_HEIGHT - GRADIENT_HEIGHT_UP_TO)
.equ TOP_LEFT_X, 150
.equ TOP_LEFT_Y, 0
.equ BORDER_WIDTH, 5
.equ LANE_SEPARATOR_WIDTH, 5
.equ TOTAL_WIDTH, LANE_WIDTH*4+LANE_SEPARATOR_WIDTH*3+BORDER_WIDTH

# R, G, B colors                    char1
# B/F - Background/foreground       char2
# 1/2/3/4 - lanes                   char3
.equ RB1, 51
.equ GB1, 39
.equ BB1, 8
.equ RB2, 50
.equ GB2, 22
.equ BB2, 0
.equ RB3, 42
.equ GB3, 7
.equ BB3, 18
.equ RB4, 41
.equ GB4, 12
.equ BB4, 47


.equ RF1, 255 
.equ GF1, 209
.equ BF1, 42
.equ RF2, 254
.equ GF2, 116
.equ BF2, 1
.equ RF3, 226
.equ GF3, 37
.equ BF3, 96
.equ RF4, 218
.equ GF4, 64
.equ BF4, 250


format: .asciz "%ld\n"

.global draw_play_area
.global draw_hit_object
.global draw_text
.global draw_hp_bar
.global draw_current_combo
.global draw_current_score
.global draw_metadata



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
r9  pointer to gradient values (starting at lane4), 0-1000
*/
draw_play_area:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    subq $160, %rsp

    movq %rsi, -40(%rbp)
    movq %rdx, -48(%rbp)
    movq %rcx, -56(%rbp)
    movq %r8, -64(%rbp)

    movq (%r9), %rax
    movq %rax, -128(%rbp)
    movq 8(%r9), %rax
    movq %rax, -120(%rbp)
    movq 16(%r9), %rax
    movq %rax, -112(%rbp)
    movq 24(%r9), %rax
    movq %rax, -104(%rbp)

    movq (%rdi), %rax
    movq %rax, -88(%rbp)
    movq 8(%rdi), %rax
    movq %rax, -80(%rbp)
    movq 16(%rdi), %rax
    movq %rax, -72(%rbp)

    # Lane x offsets
    #1x offset
    movq $TOP_LEFT_X, %r12
    addq $LANE_WIDTH, %r12
    addq $BORDER_WIDTH, %r12
    addq $LANE_SEPARATOR_WIDTH, %r12
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



    #Lane 1
    movq	-72(%rbp), %rdi	
    movq	-88(%rbp), %rsi	
	movq	$3352328, %rdx
	call	XSetForeground@PLT

    movq -72(%rbp), %rdi
    movq -80(%rbp), %rsi
    movq -88(%rbp), %rdx
    movq $TOP_LEFT_X, %rcx
    addq $BORDER_WIDTH, %rcx
    movq $TOP_LEFT_Y, %r8
    movq $LANE_WIDTH, %r9
    movq $LANE_VISUAL_HEIGHT, %r10
    addq $BORDER_WIDTH, %r10
    subq $8, %rsp
    pushq %r10
    call XFillRectangle@PLT
    addq $16, %rsp

    #Lane 2
    movq	-72(%rbp), %rdi	
    movq	-88(%rbp), %rsi	
	movq	$3282432, %rdx
	call	XSetForeground@PLT

    movq -72(%rbp), %rdi
    movq -80(%rbp), %rsi
    movq -88(%rbp), %rdx
    movq %r12, %rcx
    movq $TOP_LEFT_Y, %r8
    movq $LANE_WIDTH, %r9
    movq $LANE_VISUAL_HEIGHT, %r10
    addq $BORDER_WIDTH, %r10
    subq $8, %rsp
    pushq %r10
    call XFillRectangle@PLT
    addq $16, %rsp

    #Lane 3
    movq	-72(%rbp), %rdi	
    movq	-88(%rbp), %rsi	
	movq	$2754322, %rdx
	call	XSetForeground@PLT

    movq -72(%rbp), %rdi
    movq -80(%rbp), %rsi
    movq -88(%rbp), %rdx
    movq %r13, %rcx
    movq $TOP_LEFT_Y, %r8
    movq $LANE_WIDTH, %r9
    movq $LANE_VISUAL_HEIGHT, %r10
    addq $BORDER_WIDTH, %r10
    subq $8, %rsp
    pushq %r10
    call XFillRectangle@PLT
    addq $16, %rsp

    #Lane 4
    movq	-72(%rbp), %rdi	
    movq	-88(%rbp), %rsi	
	movq	$2690095, %rdx
	call	XSetForeground@PLT

    movq -72(%rbp), %rdi
    movq -80(%rbp), %rsi
    movq -88(%rbp), %rdx
    movq %r14, %rcx
    movq $TOP_LEFT_Y, %r8
    movq $LANE_WIDTH, %r9
    movq $LANE_VISUAL_HEIGHT, %r10
    addq $BORDER_WIDTH, %r10
    subq $8, %rsp
    pushq %r10
    call XFillRectangle@PLT
    addq $16, %rsp


    #  Lane press gradients by drawing fading lines (no RGBA format supported, only RGB)
    movq $LANE_VISUAL_HEIGHT, %r10
    loop_lane1:
        cmp $GRADIENT_HEIGHT_UP_TO, %r10
        je end_loop_lane1

        movq $0, %r8

        # Get fade strength
        movq $LANE_VISUAL_HEIGHT, %rdi
        subq %r10, %rdi
        movq $1000, %rax
        mulq %rdi 
        movq $GRADIENT_DENOMINATOR, %rdi
        divq %rdi 
        movq -104(%rbp), %rdi
        mulq %rdi 
        movq $1000, %rdi
        divq %rdi
        mulq %rax
        divq %rdi
        movq %rax, %rdx

        # Do linear interpolation between R G B values
        movq $RB1, %rdi
        movq $RF1, %rsi
        call lerp
        shl $8, %r8
        addq %rax, %r8

        movq $GB1, %rdi
        movq $GF1, %rsi
        call lerp
        shl $8, %r8
        addq %rax, %r8

        movq $BB1, %rdi
        movq $BF1, %rsi
        call lerp
        shl $8, %r8
        addq %rax, %r8

        movq %r10, %r15


        # Draw the line at given height and color
        movq	-72(%rbp), %rdi	
        movq	-88(%rbp), %rsi	
        movq	%r8, %rdx
        call	XSetForeground@PLT
        
        movq %r15, %r10

        movq -72(%rbp), %rdi
        movq -80(%rbp), %rsi
        movq -88(%rbp), %rdx
        movq $TOP_LEFT_X, %rcx
        addq $BORDER_WIDTH, %rcx
        movq $LANE_VISUAL_HEIGHT, %r8
        subq %r10, %r8
        addq $GRADIENT_HEIGHT_UP_TO, %r8
        movq $LANE_WIDTH, %r9
        subq $8, %rsp
        pushq $1

        call XFillRectangle@PLT
        addq $16, %rsp

        movq %r15, %r10

        decq %r10
        jmp loop_lane1
    end_loop_lane1:

    #  Lane press gradients by drawing fading lines (no RGBA format supported, only RGB)
    movq $LANE_VISUAL_HEIGHT, %r10
    loop_lane2:
        cmp $GRADIENT_HEIGHT_UP_TO, %r10
        je end_loop_lane2

        movq $0, %r8

        # Get fade strength
        movq $LANE_VISUAL_HEIGHT, %rdi
        subq %r10, %rdi
        movq $1000, %rax
        mulq %rdi 
        movq $GRADIENT_DENOMINATOR, %rdi
        divq %rdi 
        movq -112(%rbp), %rdi
        mulq %rdi 
        movq $1000, %rdi
        divq %rdi
        mulq %rax
        divq %rdi
        movq %rax, %rdx

        # Do linear interpolation between R G B values
        movq $RB2, %rdi
        movq $RF2, %rsi
        call lerp
        shl $8, %r8
        addq %rax, %r8

        movq $GB2, %rdi
        movq $GF2, %rsi
        call lerp
        shl $8, %r8
        addq %rax, %r8

        movq $BB2, %rdi
        movq $BF2, %rsi
        call lerp
        shl $8, %r8
        addq %rax, %r8

        movq %r10, %r15

        # Draw the line at given height and color
        movq	-72(%rbp), %rdi	
        movq	-88(%rbp), %rsi	
        movq	%r8, %rdx
        call	XSetForeground@PLT
        
        movq %r15, %r10

        movq -72(%rbp), %rdi
        movq -80(%rbp), %rsi
        movq -88(%rbp), %rdx
        movq %r12, %rcx
        movq $LANE_VISUAL_HEIGHT, %r8
        subq %r10, %r8
        addq $GRADIENT_HEIGHT_UP_TO, %r8
        movq $LANE_WIDTH, %r9
        subq $8, %rsp
        pushq $1

        call XFillRectangle@PLT
        addq $16, %rsp

        movq %r15, %r10

        decq %r10
        jmp loop_lane2
    end_loop_lane2:

    #  Lane press gradients by drawing fading lines (no RGBA format supported, only RGB)
    movq $LANE_VISUAL_HEIGHT, %r10
    loop_lane3:
        cmp $GRADIENT_HEIGHT_UP_TO, %r10
        je end_loop_lane3

        movq $0, %r8

        # Get fade strength
        movq $LANE_VISUAL_HEIGHT, %rdi
        subq %r10, %rdi
        movq $1000, %rax
        mulq %rdi 
        movq $GRADIENT_DENOMINATOR, %rdi
        divq %rdi 
        movq -120(%rbp), %rdi
        mulq %rdi 
        movq $1000, %rdi
        divq %rdi
        mulq %rax
        divq %rdi
        movq %rax, %rdx

        # Do linear interpolation between R G B values
        movq $RB3, %rdi
        movq $RF3, %rsi
        call lerp
        shl $8, %r8
        addq %rax, %r8

        movq $GB3, %rdi
        movq $GF3, %rsi
        call lerp
        shl $8, %r8
        addq %rax, %r8

        movq $BB3, %rdi
        movq $BF3, %rsi
        call lerp
        shl $8, %r8
        addq %rax, %r8

        movq %r10, %r15

        # Draw the line at given height and color
        movq	-72(%rbp), %rdi	
        movq	-88(%rbp), %rsi	
        movq	%r8, %rdx
        call	XSetForeground@PLT
        
        movq %r15, %r10

        movq -72(%rbp), %rdi
        movq -80(%rbp), %rsi
        movq -88(%rbp), %rdx
        movq %r13, %rcx
        movq $LANE_VISUAL_HEIGHT, %r8
        subq %r10, %r8
        addq $GRADIENT_HEIGHT_UP_TO, %r8
        movq $LANE_WIDTH, %r9
        subq $8, %rsp
        pushq $1

        call XFillRectangle@PLT
        addq $16, %rsp

        movq %r15, %r10

        decq %r10
        jmp loop_lane3
    end_loop_lane3:

    #  Lane press gradients by drawing fading lines (no RGBA format supported, only RGB)
    movq $LANE_VISUAL_HEIGHT, %r10
    loop_lane4:
        cmp $GRADIENT_HEIGHT_UP_TO, %r10
        je end_loop_lane4

        movq $0, %r8

        # Get fade strength
        movq $LANE_VISUAL_HEIGHT, %rdi
        subq %r10, %rdi
        movq $1000, %rax
        mulq %rdi 
        movq $GRADIENT_DENOMINATOR, %rdi
        divq %rdi 
        movq -128(%rbp), %rdi
        mulq %rdi 
        movq $1000, %rdi
        divq %rdi
        mulq %rax
        divq %rdi
        movq %rax, %rdx

        # Do linear interpolation between R G B values
        movq $RB4, %rdi
        movq $RF4, %rsi
        call lerp
        shl $8, %r8
        addq %rax, %r8

        movq $GB4, %rdi
        movq $GF4, %rsi
        call lerp
        shl $8, %r8
        addq %rax, %r8

        movq $BB4, %rdi
        movq $BF4, %rsi
        call lerp
        shl $8, %r8
        addq %rax, %r8

        movq %r10, %r15

        # Draw the line at given height and color
        movq	-72(%rbp), %rdi	
        movq	-88(%rbp), %rsi	
        movq	%r8, %rdx
        call	XSetForeground@PLT
        
        movq %r15, %r10

        movq -72(%rbp), %rdi
        movq -80(%rbp), %rsi
        movq -88(%rbp), %rdx
        movq %r14, %rcx
        movq $LANE_VISUAL_HEIGHT, %r8
        subq %r10, %r8
        addq $GRADIENT_HEIGHT_UP_TO, %r8
        movq $LANE_WIDTH, %r9
        subq $8, %rsp
        pushq $1

        call XFillRectangle@PLT
        addq $16, %rsp

        movq %r15, %r10

        decq %r10
        jmp loop_lane4
    end_loop_lane4:

    movq	-72(%rbp), %rdi	
    movq	-88(%rbp), %rsi	
	movq	$16777215, %rdx
	call	XSetForeground@PLT


    # Draw hit line
    movq -72(%rbp), %rdi
    movq -80(%rbp), %rsi
    movq -88(%rbp), %rdx
    movq $TOP_LEFT_X, %rcx
    addq $BORDER_WIDTH, %rcx
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    movq $TOTAL_WIDTH, %r9
    subq $BORDER_WIDTH, %r9
    movq $BORDER_WIDTH, %r10
    subq $8, %rsp
    pushq %r10
    call XFillRectangle@PLT

    addq $16, %rsp

    leaq -32(%rbp), %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    movq %rbp, %rsp
    popq %rbp
ret

/*
Draw the hit object
(%rdi) - gc struct
%rsi - lane
%rdx - offset
%rcx - optional slider offset
*/
draw_hit_object:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r12 # -8(%rbp)
    pushq %r13 # -16(%rbp)
    pushq %r14 # -24(%rbp)
    pushq %r15 # -32(%rbp)

    subq $88, %rsp

    movq %rsi, -64(%rbp) # lane of hit object
    movq %rdx, -72(%rbp) # offset of hit object
    movq %rcx, -80(%rbp) # offset of slider end, 0 if not slider

    movq (%rdi), %rax
    movq %rax, -56(%rbp) # gc
    movq 8(%rdi), %rax
    movq %rax, -48(%rbp) # window
    movq 16(%rdi), %rax
    movq %rax, -40(%rbp) # display

    #1x offset
    movq $TOP_LEFT_X, %r12
    addq $LANE_WIDTH, %r12
    addq $BORDER_WIDTH, %r12
    addq $LANE_SEPARATOR_WIDTH, %r12
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

    # Check if it's a slider
    testl %ecx, %ecx
    jnz slider_select

    # Check which lane the note belongs to
    movq -64(%rbp), %rax
    cmpb $0, %al
    je first_lane
    cmpb $1, %al
    je second_lane
    cmpb $2, %al
    je third_lane
    cmpb $3, %al
    je fourth_lane

    slider_select:
    movq -64(%rbp), %rax
    cmpb $0, %al
    je first_lane_slider
    cmpb $1, %al
    je second_lane_slider
    cmpb $2, %al
    je third_lane_slider
    cmpb $3, %al
    je fourth_lane_slider

    # Draw the note
    # The note offset in miliseconds directly maps to an offset from the finish line in pixels
    first_lane:
    # Set the colour
	movq	$0xFFD12A, %rdx	# RGB hex value for yellow
    movq	-56(%rbp), %rsi
    movq	-40(%rbp), %rdi
	call	XSetForeground@PLT

    # Pass all the arguments of the visuals of the note
    movq $BUTTON_HEIGHT, %r10
    pushq %r10
    movq $LANE_WIDTH, %r9
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    subq -72(%rbp), %r8
    subq $BUTTON_HEIGHT, %r8
    movq $TOP_LEFT_X, %rcx
    addq $BORDER_WIDTH, %rcx
    
    jmp finish_drawing

    second_lane:
	movq	$0xFE7401, %rdx	# Orange
    movq	-56(%rbp), %rsi
    movq	-40(%rbp), %rdi
	call	XSetForeground@PLT

    movq $BUTTON_HEIGHT, %r10
    pushq %r10
    movq $LANE_WIDTH, %r9
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    subq $BUTTON_HEIGHT, %r8
    subq -72(%rbp), %r8
    movq %r12, %rcx
    jmp finish_drawing

    third_lane:
	movq	$0xE22560, %rdx	# Red
    movq	-56(%rbp), %rsi	
    movq	-40(%rbp), %rdi	
	call	XSetForeground@PLT

    movq $BUTTON_HEIGHT, %r10
    pushq %r10
    movq $LANE_WIDTH, %r9
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    subq $BUTTON_HEIGHT, %r8
    subq -72(%rbp), %r8
    movq %r13, %rcx
    jmp finish_drawing

    fourth_lane:
	movq	$0xDA40FA, %rdx	# Purple
    movq	-56(%rbp), %rsi	
    movq	-40(%rbp), %rdi	
	call	XSetForeground@PLT

    movq $BUTTON_HEIGHT, %r10
    pushq %r10
    movq $LANE_WIDTH, %r9
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    subq $BUTTON_HEIGHT, %r8
    subq -72(%rbp), %r8
    movq %r14, %rcx
    jmp finish_drawing

    first_lane_slider:
    movq	$0xFFD12A, %rdx	# RGB hex value for yellow
    movq	-56(%rbp), %rsi
    movq	-40(%rbp), %rdi
	call	XSetForeground@PLT

    movq -80(%rbp), %r10
    subq -72(%rbp), %r10
    addq $BUTTON_HEIGHT, %r10
    pushq %r10
    movq $LANE_WIDTH, %r9
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    subq $BUTTON_HEIGHT, %r8
    subq -80(%rbp), %r8
    movq $TOP_LEFT_X, %rcx
    addq $BORDER_WIDTH, %rcx
    jmp finish_drawing

    second_lane_slider:
    movq	$0xFE7401, %rdx	# Orange
    movq	-56(%rbp), %rsi
    movq	-40(%rbp), %rdi
	call	XSetForeground@PLT

    movq -80(%rbp), %r10
    subq -72(%rbp), %r10
    addq $BUTTON_HEIGHT, %r10
    pushq %r10
    movq $LANE_WIDTH, %r9
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    subq -80(%rbp), %r8
    subq $BUTTON_HEIGHT, %r8
    movq %r12, %rcx
    jmp finish_drawing

    third_lane_slider:
    movq	$0xE22560, %rdx	# Red
    movq	-56(%rbp), %rsi	
    movq	-40(%rbp), %rdi	
	call	XSetForeground@PLT

    movq -80(%rbp), %r10
    subq -72(%rbp), %r10
    addq $BUTTON_HEIGHT, %r10
    pushq %r10
    movq $LANE_WIDTH, %r9
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    subq -80(%rbp), %r8
    subq $BUTTON_HEIGHT, %r8
    movq %r13, %rcx
    jmp finish_drawing


    fourth_lane_slider:
    movq	$0xDA40FA, %rdx	# Purple
    movq	-56(%rbp), %rsi	
    movq	-40(%rbp), %rdi	
	call	XSetForeground@PLT

    movq -80(%rbp), %r10
    subq -72(%rbp), %r10
    addq $BUTTON_HEIGHT, %r10
    pushq %r10
    movq $LANE_WIDTH, %r9
    movq $TOP_LEFT_Y, %r8
    addq $LANE_HEIGHT, %r8
    subq -80(%rbp), %r8
    subq $BUTTON_HEIGHT, %r8
    movq %r14, %rcx

    finish_drawing:
    # Pass the window arguments
    movq -56(%rbp), %rdx
    movq -48(%rbp), %rsi
    movq -40(%rbp), %rdi
    call XFillRectangle@PLT

    # move the stack pointer to %r15-%r12 registers and pop them
    leaq -32(%rbp), %rsp 
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    movq %rbp, %rsp
    popq %rbp
ret


/*
rdi - val1
rsi - val2
rdx - where (0-1000)

(OVERWRITES r9)
*/
lerp:
    pushq %r15
    movq %rdx, %r15
    movq $1000, %rax
    subq %rdx, %rax
    imulq %rdi
    movq %rax, %rdi
    movq %r15, %rax
    imulq %rsi
    addq %rdi, %rax
    movq $1000, %rdi
    idivq %rdi
    movq %r15, %rdx
    popq %r15
ret

# Status messages and their lengths
perfect: .ascii "Perfect!"
perfect_end:
.equ perfect_length, perfect_end - perfect
nice: .ascii "Nice!"
nice_end:
.equ nice_length, nice_end - nice
ok: .ascii "Ok"
ok_end:
.equ ok_length, ok_end - ok
missed: .ascii "Missed"
missed_end:
.equ missed_length, missed_end - missed

/*
Draws the status message
%rdi - gc struct
(%rsi) - text_state
*/
draw_text:
    pushq %rbp
    movq %rsp, %rbp

    # Check if there is any frames left to draw
    cmpl $0, (%rsi)
    je dont_draw_text

    pushq (%rdi) # gc -8(%rbp)
    pushq 8(%rdi) # window -16(%rbp)
    pushq 16(%rdi) # display -24(%rbp)

    # Decrement the frame counter
    decl (%rsi)

    # Determine which status message to draw based on the flag
    cmpl $1, 4(%rsi)
    je draw_missed
    cmpl $2, 4(%rsi)
    je draw_ok
    cmpl $3, 4(%rsi)
    je draw_nice
    cmpl $4, 4(%rsi)
    je draw_perfect

    # Draw the status message
    draw_perfect:
 
	movq $0x00ffff, %rdx	# Cyan
    movq -8(%rbp), %rsi	
    movq -24(%rbp), %rdi
	call XSetForeground@PLT

    pushq $perfect_length
    movq $perfect, %r9
    movq $LANE_HEIGHT, %r8
    subq $100, %r8
    movq $500, %rcx
    movq -8(%rbp), %rdx
    movq -16(%rbp), %rsi
    movq -24(%rbp), %rdi
    call XDrawImageString@PLT
    jmp dont_draw_text

    draw_nice:

    movq $0x32cd32, %rdx	# Green
    movq -8(%rbp), %rsi	
    movq -24(%rbp), %rdi
	call XSetForeground@PLT

    pushq $nice_length
    movq $nice, %r9
    movq $LANE_HEIGHT, %r8
    subq $100, %r8
    movq $500, %rcx
    movq -8(%rbp), %rdx
    movq -16(%rbp), %rsi
    movq -24(%rbp), %rdi
    call XDrawImageString@PLT
    jmp dont_draw_text

    draw_ok:

    movq $0xffff00, %rdx	# Yellow
    movq -8(%rbp), %rsi	
    movq -24(%rbp), %rdi
	call XSetForeground@PLT

    pushq $ok_length
    movq $ok, %r9
    movq $LANE_HEIGHT, %r8
    subq $100, %r8
    movq $500, %rcx
    movq -8(%rbp), %rdx
    movq -16(%rbp), %rsi
    movq -24(%rbp), %rdi
    call XDrawImageString@PLT
    jmp dont_draw_text

    draw_missed:

    movq $0xff0000, %rdx	# Red
    movq -8(%rbp), %rsi	
    movq -24(%rbp), %rdi
	call XSetForeground@PLT

    pushq $missed_length
    movq $missed, %r9
    movq $LANE_HEIGHT, %r8
    subq $100, %r8
    movq $500, %rcx
    movq -8(%rbp), %rdx
    movq -16(%rbp), %rsi
    movq -24(%rbp), %rdi
    call XDrawImageString@PLT
    jmp dont_draw_text

    dont_draw_text:
    movq %rbp, %rsp
    popq %rbp
    ret

/*
Draws the health bar
(%rdi) - gc struct
%rsi - hp
*/
draw_hp_bar:
    pushq %rbp
    movq %rsp, %rbp

    pushq (%rdi) # gc -8rbp
    pushq 8(%rdi) # wi -16
    pushq 16(%rdi) # di -24
    movq %rsi, -48(%rbp)
    subq $32, %rsp

    # Convert the hp integer to a string
    movq %rsi, %rdi
    leaq -32(%rbp), %rsi
    call int_to_string
    movq %rax, -40(%rbp)

    # compute the red shade based on hp
    movq $0x0000ff, %rax
    movq -48(%rbp), %rsi
    mulq %rsi
    movq $100, %rsi
    divq %rsi
    movq %rax, %rcx
    movq $0x00ff00, %rax
    movq -48(%rbp), %rsi
    mulq %rsi
    movq $100, %rsi
    divq %rsi
    andq $0x00ff00, %rax
    orq %rax, %rcx
    orq $0xff0000, %rcx

    # Set the colour
    movq %rcx, %rdx	# white / red
    movq -8(%rbp), %rsi	
    movq -24(%rbp), %rdi
	call XSetForeground@PLT

    # Compute the size of the bar
    movq $640, %rax
    movq -48(%rbp), %rdi
    mulq %rdi
    movq $100, %rdi
    divq %rdi

    # Draw the health bar
    pushq $10
    movq %rax, %r9
    movq $0, %r8
    movq $0, %rcx
    movq -8(%rbp), %rdx
    movq -16(%rbp), %rsi
    movq -24(%rbp), %rdi
    call XFillRectangle@PLT

    movq %rbp, %rsp
    popq %rbp
    ret

/*
Converts int to string
%rdi - integer
(%rsi) - address of where to save the string
return - the number of characters in the string
*/
int_to_string:
    pushq %rbp
    movq %rsp, %rbp

    # Convert the integer to a character array
    movq %rdi, %rax
    movq $0, %rdi
    movq $10, %rcx
    loop_int_to_string:
        movq $0, %rdx
        divq %rcx
        addq $48, %rdx
        movb %dl, (%rsi, %rdi)
        incq %rdi
        testq %rax, %rax
        jnz loop_int_to_string
    movb $0, (%rsi, %rdi)
    
    pushq %rdi
    
    # Reverse the character array
    movq $0, %rdx
    loop_reverse_string:
        decq %rdi
        cmpq %rdi, %rdx
        je dont_reverse
        movb (%rsi, %rdi), %cl
        movb (%rsi, %rdx), %r8b
        movb %cl, (%rsi, %rdx)
        movb %r8b, (%rsi, %rdi)
        incq %rdx
        cmpq %rdi, %rdx
        je dont_reverse
        jmp loop_reverse_string

    dont_reverse:
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    ret


/*
Draws the current combo
(%rdi) - gc struct
%rsi - combo
*/
draw_current_combo:
    pushq %rbp
    movq %rsp, %rbp

    pushq (%rdi) # gc -8(%rbp)
    pushq 8(%rdi) # wi -16(%rbp)
    pushq 16(%rdi) # di -24(%rbp)
    subq $48, %rsp

    # Convert the combo integer to a string
    movq %rsi, %rdi
    leaq -72(%rbp), %rsi
    call int_to_string
    movq %rax, -32(%rbp)

    # Set the colour
    movq $0xffffff, %rdx	# White
    movq -8(%rbp), %rsi	
    movq -24(%rbp), %rdi
	call XSetForeground@PLT

    # Draw the combo
    movq -32(%rbp), %rax
    pushq %rax
    leaq -72(%rbp), %r9
    movq $LANE_HEIGHT, %r8
    subq $150, %r8
    movq $500, %rcx
    movq -8(%rbp), %rdx
    movq -16(%rbp), %rsi
    movq -24(%rbp), %rdi
    call XDrawImageString@PLT

    movq %rbp, %rsp
    popq %rbp
    ret

/*
Draws the current string
(%rdi) - gc struct
%rsi - score
*/
draw_current_score:
    pushq %rbp
    movq %rsp, %rbp

    pushq (%rdi) # gc -8(%rbp)
    pushq 8(%rdi) # wi -16(%rbp)
    pushq 16(%rdi) # di -24(%rbp)
    subq $16, %rsp

    # Convert the score integer to a string
    movq %rsi, %rdi
    leaq -32(%rbp), %rsi
    call int_to_string
    movq %rax, -40(%rbp)

    # Set the colour
    movq $0xffffff, %rdx	# White
    movq -8(%rbp), %rsi	
    movq -24(%rbp), %rdi
	call XSetForeground@PLT

    # Draw the score
    movq -40(%rbp), %rax
    pushq %rax
    leaq -32(%rbp), %r9
    movq $LANE_HEIGHT, %r8
    subq $170, %r8
    movq $500, %rcx
    movq -8(%rbp), %rdx
    movq -16(%rbp), %rsi
    movq -24(%rbp), %rdi
    call XDrawImageString@PLT

    movq %rbp, %rsp
    popq %rbp
    ret

/*
Draw the metadata of the map
(%rdi) - gc struct
(%rsi) - metadata string
%rdx - number of chars
*/
draw_metadata:
    pushq %rbp
    movq %rsp, %rbp

    # Push the arguments to the stack and save callee saved reg %rbx
    pushq (%rdi) # gc -8(%rbp)
    pushq 8(%rdi) # wi -16(%rbp)
    pushq 16(%rdi) # di -24(%rbp)
    pushq %rsi # -32(%rbp)
    pushq %rdx # -40(%rbp)
    pushq %rbx
    subq $8, %rsp

    # Set the colour
    movq $0xffffff, %rdx # White
    movq -8(%rbp), %rsi	
    movq -24(%rbp), %rdi
	call XSetForeground@PLT

    # Splits the metadata into six lines at '\n' and prints them below each other
    movq $6, %rbx
    draw_metadata_loop:
            movq -32(%rbp), %r9
            movq $0, %rdi
        draw_metadata_substring_loop:
            incq %rdi
            cmpb $10, (%r9, %rdi)
            jne draw_metadata_substring_loop

        # Draws the line
        movq %rdi, %rax
        pushq %rax
        movq -32(%rbp), %r9
        incq %rdi
        addq %rdi, -32(%rbp)
        movq $30, %r8
        movq $6, %rax
        subq %rbx, %rax
        movq $15, %rdi
        mulq %rdi
        addq %rax, %r8
        movq $10, %rcx
        movq -8(%rbp), %rdx
        movq -16(%rbp), %rsi
        movq -24(%rbp), %rdi
        call XDrawImageString@PLT
        addq $8, %rsp
        decq %rbx
        jnz draw_metadata_loop

    addq $8, %rsp
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
