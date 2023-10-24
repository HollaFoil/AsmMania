.global main

format: .asciz "%ld\n"
file: .asciz "maps/sus.wav"

/*
-16(%rbp) = time since last frame in microseconds
-24(%rbp) = time since last frame in seconds

-32(%rbp) = display
-40(%rbp) = window
-48(%rbp) = gc
-56(%rbp) = width
-64(%rbp) = height

-272(%rbp) = next event

-280(%rbp) = lane1pressed
-288(%rbp) = lane2pressed
-296(%rbp) = lane3pressed
-304(%rbp) = lane4pressed

-312(%rbp) = should clear frame (potentially unused)

-320(%rbp) = pcm handle
-328(%rbp) = frames (period)






wip
-336(%rbp) = volume 0-15
-336(%rbp) = size of hit sound in bytes
-344(%rpb) = pointer to hit sound

-336(%rbp) = preview_time 
-344(%rbp) = song offset
-352(%rbp) = size of song in bytes
-360(%rbp) = pointer to song
-368(%rbp) = no. hit objects
-376(%rbp) = pointer to hit obj

-384(%rbp) = global time offset in microseconds
-392(%rbp) = global time offset in seconds

-400       = lane 1 gradient (0 - 1000)
-408       = lane 2 gradient (0 - 1000)
-416       = lane 3 gradient (0 - 1000)
-424       = lane 4 gradient (0 - 1000)

-432       = first object to draw

-440(%rbp) = bytes
-448(%rbp) = pointer to file


*/

.text
.equ KEY1, 26
.equ KEY2, 41
.equ KEY3, 44
.equ KEY4, 31
.equ KEY1ALTERNATE, 40
.equ KEY4ALTERNATE, 45

.equ FADE_OUT_SPEED, 50
.equ FADE_IN_SPEED, 200
.equ MAX_FADE, 900


main:
    pushq %rbp
    movq %rsp, %rbp

    subq $448, %rsp
    movq $640, -56(%rbp)
    movq $900, -64(%rbp)
    leaq -48(%rbp), %rdi
    movq -56(%rbp), %rsi
    movq -64(%rbp), %rdx
    call init_window

    movq $0, -280(%rbp)
    movq $0, -288(%rbp)
    movq $0, -296(%rbp)
    movq $0, -304(%rbp)

    movq $0, -432(%rbp)

    movq $1000, -400(%rbp)
    movq $1000, -408(%rbp)
    movq $1000, -416(%rbp)
    movq $1000, -424(%rbp)

    leaq -320(%rbp), %rdi
    leaq -328(%rbp), %rsi
    call create_pcm_handle

    leaq -368(%rbp), %rdi
    call load_config
    movq %rax, -376(%rbp)

    leaq -440(%rbp), %rsi
    movq $file, %rdi
    call read_file
    movq %rax, -448(%rbp) # save address of sound fx

    leaq -392(%rbp), %rdi
    movq $0, %rsi
    call gettimeofday

    leaq -24(%rbp), %rdi
    movq $0, %rsi
    call gettimeofday
    loop:
        # Handle events
        movq -32(%rbp), %rdi
        call XPending@PLT
        cmp $0, %rax
        je no_event

        movq -32(%rbp), %rdi
        leaq -272(%rbp), %rsi
        call XNextEvent@PLT

        leaq -272(%rbp), %rdi
        cmpl $2, (%rdi)
        jne not_keypress_event

        leaq -304(%rbp), %rsi
        call handle_keypress_event

        # sound fx on keypress (doesnt work correctly when a key is held)
        movq -344(%rbp), %rcx
        movq -360(%rbp), %rdx
        movq -440(%rbp), %rsi
        movq -448(%rbp), %rdi
        call play_sound_fx

        not_keypress_event:

        leaq -272(%rbp), %rdi
        cmpl $3, (%rdi)
        jne not_keyrelease_event

        leaq -304(%rbp), %rsi
        call handle_keyrelease_event
        not_keyrelease_event:

        leaq -272(%rbp), %rdi
        leaq -304(%rbp), %rsi

        cmpl $12, (%rdi)
        jne not_expose_event
        not_expose_event:
        no_event:

        #Handle song
        movq -320(%rbp), %rdi
        movq -360(%rbp), %rsi
        movq -344(%rbp), %r9
        addq %r9, %rsi
        movq $128, %rdx
        call snd_pcm_writei@PLT
        cmpq $-11, %rax # Error code -11, EAGAIN, driver not ready to accept new data
        je should_not_advance_song
        addq $512, -344(%rbp)

        should_not_advance_song:


        leaq -24(%rbp), %rdi
        call time_since
        cmp $5000, %rax
        jl loop

        
        movq $format, %rdi
        movq %rax, %rsi
        movq $0, %rax
        #call printf

        # Handle fade animations by adding/subtracting values each frame depending on if button pressed
        cmpq $1, -280(%rbp)
        je lane1pressed
        jmp lane1notpressed
        lane1pressed:
            addq $FADE_IN_SPEED, -400(%rbp)
            cmpq $MAX_FADE, -400(%rbp)
            jl nextlane_1
            movq $MAX_FADE, -400(%rbp)
            jmp nextlane_1
        lane1notpressed:
            subq $FADE_OUT_SPEED, -400(%rbp)
            cmpq $0, -400(%rbp)
            jg nextlane_1
            movq $0, -400(%rbp)
            jmp nextlane_1
        nextlane_1:
        cmpq $1, -288(%rbp)
        je lane2pressed
        jmp lane2notpressed
        lane2pressed:
            addq $FADE_IN_SPEED, -408(%rbp)
            cmpq $MAX_FADE, -408(%rbp)
            jl nextlane_2
            movq $MAX_FADE, -408(%rbp)
            jmp nextlane_2
        lane2notpressed:
            subq $FADE_OUT_SPEED, -408(%rbp)
            cmpq $0, -408(%rbp)
            jg nextlane_2
            movq $0, -408(%rbp)
            jmp nextlane_2
        nextlane_2:
        cmpq $1, -296(%rbp)
        je lane3pressed
        jmp lane3notpressed
        lane3pressed:
            addq $FADE_IN_SPEED, -416(%rbp)
            cmpq $MAX_FADE, -416(%rbp)
            jl nextlane_3
            movq $MAX_FADE, -416(%rbp)
            jmp nextlane_3
        lane3notpressed:
            subq $FADE_OUT_SPEED, -416(%rbp)
            cmpq $0, -416(%rbp)
            jg nextlane_3
            movq $0, -416(%rbp)
            jmp nextlane_3
        nextlane_3:
        cmpq $1, -304(%rbp)
        je lane4pressed
        jmp lane4notpressed
        lane4pressed:
            addq $FADE_IN_SPEED, -424(%rbp)
            cmpq $MAX_FADE, -424(%rbp)
            jl endlanes
            movq $MAX_FADE, -424(%rbp)
            jmp endlanes
        lane4notpressed:
            subq $FADE_OUT_SPEED, -424(%rbp)
            cmpq $0, -424(%rbp)
            jg endlanes
            movq $0, -424(%rbp)
            jmp endlanes
        endlanes:

        leaq -24(%rbp), %rdi
        movq $0, %rsi
        call gettimeofday

        movq -32(%rbp), %rdi
        movq -40(%rbp), %rsi
        movq $0, %rdx
        movq $0, %rcx
        movq -56(%rbp), %r8
        movq -64(%rbp), %r9
        subq $8, %rsp
        pushq $1
        call XClearArea@PLT
        addq $16, %rsp

        movq -280(%rbp), %rsi
        movq -288(%rbp), %rdx
        movq -296(%rbp), %rcx
        movq -304(%rbp), %r8
        leaq -48(%rbp), %rdi
        leaq -424(%rbp), %r9
        call draw_play_area

        pushq %r14
        pushq %r15
        leaq -392(%rbp), %rdi
        call time_since # get time since start of map

        movq $0, %rdx 
        movq $1000, %rcx
        idivq %rcx # convert microseconds to miliseconds
        movq %rax, %r14

        movq -432(%rbp), %r15
        hit_obj_loop:
            movq -376(%rbp), %rdi

            movq $0, %rsi
            movl (%rdi, %r15, 8), %esi # get lane of hit object

            movq $0, %rdx
            movl 8(%rdi, %r15, 8), %edx # get time of hit object
            subq %r14, %rdx # get the offset

            movq $0, %rcx
            movl 4(%rdi, %r15, 8), %ecx # get if slider
            testl %ecx, %ecx # look if slider
            jz regular_obj # jump if not slider
            
            movl 12(%rdi, %r15, 8), %ecx # get slider time
            subq %r14, %rcx # get offset
            cmpq $-2000, %rcx # check if slider end is below screen
            jg keep_obj
            addq $2, -432(%rbp)
            jmp next_obj

            regular_obj:
            cmpq $-2000, %rdx # check if obj is below screen
            jg keep_obj
            addq $2, -432(%rbp)
            jmp next_obj

            keep_obj:
            cmpq $2000, %rdx # check if object is above screen
            jg end_hit_obj_drawing
            
            leaq -48(%rbp), %rdi # get window or smth
            #shlq $1, %rdx # doubled the speed
            #shlq $1, %rcx # doubled the speed
            call draw_hit_object

            next_obj:
            addq $2, %r15 # increment the index by 2
            movq -368(%rbp), %rdi # get number of objects
            shlq $1, %rdi # multiply by 2

            cmpq %r15, %rdi
            jne hit_obj_loop
        end_hit_obj_drawing:

        popq %r15
        popq %r14


        jmp loop
    end:
    movq %rbp, %rsp
    popq %rbp

    movq $0, %rdi
call exit


/*
rdi      = pointer to event
rsi      = pointer to lane4pressed
rsi + 8  = pointer to lane3pressed
rsi + 16 = pointer to lane2pressed
rsi + 24 = pointer to lane1pressed
*/
handle_keypress_event:
    pushq %rbp
    movq %rsp, %rbp

    movq 84(%rdi), %rdi
    cmpl $KEY1, %edi
    je pressed_key_1
    cmpl $KEY2, %edi
    je pressed_key_2
    cmpl $KEY3, %edi
    je pressed_key_3
    cmpl $KEY4, %edi
    je pressed_key_4
    cmpl $KEY1ALTERNATE, %edi
    je pressed_alternate_key_1
    cmpl $KEY4ALTERNATE, %edi
    je pressed_alternate_key_4
    jmp key_press_end

    pressed_key_1:
    pressed_alternate_key_1:
        movq $1, 24(%rsi)
        jmp key_press_end
    pressed_key_2:
        movq $1, 16(%rsi)
        jmp key_press_end
    pressed_key_3:
        movq $1, 8(%rsi)
        jmp key_press_end
    pressed_key_4:
    pressed_alternate_key_4:
        movq $1, (%rsi)
        jmp key_press_end


    key_press_end:
    movq %rbp, %rsp
    popq %rbp
ret

handle_keyrelease_event:
    pushq %rbp
    movq %rsp, %rbp

    movq 84(%rdi), %rdi
    cmpl $KEY1, %edi
    je released_key_1
    cmpl $KEY2, %edi
    je released_key_2
    cmpl $KEY3, %edi
    je released_key_3
    cmpl $KEY4, %edi
    je released_key_4
    cmpl $KEY1ALTERNATE, %edi
    je released_alternate_key_1
    cmpl $KEY4ALTERNATE, %edi
    je released_alternate_key_4
    jmp key_release_end

    released_key_1:
    released_alternate_key_1:
        movq $0, 24(%rsi)
        jmp key_release_end
    released_key_2:
        movq $0, 16(%rsi)
        jmp key_release_end
    released_key_3:
        movq $0, 8(%rsi)
        jmp key_release_end
    released_key_4:
    released_alternate_key_4:
        movq $0, (%rsi)
        jmp key_release_end


    key_release_end:
    movq %rbp, %rsp
    popq %rbp
ret

