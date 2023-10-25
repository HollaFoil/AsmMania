.global main

format: .asciz "%ld\n"
format2: .asciz "%ld %ld\n"
format3: .asciz "%ld %ld %ld\n"

/* RESERVED STACK SPACE = 640 BYTES
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
-376(%rbp) = volume 0-100
-384(%rbp) = size of hit sound in bytes
-392(%rpb) = pointer to hit sound

-400(%rbp) = preview_time 
-408(%rbp) = song offset
-416(%rbp) = size of song in bytes
-424(%rbp) = pointer to song
-432(%rbp) = no. hit objects
-440(%rbp) = pointer to hit obj

-448(%rbp) = global time offset in microseconds
-456(%rbp) = global time offset in seconds

-464       = lane 1 gradient (0 - 1000)
-472       = lane 2 gradient (0 - 1000)
-480       = lane 3 gradient (0 - 1000)
-488       = lane 4 gradient (0 - 1000)

-496       = first object to draw

-504(%rbp) = text_state
-512(%rbp) = hp

-520       = num of events





-544       = lane1pressed old
-552       = lane2pressed old
-560       = lane3pressed old
-568       = lane4pressed old


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

    subq $640, %rsp
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

    movq $0, -496(%rbp)

    movq $1000, -464(%rbp)
    movq $1000, -472(%rbp)
    movq $1000, -480(%rbp)
    movq $1000, -488(%rbp)

    leaq -320(%rbp), %rdi
    leaq -328(%rbp), %rsi
    call create_pcm_handle

    leaq -432(%rbp), %rdi
    call load_config
    movq %rax, -440(%rbp)

    movq $0, -504(%rbp)
    movq $100, -512(%rbp) # set hp to 100

    leaq -456(%rbp), %rdi
    movq $0, %rsi
    call gettimeofday

    leaq -24(%rbp), %rdi
    movq $0, %rsi
    call gettimeofday
    loop:
        movq -280(%rbp), %rax
        movq %rax, -544(%rbp)
        movq -288(%rbp), %rax
        movq %rax, -552(%rbp)
        movq -296(%rbp), %rax
        movq %rax, -560(%rbp)
        movq -304(%rbp), %rax
        movq %rax, -568(%rbp)

        start_events:
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
            movq -408(%rbp), %rcx
            movq -424(%rbp), %rdx
            movq -384(%rbp), %rsi
            movq -392(%rbp), %rdi
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
            
            jmp start_events
        no_event:

        #Handle song
        movq -320(%rbp), %rdi
        call snd_pcm_avail@PLT
        cmpq $32, %rax
        jl should_not_advance_song

        # check if song has ended
        movq -408(%rbp), %rdi
        addq $512, %rdi
        movq -416(%rbp), %rsi
        cmpq %rdi, %rsi
        jl end

        movq -320(%rbp), %rdi
        movq -424(%rbp), %rsi
        movq -408(%rbp), %r9
        addq %r9, %rsi
        movq $128, %rdx
        call snd_pcm_writei@PLT
        cmpq $-11, %rax # Error code -11, EAGAIN, driver not ready to accept new data
        je should_not_advance_song
        addq $512, -408(%rbp)

        should_not_advance_song:

        leaq -456(%rbp), %rdi
        call time_since 
        movq $0, %rdx 
        movq $1000, %rcx
        divq %rcx 
        movq %rax, %r8

        leaq -304(%rbp), %rdi
        leaq -568(%rbp), %rsi
        movq -440(%rbp), %rdx
        movq -496(%rbp), %rcx
        leaq -504(%rbp), %r9
        leaq -512(%rbp), %r10
        call handle_hit
    

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
            addq $FADE_IN_SPEED, -464(%rbp)
            cmpq $MAX_FADE, -464(%rbp)
            jl nextlane_1
            movq $MAX_FADE, -464(%rbp)
            jmp nextlane_1
        lane1notpressed:
            subq $FADE_OUT_SPEED, -464(%rbp)
            cmpq $0, -464(%rbp)
            jg nextlane_1
            movq $0, -464(%rbp)
            jmp nextlane_1
        nextlane_1:
        cmpq $1, -288(%rbp)
        je lane2pressed
        jmp lane2notpressed
        lane2pressed:
            addq $FADE_IN_SPEED, -472(%rbp)
            cmpq $MAX_FADE, -472(%rbp)
            jl nextlane_2
            movq $MAX_FADE, -472(%rbp)
            jmp nextlane_2
        lane2notpressed:
            subq $FADE_OUT_SPEED, -472(%rbp)
            cmpq $0, -472(%rbp)
            jg nextlane_2
            movq $0, -472(%rbp)
            jmp nextlane_2
        nextlane_2:
        cmpq $1, -296(%rbp)
        je lane3pressed
        jmp lane3notpressed
        lane3pressed:
            addq $FADE_IN_SPEED, -480(%rbp)
            cmpq $MAX_FADE, -480(%rbp)
            jl nextlane_3
            movq $MAX_FADE, -480(%rbp)
            jmp nextlane_3
        lane3notpressed:
            subq $FADE_OUT_SPEED, -480(%rbp)
            cmpq $0, -480(%rbp)
            jg nextlane_3
            movq $0, -480(%rbp)
            jmp nextlane_3
        nextlane_3:
        cmpq $1, -304(%rbp)
        je lane4pressed
        jmp lane4notpressed
        lane4pressed:
            addq $FADE_IN_SPEED, -488(%rbp)
            cmpq $MAX_FADE, -488(%rbp)
            jl endlanes
            movq $MAX_FADE, -488(%rbp)
            jmp endlanes
        lane4notpressed:
            subq $FADE_OUT_SPEED, -488(%rbp)
            cmpq $0, -488(%rbp)
            jg endlanes
            movq $0, -488(%rbp)
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
        leaq -488(%rbp), %r9
        call draw_play_area

        leaq -504(%rbp), %rsi
        leaq -48(%rbp), %rdi
        call draw_text

        movq -512(%rbp), %rsi
        leaq -48(%rbp), %rdi
        call draw_hp_text

        pushq %r14
        pushq %r15
        leaq -456(%rbp), %rdi
        call time_since # get time since start of map

        movq $0, %rdx 
        movq $1000, %rcx
        divq %rcx # convert microseconds to miliseconds
        movq %rax, %r14

        movq -496(%rbp), %r15
        hit_obj_loop:
            movq -440(%rbp), %rdi

            movq $0, %rsi
            movw 6(%rdi, %r15, 8), %si # skip if status = 1 (object hit)
            cmpq $1, %rsi
            je next_obj

            movq $0, %rsi
            movw 6(%rdi, %r15, 8), %si # skip if status = 1 (object hit)
            cmpq $2, %rsi
            jne dont_trim_slider
            movl %r14d, 8(%rdi, %r15, 8)

            cmpl %r14d, 12(%rdi, %r15, 8)
            jl next_obj
            dont_trim_slider:

            movq $0, %rsi
            movl (%rdi, %r15, 8), %esi # get lane of hit object

            movq $0, %rdx
            movl 8(%rdi, %r15, 8), %edx # get time of hit object
            subq %r14, %rdx # get the offset

            movq $0, %rcx
            movw 4(%rdi, %r15, 8), %cx # get if slider
            testw %cx, %cx # look if slider
            jz regular_obj # jump if not slider
            
            movl 12(%rdi, %r15, 8), %ecx # get slider time
            subq %r14, %rcx # get offset
            cmpq $-2000, %rcx # check if slider end is below screen
            jg keep_obj
            addq $2, -496(%rbp)
            jmp next_obj

            regular_obj:
            cmpq $-2000, %rdx # check if obj is below screen
            jg keep_obj
            addq $2, -496(%rbp)
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
            movq -432(%rbp), %rdi # get number of objects
            shlq $1, %rdi # multiply by 2

            cmpq %r15, %rdi
            jne hit_obj_loop
        end_hit_obj_drawing:

        popq %r15
        popq %r14


        jmp loop

    dead:
    end:
    movq -320(%rbp), %rdi
    call snd_pcm_drain@PLT
    movq -320(%rbp), %rdi
    call snd_pcm_close@PLT
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

/*
RDI - currently pressed lanes (struct of 4 qw)
RSI - previously pressed lanes (struct of 4 qw)
RDX - hit object array address
RCX - hit objects that have passed
R8  - time since start of song (ms)
R9  - text status address
R10 - global hp address
*/
handle_hit:
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    pushq %rbp
    movq %rsp, %rbp

    subq $64, %rsp
    movq %rdi, -8(%rbp)
    movq %rsi, -16(%rbp)
    movq %rdx, -24(%rbp)
    movq %rcx, -32(%rbp)
    movq %r8, -40(%rbp)
    movq %r9, -48(%rbp)
    movq %r10, -56(%rbp)

    movq -24(%rbp), %rdi
    movq $0, %r9
    find_closest_obj_loop:
        movq -32(%rbp), %r15
        movq $-20000, %r13
        movq $-1, %r8
        find_loop:
            movq $0, %rdx
            movl 8(%rdi, %r15, 8), %edx
            subq -40(%rbp), %rdx

            # Absolute value
            movq %rdx, %r12
            movq %r12, %rax
            sarq $63, %rax
            movq %rax, %rdx
            xorq %r12, %rdx
            subq %rax, %rdx

            cmpq $300, %r12
            jg end_find_loop

            cmpq $-100, %r12
            jl next_iter

            # Check state
            movq $0, %rsi
            movw 6(%rdi, %r15, 8), %si
            cmpq $0, %rsi
            jne next_iter

            movq $0, %rsi
            movl (%rdi, %r15, 8), %esi
            cmpq %rsi, %r9
            jne next_iter

            movq %r15, %r8
            movq %rdx, %r13
            jmp end_find_loop

            next_iter:
            addq $2, %r15
            jmp find_loop

        end_find_loop:
        incq %r9
        
        pushq %rdi
        pushq %r9
        cmpq $-1, %r8
        je dont_set_status

        leaq (%rdi, %r8, 8), %rdi
        movq -8(%rbp), %rsi
        movq -16(%rbp), %rdx
        movq %r13, %rcx
        movq -48(%rbp), %r8
        movq -56(%rbp), %r9
        call set_obj_status_to_hit

        
        dont_set_status:

        popq %r9
        popq %rdi

        cmpq $4, %r9
        je end_find_closest_obj_loop
        jmp find_closest_obj_loop
    end_find_closest_obj_loop:

    movq %rbp, %rsp
    popq %rbp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
ret

/*
%RDI - obj location
%RSI - curr lanes pressed
%RDX - prev lanes pressed
%RCX - delay
(%r8) - text status address
(%r9) - global hp address
*/
set_obj_status_to_hit:
    pushq %rbp
    movq %rsp, %rbp

    pushq %r8
    pushq %r9

    movq $0, %rax
    movl (%rdi), %eax
    movq $-8, %r9 
    pushq %rdx
    imulq %r9
    popq %rdx
    addq $24, %rax

    addq %rax, %rsi
    addq %rax, %rdx
    movq (%rsi), %r8
    movq (%rdx), %r9

    cmpq $1, %r8
    jne end_set_obj
    cmpq $0, %r9
    jne end_set_obj

    pushq %rdi
    pushq %rdi

    # update text
    movq -16(%rbp), %rdx
    movq %r12, %rsi
    movq -8(%rbp), %rdi
    call handle_note_press

    popq %rdi
    popq %rdi

    movw 4(%rdi), %ax
    cmpw $1, %ax
    jne set_status_regular_obj

    movw $2, 6(%rdi)
    jmp end_set_obj

    set_status_regular_obj:
    movw $1, 6(%rdi)

    end_set_obj:
    movq %rbp, %rsp
    popq %rbp
ret


# args:
# (%rdi) - text_state obj address
# %rsi - delay of keypress
# %rdx - global hp address
handle_note_press:
    pushq %rbp
    movq %rsp, %rbp

    pushq %rdi
    pushq %rdx

    cmpq $8, %rsi
    jle perfect
    cmpq $50, %rsi
    jle nice
    cmpq $100, %rsi
    jle ok

    #missed:
    movq $1, %rsi
    call set_text_status
    popq %rdi
    subq $8, %rsp
    movq $-3, %rsi
    call handle_health
    jmp end_set_handle_note_press
    
    ok:
    movq $2, %rsi
    call set_text_status
    popq %rdi
    subq $8, %rsp
    movq $0, %rsi
    call handle_health
    jmp end_set_handle_note_press

    nice:
    movq $3, %rsi
    call set_text_status
    popq %rdi
    subq $8, %rsp
    movq $1, %rsi
    call handle_health
    jmp end_set_handle_note_press

    perfect:
    movq $4, %rsi
    call set_text_status
    popq %rdi
    subq $8, %rsp
    movq $3, %rsi
    call handle_health


    end_set_handle_note_press:
    movq %rbp, %rsp
    popq %rbp
    ret

# args:
# (%rdi) - text_state obj address
# First 32 bits specify string
# 0 - no text, 1 - Ok, 2 - Nice!, 3 - Perfect!, 4 - missed perhaps
# Last 32 bits specify frames left to draw
# %rsi - miss/ok/nice/perfect 1-4
set_text_status:
    pushq %rbp
    movq %rsp, %rbp

    cmpq $4, %rsi
    je set_perfect
    cmpq $3, %rsi
    je set_nice
    cmpq $2, %rsi
    je set_ok

    set_missed:
    movq $4, %rsi
    jmp end_set_text
    
    set_ok:
    movq $1, %rsi
    jmp end_set_text

    set_nice:
    movq $2, %rsi
    jmp end_set_text

    set_perfect:
    movq $3, %rsi
    jmp end_set_text


    end_set_text:
    shlq $32, %rsi
    addq $60, %rsi # how many frames to last
    movq %rsi, (%rdi)

    movq %rbp, %rsp
    popq %rbp
    ret

# args:
# (%rdi) - global hp address
# %rsi - hp lost or gained
handle_health:
    pushq %rbp
    movq %rsp, %rbp

    movq (%rdi), %rdx
    addq %rsi, %rdx
    cmpq $0, %rdx
    jle dead

    cmpq $100, %rdx
    jle no_health_overflow
    
    movq $100, %rdx

    no_health_overflow:
    movq %rdx, (%rdi)

    movq %rbp, %rsp
    popq %rbp
    ret