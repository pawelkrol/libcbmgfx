.include "const.s"

.section .text

# template<typename T>
# void free_with_zero_fill(T *ptr, uint64_t length)
.globl free_with_zero_fill
.type free_with_zero_fill, @function

# T *ptr
.equ LOCAL_PTR, -8
# uint64_t length
.equ LOCAL_LENGTH, -16

# %rdi - T *ptr
# %rsi - uint64_t length (in quadwords)
free_with_zero_fill:

    # Reserve space for 2 variables (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - T *ptr
    movq %rdi, LOCAL_PTR(%rbp)
    # %rsi - uint64_t length
    movq %rsi, LOCAL_LENGTH(%rbp)
    # Do not deallocate a null pointer:
    cmpq $0, %rdi
    jz __free_with_zero_fill_1

    # Fill deallocated memory with zeroes:
    movq LOCAL_PTR(%rbp), %rdi
    movq LOCAL_LENGTH(%rbp), %rcx
    shr $3, %rcx
    movq $0, %rax
    rep stosq

    movq LOCAL_PTR(%rbp), %rdi
    # %rdi - T *ptr
    call free

__free_with_zero_fill_1:

    movq $0, %rax
    leave
    ret

# throw_runtime_error(const char *message, size_t count);
.globl throw_runtime_error
.type throw_runtime_error, @function

# %rdi - const char *message
# %rsi - size_t count
throw_runtime_error:

    # Load "stdout" into %rdi using the GOT:
    movq stdout@GOTPCREL(%rip), %rdi
    movq (%rdi), %rdi
    # %rdi - unsigned int fd (file descriptor)
    movq $0, %rax

    # Call "fprintf" using the PLT:
    call fprintf@plt

    # Exit:
    movq $0x3c, %rax
    # %rax - "exit" (system call number)
    movq $0x01, %rdi
    # %rdi - int error_code
    syscall
