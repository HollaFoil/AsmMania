.global read_file

.equ SEEK_SET,  0
.equ SEEK_CUR,  1
.equ SEEK_END,  2
.equ EOF,      -1

file_mode: .asciz "r"

# arguments:
# %rdi - string of file path and name
# %rsi - address to return the bytes_read
# %rdx - offset (default 0)
# %rcx - alignment (default 1)
# output:
# %rax - address to the allocated memory where the read contents of the file are
# (%rsi) - the size of the file in bytes

read_file:
	# stack:
	# -8(%rbp) BYTES_READ pointer
	# -16(%rbp) FILE pointer
	# -24(%rbp) file size
	# -32(%rbp) address of allocated buffer
	# -40(%rbp) number of trailing bytes to add
	# -48(%rbp) alignment (default 1)
    pushq %rbp
    movq %rsp, %rbp

    subq $48, %rsp

	movq %rdx, -40(%rbp)
	movq %rcx, -48(%rbp)

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

	# set alignment
	movq $0, %rdx
	subq -40(%rbp), %rax
	movq -48(%rbp), %rsi
	divq %rsi
	addq %rdx, -24(%rbp)

    # seek back to start
	movq -16(%rbp), %rdi
	movq $0, %rsi
	movq $SEEK_SET, %rdx
	call fseek
	testq %rax, %rax
	jnz fseek_failed

    # allocate memory and store pointer
	# allocate file_size
	movq -24(%rbp), %rdi
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
	movq %rax, (%rdi) # return the bytes_read

    # add the trailing null bytes
	movq -24(%rbp), %rsi
	movq -32(%rbp), %rdi
	subq %rax, %rsi
	loop_null:
		testq %rsi, %rsi
		jz end_loop_null
		movb $0, (%rdi, %rax)
		incq %rax
		decq %rsi
		jmp loop_null

	end_loop_null:

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
