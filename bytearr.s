.include "const.s"

.section .text

# ByteArray *new_byte_array(std::size_t length, Byte *data);
.globl new_byte_array
.type new_byte_array, @function

# std::size_t length
.equ LOCAL_LENGTH, -8
# Byte *data
.equ LOCAL_DATA_PTR, -16
# Byte *bytes
.equ LOCAL_BYTES_PTR, -24
# ByteArray *array
.equ LOCAL_BYTE_ARRAY_PTR, -32

# %rdi - std::size_t length
# %rsi - Byte *data
new_byte_array:

    # Reserve space for 4 variables (aligned to 16 bytes):
    enter $0x20, $0
    # %rdi - std::size_t length
    movq %rdi, LOCAL_LENGTH(%rbp)
    # %rsi - Byte *data
    movq %rsi, LOCAL_DATA_PTR(%rbp)

    # array->data = nullptr
    movq $0, LOCAL_BYTES_PTR(%rbp)

    # Skip empty lists:
    cmpq $0, LOCAL_LENGTH(%rbp)
    jz __new_byte_array_1

    movq LOCAL_LENGTH(%rbp), %rdi
    # %rdi - std::size_t length
    # Allocate memory to store the bytes:
    call malloc@plt
    # %rax - Byte *bytes
    movq %rax, LOCAL_BYTES_PTR(%rbp)

__new_byte_array_1:

    # Allocate memory to store the new ByteArray object:
    movq $BYTE_ARRAY_TOTAL_SIZE, %rdi
    call malloc@plt
    movq %rax, LOCAL_BYTE_ARRAY_PTR(%rbp)

    movq LOCAL_BYTE_ARRAY_PTR(%rbp), %rdi
    # %rdi - ByteArray *array

    # Initialise array->length with length:
    movq LOCAL_LENGTH(%rbp), %rax
    movq %rax, BYTE_ARRAY_LENGTH_OFFSET(%rdi)

    # Initialise array->data with bytes pointer:
    movq LOCAL_BYTES_PTR(%rbp), %rax
    movq %rax, BYTE_ARRAY_DATA_OFFSET(%rdi)

    # Copy length of bytes to array->data:
    movq LOCAL_BYTES_PTR(%rbp), %rdi
    movq LOCAL_DATA_PTR(%rbp), %rsi
    movq LOCAL_LENGTH(%rbp), %rcx
    cld
    rep movsb

    movq LOCAL_BYTE_ARRAY_PTR(%rbp), %rax
    # %rax - ByteArray *array

    leave
    ret

# void delete_byte_array(ByteArray *array);
.globl delete_byte_array
.type delete_byte_array, @function

# ByteArray *array
.equ LOCAL_BYTE_ARRAY_PTR, -8
# std::size_t length
.equ LOCAL_LENGTH, -16
# Byte *bytes
.equ LOCAL_BYTES_PTR, -24

# %rdi - ByteArray *array
delete_byte_array:

    # Reserve space for 3 variables (aligned to 16 bytes):
    enter $0x20, $0
    # %rdi - ByteArray *array
    movq %rdi, LOCAL_BYTE_ARRAY_PTR(%rbp)
    # Do not deallocate a null pointer:
    cmpq $0, %rdi
    jz __delete_byte_array_1

    # std::size_t length = array->length
    movq BYTE_ARRAY_LENGTH_OFFSET(%rdi), %rax
    movq %rax, LOCAL_LENGTH(%rbp)

    # Byte *bytes = array->data
    movq BYTE_ARRAY_DATA_OFFSET(%rdi), %rax
    movq %rax, LOCAL_BYTES_PTR(%rbp)

    # Deallocate an array holding all data bytes:
    movq LOCAL_BYTES_PTR(%rbp), %rdi
    # %rdi - Byte *bytes
    movq LOCAL_LENGTH(%rbp), %rsi
    # %rsi - std::size_t length
    call free_with_zero_fill

    # Deallocate the ByteArray object:
    movq LOCAL_BYTE_ARRAY_PTR(%rbp), %rdi
    # %rdi - ByteArray *array
    movq $BYTE_ARRAY_TOTAL_SIZE, %rsi
    # %rsi - std::size_t length
    call free_with_zero_fill

__delete_byte_array_1:

    leave
    ret

# Byte *byte_array_get_data(ByteArray *array);
.globl byte_array_get_data
.type byte_array_get_data, @function

# %rdi - ByteArray *array
byte_array_get_data:

    # %rdi - ByteArray *array
    movq BYTE_ARRAY_DATA_OFFSET(%rdi), %rax
    # %rax - Byte *data

    ret

# std::size_t byte_array_get_length(ByteArray *array);
.globl byte_array_get_length
.type byte_array_get_length, @function

# %rdi - ByteArray *array
byte_array_get_length:

    # %rdi - ByteArray *array
    movq BYTE_ARRAY_LENGTH_OFFSET(%rdi), %rax
    # %rax - std::size_t length

    ret

# Byte byte_array_get_value_at(ByteArray *array, std::size_t offset);
.globl byte_array_get_value_at
.type byte_array_get_value_at, @function

# %rdi - ByteArray *array
# %rsi - std::size_t offset
byte_array_get_value_at:

    # %rdi - ByteArray *array
    call byte_array_get_data
    # %rax - Byte *data
    movq %rax, %rdi
    # %rdi - Byte *data
    movb (%rdi, %rsi, 1), %al
    # %al - Byte value

    ret
