
.text
.equ UPKEY, 111
.equ DOWNKEY, 116
.equ ENTERKEY, 36
mapsfolder: .asciz "./maps/" #LEN 7
mapslist: .asciz "/maps.txt" #LEN 9
slash: .asciz "/"
format: .asciz "%s\n"
format2: .asciz "%d\n"



.global start_select_map
/*
-40  = display
-48  = window
-56  = gc
-72  = time since last frame

-80  = pressed up
-88  = pressed down
-96  = pressed enter
-104 = pressed up old
-112 = pressed down old
-120 = pressed enter old

-128 = choices
-136 = chosen map
-144 = maps.txt
-152 = maps.txt length
-160 = map types
-168 = map file names
-176 = event location
-184 = width
-192 = height


/*
Intro screen to select map
%RDI - GC struct
%RSI - event pointer location
%RDX - width
%RCX - height
%R8  - directory path
%R9  - map
*/
start_select_map:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    # Save gc struct to memory
    subq $256, %rsp
    movq (%rdi), %rax
    movq %rax, -56(%rbp)
    addq $8, %rdi
    movq (%rdi), %rax
    movq %rax, -48(%rbp)
    addq $8, %rdi
    movq (%rdi), %rax
    movq %rax, -40(%rbp)
    movq %rsi, %r12
    movq %rsi, -176(%rbp)
    movq %rdx, -184(%rbp)
    movq %rcx, -192(%rbp)
    movq %r8, -200(%rbp)
    movq %r9, -208(%rbp)

    movq $0, -80(%rbp)
    movq $0, -88(%rbp)
    movq $0, -96(%rbp)
    
    # Open the maps directory
    movq $mapsfolder, %rdi
    call opendir@PLT
    movq %rax, %r15

    # Read all directories in the maps directory. Exclude all directory names below size 3 to ignore '.' and '..'
    movq $0, %r13
    read_dirs:
        movq %r15, %rdi
        call readdir@PLT
        movq %rax, %r14

        cmpq $0, %r14
        je end_read_dirs

        addq $19, %r14
        movq %r14, %rdi
        call strlen@PLT

        cmpq $2, %rax
        jle next_dir
        incq %r13

        movq %rax, %rdi
        call malloc@PLT

        movq %rax, %rdi
        movq %r14, %rsi
        call strcpy@PLT

        pushq %rdi
        pushq %rdi
        next_dir:
        jmp read_dirs
    end_read_dirs:
    # Clean up the directory object
    movq %r15, %rdi
    call closedir@PLT

    # Allocate memory for directory name strings
    movq %r13, %rax
    movq $8, %rdi
    mulq %rdi

    movq %rax, %rdi
    call malloc@PLT
    movq %rax, %rdi

    # Copy all directories into the array
    movq $0, %r8
    save_dirs:
        popq %rax
        popq %rax
        movq %rax, (%rdi, %r8, 8)

        incq %r8
        cmpq %r8, %r13
        je end_save_dirs
        jmp save_dirs
    end_save_dirs:
    movq %rdi, -128(%rbp)



    # Loop which displays the menu for map selection
    leaq -72(%rbp), %rdi
    movq $0, %rsi
    call gettimeofday
    # Current map selection
    movq $0, %r15
    loop_select_dir:
        # Save previous inputs to be able to process keypresses
        movq -80(%rbp), %rax
        movq %rax, -104(%rbp)
        movq -88(%rbp), %rax
        movq %rax, -112(%rbp)
        movq -96(%rbp), %rax
        movq %rax, -120(%rbp)
        # Handle events
        start_events_dirs:  
            # Check if there are any pending events
            movq -40(%rbp), %rdi
            call XPending@PLT
            cmp $0, %rax
            je no_event_dirs

            # Get the next event
            movq -40(%rbp), %rdi
            movq %r12, %rsi
            call XNextEvent@PLT

            # Check if it is keypress event, if so, handle it
            movq %r12, %rdi
            cmpl $2, (%rdi)
            jne not_keypress_event_dirs

            leaq -96(%rbp), %rsi
            call handle_keypress_event_dirs

            not_keypress_event_dirs:

            # Check if it is keyrelease event, if so, handle it
            movq %r12, %rdi
            cmpl $3, (%rdi)
            jne not_keyrelease_event_dirs

            leaq -96(%rbp), %rsi
            call handle_keyrelease_event_dirs
            not_keyrelease_event_dirs:

            # Jump back in case there are multiple events to handle
            jmp start_events_dirs
        no_event_dirs:

        # Check if we pressed the UP key
        cmpq $1, -80(%rbp)
        jne didnt_press_up
        cmpq $0, -104(%rbp)
        jne didnt_press_up
        decq %r15
        didnt_press_up:

        # Check if we pressed the DOWN key
        cmpq $1, -88(%rbp)
        jne didnt_press_down
        cmpq $0, -112(%rbp)
        jne didnt_press_down
        incq %r15
        didnt_press_down:

        # Make sure map selection doesn't go out of bounds by wrapping around
        cmpq $0, %r15
        jl normalize_up
        cmpq %r13, %r15
        jge normalize_down
        jmp normalize_end
        normalize_down:
            subq %r13, %r15
            jmp normalize_end
        normalize_up:
            addq %r13, %r15
            jmp normalize_end
        normalize_end:

        # Limit fps
        leaq -72(%rbp), %rdi
        call time_since
        cmp $5000, %rax
        jl loop_select_dir

        # Exit loop if we press enter, save choice.
        cmpq $1, -96(%rbp)
        jne didnt_press_enter
        cmpq $0, -120(%rbp)
        jne didnt_press_enter
        jmp end_loop_select_dir
        didnt_press_enter:

        leaq -56(%rbp), %rdi
        movq -128(%rbp), %rsi
        movq %r13, %rdx
        movq %r15, %rcx
        call draw_choices
        jmp loop_select_dir
    end_loop_select_dir:

    # Get the maps.txt file of the chosen map
    movq -128(%rbp), %rdi
    movq (%rdi, %r15, 8), %rdi
    movq %rdi, -136(%rbp)
    call load_map_variants_txt
    movq %rax, -144(%rbp)

    # Load the file
    movq %rax, %rdi
    leaq -152(%rbp), %rsi
    movq $0, %rdx
    movq $1, %rcx
    call read_file
    
    movq %rax, %rdi
    movq -152(%rbp), %rsi
    leaq -160(%rbp), %rdx
    leaq -168(%rbp), %rcx
    call load_variant_data
    movq %rax, %r13

    movq -40(%rbp), %rdi
    movq -48(%rbp), %rsi
    movq $0, %rdx
    movq $0, %rcx
    movq -184(%rbp), %r8
    movq -196(%rbp), %r9
    subq $8, %rsp
    pushq $1
    call XClearArea@PLT
    addq $16, %rsp

    # Loop which displays the menu for variant selection
    leaq -72(%rbp), %rdi
    movq $0, %rsi
    call gettimeofday
    # Current variant selection
    movq $0, %r15
    loop_select_file:
        # Save previous inputs to be able to process keypresses
        movq -80(%rbp), %rax
        movq %rax, -104(%rbp)
        movq -88(%rbp), %rax
        movq %rax, -112(%rbp)
        movq -96(%rbp), %rax
        movq %rax, -120(%rbp)
        # Handle events
        start_events_file:  
            # Check if there are any pending events
            movq -40(%rbp), %rdi
            call XPending@PLT
            cmp $0, %rax
            je no_event_file

            # Get the next event
            movq -40(%rbp), %rdi
            movq -176(%rbp), %rsi
            call XNextEvent@PLT

            # Check if it is keypress event, if so, handle it
            movq -176(%rbp), %rdi
            cmpl $2, (%rdi)
            jne not_keypress_event_file

            leaq -96(%rbp), %rsi
            call handle_keypress_event_dirs

            not_keypress_event_file:

            # Check if it is keyrelease event, if so, handle it
            movq -176(%rbp), %rdi
            cmpl $3, (%rdi)
            jne not_keyrelease_event_file

            leaq -96(%rbp), %rsi
            call handle_keyrelease_event_dirs
            not_keyrelease_event_file:

            # Jump back in case there are multiple events to handle
            jmp start_events_file
        no_event_file:

        # Check if we pressed the UP key
        cmpq $1, -80(%rbp)
        jne didnt_press_up_file
        cmpq $0, -104(%rbp)
        jne didnt_press_up_file
        decq %r15
        didnt_press_up_file:

        # Check if we pressed the DOWN key
        cmpq $1, -88(%rbp)
        jne didnt_press_down_file
        cmpq $0, -112(%rbp)
        jne didnt_press_down_file
        incq %r15
        didnt_press_down_file:

        # Make sure map selection doesn't go out of bounds by wrapping around
        cmpq $0, %r15
        jl normalize_up_file
        cmpq %r13, %r15
        jge normalize_down_file
        jmp normalize_end_file
        normalize_down_file:
            subq %r13, %r15
            jmp normalize_end_file
        normalize_up_file:
            addq %r13, %r15
            jmp normalize_end_file
        normalize_end_file:

        # Limit fps
        leaq -72(%rbp), %rdi
        call time_since
        cmp $5000, %rax
        jl loop_select_file

        # Exit loop if we press enter, save choice.
        cmpq $1, -96(%rbp)
        jne didnt_press_enter_file
        cmpq $0, -120(%rbp)
        jne didnt_press_enter_file
        jmp end_loop_select_file
        didnt_press_enter_file:

        leaq -56(%rbp), %rdi
        movq -168(%rbp), %rsi
        movq %r13, %rdx
        movq %r15, %rcx
        call draw_choices
        jmp loop_select_file
    end_loop_select_file:
    movq -160(%rbp), %rdi
    movq (%rdi, %r15, 8), %rdi
    movq %rdi, %r15

    movq %rdi, -136(%rbp)
    call load_map_directory_path
    movq -200(%rbp), %r8
    movq -208(%rbp), %r9
    movq %rax, (%r8)
    movq %r15, (%r9)

    addq $256, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    movq %rbp, %rsp
    popq %rbp
ret

/*
RDI - maps.txt data
RSI - maps.txt length 
RDX - return address of map file names
RCX - return address of map display names
*/
load_variant_data:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r12 # Number of maps
    pushq %r13 
    pushq %r14 
    pushq %r15

    pushq %rdi #-40
    pushq %rsi #-48
    pushq %rdx #-56
    pushq %rcx #-64

    movq $0, %r8
    movq $0, %r10
    count_colons:
        movzb (%rdi, %r8, 1), %r9
        cmpq $58, %r9
        je is_colon
        jmp next_char
        is_colon:
            incq %r10

        next_char:
        incq %r8
        cmpq -48(%rbp), %r8
        je end_count_colons
        jmp count_colons
    end_count_colons:
    movq %r10, %r12 # Number of maps

    movq %r10, %rax
    movq $8, %rdi
    mulq %rdi
    movq %rax, %r13

    movq %r13, %rdi
    call malloc@PLT
    pushq %rax #-72: map type

    movq %r13, %rdi
    call malloc@PLT
    pushq %rax #-80: map file


    movq $0, %r13
    movq $0, %r15
    movq -40(%rbp), %r14
    parse_line:
        movq %r14, %rdi
        movq $58, %rsi
        call strchr@PLT
        movq %rax, %r15
        subq %r14, %r15
        addq $1, %r15

        movq %r15, %rdi
        call malloc@PLT
        movq -72(%rbp), %rsi
        movq %rax, (%rsi, %r13, 8)

        addq %r15, %rax
        movb $0, -1(%rax)

        movq (%rsi, %r13, 8), %rdi
        movq %r14, %rsi
        movq %r15, %rdx
        decq %rdx
        call memcpy@PLT

        movq %r14, %rdi
        movq $58, %rsi
        call strchr@PLT
        movq %rax, %r14
        incq %r14

        movq %r14, %rdi
        movq $10, %rsi
        call strchr@PLT
        movq %rax, %r15
        subq %r14, %r15
        addq $1, %r15

        movq %r15, %rdi
        call malloc@PLT
        movq -80(%rbp), %rsi
        movq %rax, (%rsi, %r13, 8)

        addq %r15, %rax
        movb $0, -1(%rax)
        
        movq (%rsi, %r13, 8), %rdi
        movq %r14, %rsi
        movq %r15, %rdx
        decq %rdx
        call memcpy@PLT

        movq %r14, %rdi
        movq $10, %rsi
        call strchr@PLT
        movq %rax, %r14
        incq %r14

        incq %r13
        cmpq %r13, %r12
        je end_parse_line
        jmp parse_line
    end_parse_line:

    movq %r12, %rax
    movq -56(%rbp), %rdx
    movq -64(%rbp), %rcx
    movq -72(%rbp), %rdi
    movq %rdi, (%rcx)
    movq -80(%rbp), %rdi
    movq %rdi, (%rdx)

    leaq -32(%rbp), %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    movq %rbp, %rsp
    popq %rbp
ret

/*
RDI - chosen map directory name
*/
load_map_directory_path:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r12 # Chosen map
    pushq %r13 # "/"
    pushq %r14 # Chosen map length
    pushq %r15

    movq %rdi, %r12
    call strlen
    movq %rax, %r14

    movq %rax, %rdi
    addq $9, %rdi
    call malloc@PLT
    movq %rax, %r13

    movq %r13, %rdi
    movq $mapsfolder, %rsi
    call strcpy

    movq %r13, %rdi
    addq $7, %rdi #maps folder name is 7 chars long
    movq %r12, %rsi
    call strcpy

    movq %r13, %rdi
    addq $7, %rdi #maps folder name is 9 chars long
    addq %r14, %rdi
    movq $slash, %rsi
    call strcpy

    movq %r13, %rdi
    addq $8, %rdi
    addq %r14, %rdi
    movb $0, (%rdi) #Null terminated

    movq %r13, %rax
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    movq %rbp, %rsp
    popq %rbp
ret

/*
RDI - chosen map directory name
*/
load_map_variants_txt:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r12 # Chosen map
    pushq %r13 # Path to maps.txt
    pushq %r14 # Chosen map length
    pushq %r15

    movq %rdi, %r12
    call strlen
    movq %rax, %r14

    movq %rax, %rdi
    addq $17, %rdi
    call malloc@PLT
    movq %rax, %r13

    movq %r13, %rdi
    movq $mapsfolder, %rsi
    call strcpy

    movq %r13, %rdi
    addq $7, %rdi #maps folder name is 7 chars long
    movq %r12, %rsi
    call strcpy

    movq %r13, %rdi
    addq $7, %rdi #maps folder name is 9 chars long
    addq %r14, %rdi
    movq $mapslist, %rsi
    call strcpy

    movq %r13, %rdi
    addq $16, %rdi
    addq %r14, %rdi
    movb $0, (%rdi) #Null terminated

    movq %r13, %rax
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    movq %rbp, %rsp
    popq %rbp
ret

handle_keypress_event_dirs:
    pushq %rbp
    movq %rsp, %rbp

    # Switch case to check which key was pressed. Keycodes are constants defined near the start of the program
    movq 84(%rdi), %rdi
    cmpl $UPKEY, %edi
    je pressed_up
    cmpl $DOWNKEY, %edi
    je pressed_down
    cmpl $ENTERKEY, %edi
    je pressed_enter

    # Simply set the value to 1 to describe whether lane is pressed
    pressed_up:
        movq $1, 16(%rsi)
        jmp key_press_end_dir
    pressed_down:
        movq $1, 8(%rsi)
        jmp key_press_end_dir
    pressed_enter:
        movq $1, 0(%rsi)
        jmp key_press_end_dir
    key_press_end_dir:
    
    movq %rbp, %rsp
    popq %rbp
ret

# Exact same subroutine as above, however this handles the release of a key
handle_keyrelease_event_dirs:
    pushq %rbp
    movq %rsp, %rbp

    # Switch case to check which key was released. Keycodes are constants defined near the start of the program
    movq 84(%rdi), %rdi
    cmpl $UPKEY, %edi
    je released_up
    cmpl $DOWNKEY, %edi
    je released_down
    cmpl $ENTERKEY, %edi
    je released_enter

    # Simply set the value to 0 to describe whether lane is released
    released_up:
        movq $0, 16(%rsi)
        jmp key_release_end_dir
    released_down:
        movq $0, 8(%rsi)
        jmp key_release_end_dir
    released_enter:
        movq $0, (%rsi)
        jmp key_release_end_dir
    key_release_end_dir:

    movq %rbp, %rsp
    popq %rbp
ret
