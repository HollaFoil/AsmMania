.global read_file

.equ SEEK_SET,  0
.equ SEEK_CUR,  1
.equ SEEK_END,  2
.equ EOF,      -1

file_mode: .asciz "r"

# arguments:
# %rdi - string of file path and name
# %rsi - address to return the bytes_read
# output:
# %rax - address to the allocated memory where the read contents of the file are
# (%rsi) - the size of the file in bytes

read_file:
	# stack:
	# -8(%rbp) BYTES_READ pointer
	# -16(%rbp) FILE pointer
	# -24(%rbp) file size
	# -32(%rbp) address of allocated buffer
    pushq %rbp
    movq %rsp, %rbp

    subq $32, %rsp

    # save BYTES_READ address
    movq %rsi, -8(%rbp)

    # open file
	movq $file_mode, %rsi
	call fopen
	testq %rax, %rax
	jz fopen_failed
	movq %rax, -16(%rbp)

    # seek to end of file
	movq %rax, %rdi
	movq $0, %rsi
	movq $SEEK_END, %rdx
	call fseek
	testq %rax, %rax
	jnz fseek_failed

    # get current position in file (length of file)
	movq -16(%rbp), %rdi
	call ftell
	cmpq $EOF, %rax
	je ftell_failed
	movq %rax, -24(%rbp)

    # seek back to start
	movq -16(%rbp), %rdi
	movq $0, %rsi
	movq $SEEK_SET, %rdx
	call fseek
	testq %rax, %rax
	jnz fseek_failed

    # allocate memory and store pointer
	# allocate file_size + 16 for a trailing null octaword (for reasons)
	movq -24(%rbp), %rdi
	addq $16, %rdi
	call malloc
	test %rax, %rax
	jz malloc_failed
	movq %rax, -32(%rbp)

    # read file contents
	movq %rax, %rdi # pointer to allocated memory
	movq $1, %rsi
	movq -24(%rbp), %rdx
	movq -16(%rbp), %rcx
	call fread
	movq -8(%rbp), %rdi
	movq %rax, (%rdi)

    # add a trailing null octaword
	movq -32(%rbp), %rdi
	movq $0, (%rdi, %rax)
    movq $0, 8(%rdi, %rax)

    # close file descriptor
	movq -16(%rbp), %rdi
	call fclose

	# return address of allocated buffer
	movq -32(%rbp), %rax
	movq %rbp, %rsp
	popq %rbp
	ret

malloc_failed:
ftell_failed:
fseek_failed:
	# close file
	movq -16(%rbp), %rdi
	call fclose

fopen_failed:
    # set read_bytes to 0 and return 0
	movq -8(%rbp), %rax
	movq $0, (%rax)
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    ret
