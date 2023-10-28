.global save_highscore

file_mode: .asciz "w"
string: .asciz "Highscore:%d\nMax combo:%d\n"
error_message: .asciz "Failed to open/create a highscore file"

# Create a file or overwrite an existing one with new scores.
# %rdi - file name
# %rsi - max score
# %rdx - max combo
# return the file pointer
save_highscore:
    # stack:
    # -8(%rbp) - max score
    # -16(%rbp) - max combo
    # -24(%rbp) - file pointer
    pushq %rbp
    movq %rsp, %rbp
    pushq %rsi
    pushq %rdx
    subq $16, %rsp

    # Open or create a file
    # %rdi already contains file name
    movq $file_mode, %rsi
    call fopen
    testq %rax, %rax
	jz fopen_failed
    movq %rax, -24(%rbp)

    # Print the score and combo
    movq -16(%rbp), %rcx
    movq -8(%rbp), %rdx
    movq $string, %rsi
    movq -24(%rbp), %rdi
    call fprintf

    end:
    # Close the file
    movq -24(%rbp), %rdi
    call fclose

    movq -24(%rbp), %rax
    movq %rbp, %rsp
    popq %rbp
    ret

# Print an error message in the terminal
fopen_failed:
    movq $error_message, %rdi
    movq $0, %rax
    call printf
    jmp end
