.global main

format: .asciz "%ld\n"
format2: .asciz "%ld %ld\n"
format3: .asciz "%ld %ld %ld\n"

final_combo_message: .asciz "Highest combo: %d\n"
score_message: .asciz "Score: %d\n"
lost_message: .asciz "You lost!\n"
map_cleared_message: .asciz "You have cleared the map!\n"

map_folder: .asciz "maps/Camellia - WHAT THE CAT!?/"
map_variant: .asciz "map1"

/* RESERVED STACK SPACE = 656 BYTES
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

-336(%rpb) = pointer to hit sound
-344(%rbp) = size of hit sound in bytes
-352(%rbp) = song offset

-368(%rbp) = best accurracy
-376(%rbp) = all time highscore
-384(%rbp) = all time max combo
-392(%rbp) = highscore file name
-400(%rbp) = metadata number of chars
-408(%rbp) = metadata
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


-520       = num of events

-528       = lane1pressed old
-536       = lane2pressed old
-544       = lane3pressed old
-552       = lane4pressed old

player performance struct
-560(%rbp) = current accurracy
-568(%rbp) = ideal current accurracy
-576(%rbp) = text_state
-584(%rbp) = hp
-592(%rbp) = current combo
-600(%rbp) = max combo
-608(%rbp) = score


-624 = holding note lane 1 (-1 if not holding)
-632 = holding note lane 2 (-1 if not holding)
-640 = holding note lane 3 (-1 if not holding)
-648 = holding note lane 4 (-1 if not holding)
-656 = map directory
-664 = map variant
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

    subq $704, %rsp

    # Create game window, with size 900x640
    movq $640, -56(%rbp)
    movq $900, -64(%rbp)
    leaq -48(%rbp), %rdi
    movq -56(%rbp), %rsi
    movq -64(%rbp), %rdx
    call init_window

    # Select map menu
    leaq -48(%rbp), %rdi
    leaq -272(%rbp), %rsi
    movq -56(%rbp), %rdx
    movq -64(%rbp), %rcx
    leaq -656(%rbp), %r8
    leaq -664(%rbp), %r9
    call start_select_map

    # Initialize stack values/variables to required values
    movq $0, -280(%rbp)
    movq $0, -288(%rbp)
    movq $0, -296(%rbp)
    movq $0, -304(%rbp)

    movq $0, -496(%rbp)

    movq $1000, -464(%rbp)
    movq $1000, -472(%rbp)
    movq $1000, -480(%rbp)
    movq $1000, -488(%rbp)

    movq $-1, -624(%rbp)
    movq $-1, -632(%rbp)
    movq $-1, -640(%rbp)
    movq $-1, -648(%rbp)

    movq $0, -576(%rbp)
    movq $100, -584(%rbp) # set hp to 100
    movq $0, -592(%rbp)
    movq $0, -600(%rbp)
    movq $0, -608(%rbp)
    movq $1, -568(%rbp)
    movq $1, -560(%rbp)

    # Create the ALSA pcm handle used for audio playback
    leaq -320(%rbp), %rdi
    leaq -328(%rbp), %rsi
    call create_pcm_handle

    # Load config.txt file
    leaq -344(%rbp), %rdi
    call load_config
    movq %rax, -352(%rbp)

    # Load map
    movq -664(%rbp), %rdx
    movq -656(%rbp), %rsi
    leaq -432(%rbp), %rdi
    call load_map
    movq %rax, -440(%rbp)

    # Get time object, which corresponds to time at the start of the map
    leaq -456(%rbp), %rdi
    movq $0, %rsi
    call gettimeofday

    # Get time object, which corresponds to time since last frame
    leaq -24(%rbp), %rdi
    movq $0, %rsi
    call gettimeofday
    loop:
        # Save previously saved button presses, which are used to differentiate between held and just pressed keys
        movq -280(%rbp), %rax
        movq %rax, -528(%rbp)
        movq -288(%rbp), %rax
        movq %rax, -536(%rbp)
        movq -296(%rbp), %rax
        movq %rax, -544(%rbp)
        movq -304(%rbp), %rax
        movq %rax, -552(%rbp)

        # Handle events
        start_events:  
            # Check if there are any pending events
            movq -32(%rbp), %rdi
            call XPending@PLT
            cmp $0, %rax
            je no_event

            # Get the next event
            movq -32(%rbp), %rdi
            leaq -272(%rbp), %rsi
            call XNextEvent@PLT

            # Check if it is keypress event, if so, handle it
            leaq -272(%rbp), %rdi
            cmpl $2, (%rdi)
            jne not_keypress_event

            leaq -304(%rbp), %rsi
            call handle_keypress_event

            not_keypress_event:

            # Check if it is keyrelease event, if so, handle it
            leaq -272(%rbp), %rdi
            cmpl $3, (%rdi)
            jne not_keyrelease_event

            leaq -304(%rbp), %rsi
            call handle_keyrelease_event
            not_keyrelease_event:

            # Jump back in case there are multiple events to handle
            jmp start_events
        no_event:

        # Check if any key was just pressed, and if so, play the hitsound sound effect
        movq $0, %rdi
        check_keypress:
            cmpq $1, -304(%rbp, %rdi, 8)
            jne next_iter_check_keypress
            cmpq $0, -552(%rbp, %rdi, 8)
            jne next_iter_check_keypress
            jmp play_sfx

            next_iter_check_keypress:
            incq %rdi
            cmpq $4, %rdi
            je end_check_keypress
            jmp check_keypress
        end_check_keypress:
        jmp dont_play_sfx

        play_sfx:
        movq -352(%rbp), %rcx
        movq -424(%rbp), %rdx
        movq -344(%rbp), %rsi
        movq -336(%rbp), %rdi
        call play_sound_fx
        dont_play_sfx:

        # Check how many frames are buffered in the song, don't send too many for input delay issues
        movq -320(%rbp), %rdi
        call snd_pcm_avail@PLT
        cmpq $32, %rax
        jl should_not_advance_song

        # Check if song has ended
        movq -352(%rbp), %rdi
        addq $1024, %rdi
        movq -416(%rbp), %rsi
        cmpq %rdi, %rsi
        jl song_end

        # Write 1024 bytes of song (256 frames) into the pcm buffer
        movq -320(%rbp), %rdi
        movq -424(%rbp), %rsi
        movq -352(%rbp), %r9
        addq %r9, %rsi
        movq $256, %rdx
        call snd_pcm_writei@PLT
        cmpq $-11, %rax # Error code -11, EAGAIN, driver not ready to accept new data

        je should_not_advance_song
        addq $1024, -352(%rbp)

        # Sometimes pcm throws error code -32 - underrun
        cmpq $0, %rax
        je no_event

        should_not_advance_song:

        # Get the time since the start of the map, used for timing reasons
        leaq -456(%rbp), %rdi
        call time_since 
        movq $0, %rdx 
        movq $1000, %rcx
        divq %rcx 
        movq %rax, %r8
        pushq %r8

        # Handle object hits
        movq -432(%rbp), %r10
        leaq -304(%rbp), %rdi
        leaq -552(%rbp), %rsi
        movq -440(%rbp), %rdx
        movq -496(%rbp), %rcx
        leaq -608(%rbp), %r9
        leaq -648(%rbp), %rax
        pushq %rax
        call handle_hit
        popq %rax
        popq %r8

        # Handle hold note releases
        leaq -304(%rbp), %rdi
        movq %r8, %rsi
        leaq -608(%rbp), %rdx
        leaq -648(%rbp), %rcx
        call handle_release
        
        # Get time since last frame. Frame time is limited to >5ms
        leaq -24(%rbp), %rdi
        call time_since
        cmp $5000, %rax
        jl loop
        
        # Handle fade animations by adding/subtracting values each frame depending on if button pressed
        # Render code is located in render.s, this just sets the fade amount
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

        # Get time since last frame
        leaq -24(%rbp), %rdi
        movq $0, %rsi
        call gettimeofday

        # Clear entire window to color black
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

        # Draw the background play area - lanes, fade effect, hit line
        movq -280(%rbp), %rsi
        movq -288(%rbp), %rdx
        movq -296(%rbp), %rcx
        movq -304(%rbp), %r8
        leaq -48(%rbp), %rdi
        leaq -488(%rbp), %r9
        call draw_play_area

        # Draw various text items
        leaq -576(%rbp), %rsi
        leaq -48(%rbp), %rdi
        call draw_status_text

        movq -592(%rbp), %rsi
        leaq -48(%rbp), %rdi
        call draw_current_combo

        movq -608(%rbp), %rsi
        leaq -48(%rbp), %rdi
        call draw_current_score

        movq -376(%rbp), %rsi
        leaq -48(%rbp), %rdi
        call draw_highscore

        movq -384(%rbp), %rsi
        leaq -48(%rbp), %rdi
        call draw_max_combo

        movq -560(%rbp), %rax
        movq $100, %rdi
        mulq %rdi
        movq -568(%rbp), %rdi
        divq %rdi
        movq %rax, %rsi
        leaq -48(%rbp), %rdi
        call draw_current_accuracy

        movq -368(%rbp), %rsi
        leaq -48(%rbp), %rdi
        call draw_max_accuracy

        movq -400(%rbp), %rdx
        movq -408(%rbp), %rsi
        leaq -48(%rbp), %rdi
        call draw_metadata

        # Get the time since the start of the map
        pushq %r14
        pushq %r15
        leaq -456(%rbp), %rdi
        call time_since

        # Convert the time to miliseconds
        movq $0, %rdx 
        movq $1000, %rcx
        divq %rcx
        movq %rax, %r14

        # Draw all the hitobjects that are currently in view
        movq -496(%rbp), %r15
        hit_obj_loop:
            movq -440(%rbp), %rdi

            # Skip if object status is 1, meaning the object is hit
            movq $0, %rsi
            movw 6(%rdi, %r15, 8), %si
            cmpq $1, %rsi
            je next_obj

            # Check if slider start is still in the future, meaning we should not trim it on keypress, yet 
            cmpl %r14d, 8(%rdi, %r15, 8)
            jg dont_trim_slider

            # Check if object status is 2 or 3, in which case it is a slider that has been hit and we should trim it
            cmpq $2, %rsi
            je trim_slider
            cmpq $3, %rsi
            je trim_slider
            jmp dont_trim_slider

            # Trim slider to only extend down to the hit line, for visual reasons
            trim_slider:
            movl %r14d, 8(%rdi, %r15, 8)
            cmpl %r14d, 12(%rdi, %r15, 8)
            jl next_obj
            dont_trim_slider:

            # Get the lane of the hit object
            movq $0, %rsi
            movl (%rdi, %r15, 8), %esi

            # Get the height/hit time of the hit object
            movq $0, %rdx
            movl 8(%rdi, %r15, 8), %edx
            # Get the time offset since the start of the song
            subq %r14, %rdx

            # Check if the hit object is a slider or a regular object
            movq $0, %rcx
            movw 4(%rdi, %r15, 8), %cx
            testw %cx, %cx
            jz regular_obj
            
            # Since this is a slider, we also need to get the slider end time
            movl 12(%rdi, %r15, 8), %ecx
            # Get slider end time since start of song
            subq %r14, %rcx
            # Check if slider is below the screen
            cmpq $-2000, %rcx
            jg keep_obj
            addq $2, -496(%rbp)
            jmp next_obj

            regular_obj:
            # Check if object is below the screen, in which case we never want to render this object again
            cmpq $-2000, %rdx
            jg keep_obj
            addq $2, -496(%rbp)
            jmp next_obj

            keep_obj:
            # Check if object is above the screen, in which case we stop rendering objects
            cmpq $2000, %rdx
            jg end_hit_obj_drawing

            # Check whether we've missed any objects
            pushq %rcx
            pushq %rdx
            pushq %rsi
            pushq %rdi
            movq %rdx, %rsi
            movq %rcx, %rdx
            leaq -608(%rbp), %rcx
            leaq (%rdi, %r15, 8), %rdi
            call check_for_miss
            popq %rdi
            popq %rsi
            popq %rdx
            popq %rcx
            
            # Draw the hit object
            leaq -48(%rbp), %rdi
            call draw_hit_object

            next_obj:
            # Increment index by 2, as each object is 2*8 bytes
            addq $2, %r15 

            # Check if we're not at the end of the object list
            movq -432(%rbp), %rdi 
            shlq $1, %rdi 
            cmpq %r15, %rdi
            jne hit_obj_loop
        end_hit_obj_drawing:

        # Draw the hp bar at the top of the screen
        movq -584(%rbp), %rsi
        leaq -48(%rbp), %rdi
        call draw_hp_bar

        popq %r15
        popq %r14

        # Jump back to the start of the game loop
        jmp loop

    # After song has finished, exit the program
    song_end:
    # Print map cleared message in the terminal
    movq $map_cleared_message, %rdi
    movq $0, %rax
    call printf

    # Print final score
    movq -608(%rbp), %rsi
    movq $score_message, %rdi
    movq $0, %rax
    call printf

    # Print max combo
    movq -600(%rbp), %rsi
    movq $final_combo_message, %rdi
    movq $0, %rax
    call printf

    # Update the highscore and max combo
    movq -560(%rbp), %rax
    movq $100, %rdi
    mulq %rdi
    movq -568(%rbp), %rdi
    divq %rdi
    movq -368(%rbp), %rcx
    cmpq %rcx, %rax
    cmovgq %rax, %rcx
    movq -600(%rbp), %rdx
    movq -384(%rbp), %r8
    cmpq %r8, %rdx
    cmovlq %r8, %rdx
    movq -608(%rbp), %rsi
    movq -376(%rbp), %r8
    cmpq %r8, %rsi
    cmovlq %r8, %rsi
    movq -392(%rbp), %rdi
    call save_highscore

    end:
    # Play the remaining samples in the buffer, close the PCM handle and exit
    movq -320(%rbp), %rdi
    call snd_pcm_drain@PLT
    movq -320(%rbp), %rdi
    call snd_pcm_close@PLT

    movq %rbp, %rsp
    popq %rbp
    movq $0, %rdi
    call exit


/*
Subroutine to handle event when a key is pressed
rdi      = pointer to event
rsi      = pointer to lane4pressed
rsi + 8  = pointer to lane3pressed
rsi + 16 = pointer to lane2pressed
rsi + 24 = pointer to lane1pressed
*/
handle_keypress_event:
    pushq %rbp
    movq %rsp, %rbp

    # Switch case to check which key was pressed. Keycodes are constants defined near the start of the program
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

    # Simply set the value to 1 to describe whether lane is pressed
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

# Exact same subroutine as above, however this handles the release of a key
handle_keyrelease_event:
    pushq %rbp
    movq %rsp, %rbp

    # Switch case to check which key was released. Keycodes are constants defined near the start of the program
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

    # Simply set the value to 0 to describe whether lane is released
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
R9  - player performance struct
R10 - number of total hit objects

STACK1 - lanes holding struct
*/
handle_hit:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    # Store all subroutine arguments on stack
    subq $64, %rsp
    movq %rdi, -40(%rbp)
    movq %rsi, -48(%rbp)
    movq %rdx, -56(%rbp)
    movq %rcx, -64(%rbp)
    movq %r8, -72(%rbp)
    movq %r9, -80(%rbp)
    movq 16(%rbp), %rax
    movq %rax, -88(%rbp)

    # Double the total hit obj
    shlq %r10

    # Loop through each lane and find first object which is within the required timing threshold
    movq -56(%rbp), %rdi
    movq $0, %r9
    find_closest_obj_loop:
        movq -64(%rbp), %r15
        movq $-20000, %r13
        movq $-1, %r8
        find_loop:
            # Get the time offset of this hit object since start of song
            movq $0, %rdx
            movl 8(%rdi, %r15, 8), %edx
            subq -72(%rbp), %rdx

            # Absolute value of offset
            movq %rdx, %r12
            movq %r12, %rax
            sarq $63, %rax
            movq %rax, %rdx
            xorq %r12, %rdx
            subq %rax, %rdx

            # Check if object is within threshold
            cmpq $140, %r12
            jg end_find_loop

            cmpq $-100, %r12
            jl next_iter

            # Check if object has been hit, i.e. check if state = 1
            movq $0, %rsi
            movw 6(%rdi, %r15, 8), %si
            cmpq $0, %rsi
            jne next_iter

            # Check if this object is in the correct lane
            movq $0, %rsi
            movl (%rdi, %r15, 8), %esi
            cmpq %rsi, %r9
            jne next_iter

            # All conditions passed, therefore we save values and "hit" this object
            movq %r15, %r8
            movq %rdx, %r13
            jmp end_find_loop

            # Try next object
            next_iter:
            addq $2, %r15
            cmpq %r10, %r15
            je end_find_loop
            jmp find_loop

        end_find_loop:
        incq %r9
        
        pushq %rdi
        pushq %r9

        # Check if we found and object to hit
        cmpq $-1, %r8
        je dont_set_status

        # "Hit" this object and handle game logic
        leaq (%rdi, %r8, 8), %rdi
        movq -40(%rbp), %rsi
        movq -48(%rbp), %rdx
        movq %r13, %rcx
        movq -80(%rbp), %r8
        movq -88(%rbp), %r9
        call set_obj_status_to_hit

        dont_set_status:

        popq %r9
        popq %rdi

        # Only 4 lanes, therefore we break when lane counter is too high
        cmpq $4, %r9
        je end_find_closest_obj_loop
        jmp find_closest_obj_loop
    end_find_closest_obj_loop:
    
    addq $64, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    movq %rbp, %rsp
    popq %rbp
ret

/*
Handle the release of hold notes
RDI - currently pressed lanes (struct of 4 qw)
RSI - time since start of song (ms)
RDX - player performance struct
RCX - lanes holding struct
*/
handle_release:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    subq $32, %rsp
    movq %rdi, -40(%rbp)
    movq %rsi, -48(%rbp)
    movq %rdx, -56(%rbp)
    movq %rcx, -64(%rbp)

    # R9 is a memory offset for each lane. Each lane holding info is 8 bytes, so offsets are 0, 8, 16, 24
    movq $24, %r9
    handle_unholding_notes_loop:
        # Check if we are still holding the key
        movq -40(%rbp), %rdi
        addq %r9, %rdi
        cmpq $1, (%rdi)
        je next_iter_release

        # Check if we were pressing and holding a note
        movq -64(%rbp), %rdi
        addq %r9, %rdi
        cmpq $-1, (%rdi)
        je next_iter_release
        # We no longer are holding, so set the holding note address to -1 (not holding any note)
        movq (%rdi), %r8
        movq $-1, (%rdi)

        # Get the offset of the hold note's end since start of song
        movq $0, %rdx
        movl 12(%r8), %edx
        subq -48(%rbp), %rdx

        # Absolute value of the offset
        movq %rdx, %r12
        movq %r12, %rax
        sarq $63, %rax
        movq %rax, %rdx
        xorq %r12, %rdx
        subq %rax, %rdx
        
        pushq %rdi
        pushq %r9

        # We release this object and handle game logic
        movq %r8, %rdi
        movq %rdx, %rsi
        movq -56(%rbp), %rdx
        call set_obj_status_to_released

        popq %r9
        popq %rdi

        # Handle next iteration. Break if lane offset is below 0 (first such value is -8, so we break when it hits -8)
        next_iter_release:
        subq $8, %r9
        cmpq $-8, %r9
        je end_handle_unholding_notes_loop
        jmp handle_unholding_notes_loop
    end_handle_unholding_notes_loop:

    addq $32, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    movq %rbp, %rsp
    popq %rbp
ret

/*
Release a hold note
%RDI - obj location
%RSI - delay
(%RDX) - player performance struct
*/
set_obj_status_to_released:
    pushq %rbp
    movq %rsp, %rbp

    # Set note status to 3
    movw $3, 6(%rdi)

    # Update text
    movq %rdx, %rdi
    call handle_note_press

    movq %rbp, %rsp
    popq %rbp
ret

/*
%RDI - obj location
(%RSI) - curr lanes pressed
(%RDX) - prev lanes pressed
%RCX - delay
(%R8) - player performance struct
(%R9) - lanes held struct
*/
set_obj_status_to_hit:
    pushq %rbp
    movq %rsp, %rbp

    pushq %r8
    pushq %r9

    # Calculate memory offset for the given lane the object is in
    movq $0, %rax
    movl (%rdi), %eax
    movq $-8, %r9 
    pushq %rdx
    imulq %r9
    popq %rdx
    addq $24, %rax

    # Add this offset to required struct addresses
    addq %rax, %rsi
    addq %rax, %rdx
    movq (%rsi), %r8
    movq (%rdx), %r9

    # Check if we JUST pressed this key (not holding)
    cmpq $1, %r8
    jne end_set_obj
    cmpq $0, %r9
    jne end_set_obj

    pushq %rdi
    pushq %rax

    # Update text
    movq %rcx, %rsi
    movq -8(%rbp), %rdi
    call handle_note_press

    popq %rax
    popq %rdi

    # Check if this is a hold note
    movw 4(%rdi), %dx
    cmpw $1, %dx
    jne set_status_regular_obj

    # This is a hold note, so we set status to 2, meaning holding.
    # We also save the hold note index to the holding notes struct 
    movw $2, 6(%rdi)
    popq %r9
    addq %rax, %r9
    movq %rdi, (%r9)
    jmp end_set_obj

    set_status_regular_obj:
    # Set status to 1, meaning hit
    movw $1, 6(%rdi)

    end_set_obj:
    movq %rbp, %rsp
    popq %rbp
ret

/*
(%rdi) - player_performance struct
%rsi - absolute delay of keypress
*/
handle_note_press:
    pushq %rbp
    movq %rsp, %rbp

    # Save the struct in stack
    pushq %rdi # -8(%rbp)
    pushq %rdi

    # Determine the accuracy based on delay
    cmpq $30, %rsi
    jle perfect
    cmpq $60, %rsi
    jle nice
    cmpq $100, %rsi
    jle ok

    # Missed: reset combo, lower health, set to display the "Missed" text
    movq $0, 16(%rdi)
    # Increase ideal acc
    addq $3, 40(%rdi)
    # Set the flag for miss and update the text status
    movq $1, %rsi
    movq -8(%rbp), %rdi
    leaq 32(%rdi), %rdi
    call set_text_status
    # Lower the health
    movq -8(%rbp), %rdi
    leaq 24(%rdi), %rdi
    movq $-6, %rsi
    call handle_health

    jmp end_set_handle_note_press
    
    # Increase combo and score, lower health, set to display the "Ok" text
    ok:
    # Increment the combo
    incq 16(%rdi)
    # Increase current and ideal acc
    addq $3, 40(%rdi)
    addq $1, 48(%rdi)
    # Update the max combo
    movq 16(%rdi), %rsi
    addq %rsi, (%rdi)
    movq 8(%rdi), %rdx
    cmpq %rdx, %rsi
    cmovg %rsi, %rdx
    movq %rdx, 8(%rdi)
    # Set the flag for ok and update the text status
    movq $2, %rsi
    movq -8(%rbp), %rdi
    leaq 32(%rdi), %rdi
    call set_text_status
    # Lower health
    movq -8(%rbp), %rdi
    leaq 24(%rdi), %rdi
    movq $-1, %rsi
    call handle_health

    jmp end_set_handle_note_press

    # Increase combo and score, increment health, set to display the "Nice!" text
    nice:
    incq 16(%rdi)
    # Increase ideal acc
    addq $3, 40(%rdi)
    addq $2, 48(%rdi)
    # Update the max combo
    movq 16(%rdi), %rax
    shlq %rax
    addq %rax, (%rdi)
    movq 8(%rdi), %rdx
    cmpq %rdx, %rsi
    cmovg %rsi, %rdx
    movq %rdx, 8(%rdi)
    # Set the flag for nice and update the text status
    movq $3, %rsi
    movq -8(%rbp), %rdi
    leaq 32(%rdi), %rdi
    call set_text_status
    # Increase the health
    movq -8(%rbp), %rdi
    leaq 24(%rdi), %rdi
    movq $1, %rsi
    call handle_health

    jmp end_set_handle_note_press

    # Increase combo and score, increment health by 2, set to display the "Perfect!" text
    perfect:
    incq 16(%rdi)
    # Increase current and ideal acc
    addq $3, 40(%rdi)
    addq $3, 48(%rdi)
    # Update the max combo
    movq 16(%rdi), %rax
    movq $3, %rdx
    mulq %rdx
    addq %rax, (%rdi)
    movq 8(%rdi), %rdx
    cmpq %rdx, %rsi
    cmovg %rsi, %rdx
    movq %rdx, 8(%rdi)
    # Set the flag for perfect and update the text status
    movq $4, %rsi
    movq -8(%rbp), %rdi
    leaq 32(%rdi), %rdi
    call set_text_status
    # Increase the health
    movq -8(%rbp), %rdi
    leaq 24(%rdi), %rdi
    movq $2, %rsi
    call handle_health

    end_set_handle_note_press:
    movq %rbp, %rsp
    popq %rbp
    ret

/*
Update the hit status
args:
(%rdi) - text_state obj address
First 32 bits specify string
0 - no text, 1 - Ok, 2 - Nice!, 3 - Perfect!, 4 - Missed
Last 32 bits specify frames left to draw
%rsi - miss/ok/nice/perfect 1-4
*/
set_text_status:
    pushq %rbp
    movq %rsp, %rbp

    shlq $32, %rsi
    # How many frames for message to display
    addq $60, %rsi 
    movq %rsi, (%rdi)

    movq %rbp, %rsp
    popq %rbp
    ret

# Updates the health, ends game if hp goes to 0
# args:
# (%rdi) - global hp address
# %rsi - hp lost or gained
handle_health:
    pushq %rbp
    movq %rsp, %rbp

    # Copy hp, modify the copy and check if it's 0 or less
    movq (%rdi), %rdx
    addq %rsi, %rdx
    cmpq $0, %rdx
    jle dead

    # Ensures that hp doesn't go above 100
    cmpq $100, %rdx
    jle no_health_overflow

    movq $100, %rdx

    no_health_overflow:
    # Update the global hp
    movq %rdx, (%rdi)

    movq %rbp, %rsp
    popq %rbp
    ret

/*
Prints the lost_message, final score, max combo and exits the program
(%rdi) - health address
*/
dead:
    subq $8, %rsp
    pushq %rdi

    # Print the messages
    movq $lost_message, %rdi
    movq $0, %rax
    call printf

    popq %rdi
    pushq %rdi
    movq -24(%rdi), %rsi
    movq $score_message, %rdi
    movq $0, %rax
    call printf
    
    popq %rdi
    pushq %rdi
    movq -16(%rdi), %rsi
    movq $final_combo_message, %rdi
    movq $0, %rax
    call printf

    # Play the remaining samples in the buffer
    popq %rdi
    pushq %rdi
    movq 264(%rdi), %rdi
    call snd_pcm_drain@PLT
    # Close the PCM handle
    popq %rdi
    pushq %rdi
    movq 264(%rdi), %rdi
    call snd_pcm_close@PLT

    movq $0, %rdi
    call exit

/*
# Checks if a note below a certain treshold hasn't been hit and triggers a miss in that case
%rdi - hit object address
%rsi - note offset
%rdx - slider end offset
%rcx - player_performance struct
*/
check_for_miss:
    pushq %rbp
    movq %rsp, %rbp

    # Save the player_perfomance struct
    pushq %rcx # -8(%rbp)
    subq $8, %rsp

    # Check if it's a slider
    cmpw $1, 4(%rdi)
    je check_for_miss_slider

    # Checks a regular note

    # Check if it was hit already
    cmpw $1, 6(%rdi) 
    je note_fulfilled
    # Check if it was missed and accounted for already
    cmpw $1, 2(%rdi)
    je note_fulfilled
    # Check if it was missed
    cmpq $-100, %rsi
    jge note_fulfilled

    # Trigger a miss
    # Set the flag for being accounted for
    movw $1, 2(%rdi) 
    # Lower the health
    movq $-5, %rsi
    movq -8(%rbp), %rdi
    leaq 24(%rdi), %rdi
    call handle_health
    # Increase ideal acc
    movq -8(%rbp), %rdi
    addq $3, 40(%rdi)
    # Reset combo
    movq $0, 16(%rdi) 
    jmp note_fulfilled

    # Checks a slider
    check_for_miss_slider:
    # Check if it was hit fully already
    cmpw $3, 6(%rdi)
    je note_fulfilled
    # Check if the start has been hit already
    cmpw $2, 6(%rdi) 
    je slider_start_fulfilled

    # Check slider start

    # Check if it was missed and accounted for already
    cmpw $1, 2(%rdi) 
    je note_fulfilled
    # Check if it was missed
    cmpq $-100, %rsi 
    jge note_fulfilled

    # Trigger a miss

    # Set the flag for only slider start being accounted for
    movw $1, 2(%rdi) 
    # Lower the health
    movq $-5, %rsi 
    movq -8(%rbp), %rdi
    leaq 24(%rdi), %rdi
    call handle_health
    # Increase ideal acc
    movq -8(%rbp), %rdi
    addq $3, 40(%rdi)
    # Reset combo
    movq $0, 16(%rdi)
    jmp note_fulfilled

    # Check slider end
    slider_start_fulfilled:
    cmpw $2, 2(%rdi) # check if it was missed and accounted for already
    je note_fulfilled
    cmpq $-100, %rdx # check if it was missed
    jge note_fulfilled

    # Trigger a miss
    # Set the flag for whole slider being accounted for
    movw $2, 2(%rdi)
    # Lower the health
    movq $-5, %rsi
    movq -8(%rbp), %rdi
    leaq 24(%rdi), %rdi
    call handle_health
    # Increase ideal acc
    movq -8(%rbp), %rdi
    addq $3, 40(%rdi)
    # Reset combo
    movq $0, 16(%rdi)
    jmp note_fulfilled

    note_fulfilled:
    movq %rbp, %rsp
    popq %rbp
    ret
