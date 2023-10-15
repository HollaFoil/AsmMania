.global main

format: .asciz "%ld\n"
file: .asciz "maps/song.wav"

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

-336(%rbp) = no. hit objects (start of load_config.s)
-344(%rbp) = pointer to song
-352(%rbp) = size of song in bytes
-360(%rbp) = song offset
-368(%rbp) = pointer to hit obj
*/

.text
.equ KEY1, 26
.equ KEY2, 41
.equ KEY3, 44
.equ KEY4, 31
.equ KEY1ALTERNATE, 40
.equ KEY4ALTERNATE, 45


main:
    pushq %rbp
    movq %rsp, %rbp

    subq $480, %rsp
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

    leaq -320(%rbp), %rdi
    leaq -328(%rbp), %rsi
    call create_pcm_handle

    leaq -336(%rbp), %rdi
    call load_config
    movq %rax, -368(%rbp)

    #movq $file, %rdi
    #leaq -356(%rbp), %rsi
    #call read_file
    #movq %rax, -344(%rbp)
    #movq $242, -360(%rbp)

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
        movq -344(%rbp), %rsi
        movq -360(%rbp), %r9
        leaq (%rsi, %r9, 1), %rsi
        movq $1024, %rdx
        call snd_pcm_writei@PLT
        cmpq $-11, %rax # Error code -11, EAGAIN, driver not ready to accept new data
        je should_not_advance_song
        addq $4096, -360(%rbp)
        

        should_not_advance_song:


        leaq -24(%rbp), %rdi
        call time_since
        cmp $5000, %rax
        jl loop

        movq $format, %rdi
        movq %rax, %rsi
        movq $0, %rax
        call printf

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
        call draw_play_area


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

