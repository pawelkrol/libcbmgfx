.include "const.s"

.section .data

.size size_of_screen_row_data, 2
.type size_of_screen_row_data, @object
size_of_screen_row_data:
    .2byte SIZE_OF_SCREEN_ROW_DATA

.section .text

# Screen *new_screen(Byte data[$SCREEN_DATA_LENGTH]);
.globl new_screen
.type new_screen, @function

# Byte data[$SCREEN_DATA_LENGTH]
.equ LOCAL_DATA_PTR, -8
# Byte *bytes
.equ LOCAL_BYTES_PTR, -16
# Screen *screen
.equ LOCAL_SCREEN_PTR, -24

# %rdi - Byte data[$SCREEN_DATA_LENGTH]
new_screen:

    # Reserve space for 3 variables (aligned to 16 bytes):
    enter $0x20, $0
    # %rdi - Byte data[$SCREEN_DATA_LENGTH]
    movq %rdi, LOCAL_DATA_PTR(%rbp)

    movq $SCREEN_DATA_LENGTH, %rdi
    # %rdi - uint64_t length
    # Allocate memory to store the bytes:
    call malloc@plt
    # %rax - Byte *bytes
    movq %rax, LOCAL_BYTES_PTR(%rbp)

    # Allocate memory to store the new Screen object:
    movq $SCREEN_TOTAL_SIZE, %rdi
    call malloc@plt
    movq %rax, LOCAL_SCREEN_PTR(%rbp)

    movq LOCAL_SCREEN_PTR(%rbp), %rdi
    # %rdi - Screen *screen

    # Initialise screen->data with bytes pointer:
    movq LOCAL_BYTES_PTR(%rbp), %rax
    movq %rax, SCREEN_DATA_OFFSET(%rdi)

    # Copy $SCREEN_DATA_LENGTH of bytes to screen->data:
    movq LOCAL_BYTES_PTR(%rbp), %rdi
    movq LOCAL_DATA_PTR(%rbp), %rsi
    movq $SCREEN_DATA_LENGTH, %rcx
    cld
    rep movsb

    movq LOCAL_SCREEN_PTR(%rbp), %rax
    # %rax - Screen *screen

    leave
    ret

# void delete_screen(Screen *screen);
.globl delete_screen
.type delete_screen, @function

# Screen *screen
.equ LOCAL_SCREEN_PTR, -8
# Byte *bytes
.equ LOCAL_BYTES_PTR, -24

# %rdi - Screen *screen
delete_screen:

    # Reserve space for 3 variables (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - Screen *screen
    movq %rdi, LOCAL_SCREEN_PTR(%rbp)
    # Do not deallocate a null pointer:
    cmpq $0, %rdi
    jz __delete_screen_1

    # Byte *bytes = screen->data
    movq SCREEN_DATA_OFFSET(%rdi), %rax
    movq %rax, LOCAL_BYTES_PTR(%rbp)

    # Deallocate an array holding all data bytes:
    movq LOCAL_BYTES_PTR(%rbp), %rdi
    # %rdi - Byte *bytes
    movq $SCREEN_DATA_LENGTH, %rsi
    # %rsi - uint64_t length
    call free_with_zero_fill

    # Deallocate the Screen object:
    movq LOCAL_SCREEN_PTR(%rbp), %rdi
    # %rdi - Screen *screen
    movq $SCREEN_TOTAL_SIZE, %rsi
    # %rsi - uint64_t length
    call free_with_zero_fill

__delete_screen_1:

    leave
    ret

# void scr_copy_data(Screen *screen, Byte *target_data);
.globl scr_copy_data
.type scr_copy_data, @function

# %rdi - Screen *screen
# %rsi - Byte *target_data
scr_copy_data:

    # %rdi - Screen *screen
    # %rsi - Byte *target_data
    call scr_get_data
    # %rax - Byte *source_data

    # Copy $SCREEN_DATA_LENGTH of bytes to target_data:
    movq %rsi, %rdi
    # %rdi - Byte *target_data
    movq %rax, %rsi
    # %rsi - Byte *source_data
    movq $SCREEN_DATA_LENGTH, %rcx
    # %rcx - uint64_t data_length
    cld
    rep movsb

    ret

# Byte *scr_get_data(Screen *screen);
.globl scr_get_data
.type scr_get_data, @function

# %rdi - Screen *screen
scr_get_data:

    # %rdi - Screen *screen
    movq SCREEN_DATA_OFFSET(%rdi), %rax
    # %rax - Byte *data

    ret

# Byte scr_get_value_at(Screen *screen, uint64_t offset);
.globl scr_get_value_at
.type scr_get_value_at, @function

# %rdi - Screen *screen
# %rsi - uint64_t offset
scr_get_value_at:

    # %rdi - Screen *screen
    call scr_get_data
    # %rax - Byte *data
    movq %rax, %rdi
    movb (%rdi, %rsi, 1), %al
    # %al - Byte value

    ret

# Byte scr_get_value_at_pixel_xy(Screen *screen, uint16_t x, uint16_t y);
.globl scr_get_value_at_pixel_xy
.type scr_get_value_at_pixel_xy, @function

# Screen *screen
.equ LOCAL_SCREEN_PTR, -8
# uint64_t offset
.equ LOCAL_OFFSET, -16
# uint16_t x
.equ LOCAL_X, -18
# uint16_t y
.equ LOCAL_Y, -20

# %rdi - Screen *screen
# %si - uint16_t x
# %dx - uint16_t y
scr_get_value_at_pixel_xy:

    # Reserve space for 4 variables (aligned to 16 bytes):
    enter $0x20, $0
    # %rdi - Screen *screen
    movq %rdi, LOCAL_SCREEN_PTR(%rbp)
    # %si - uint16_t x
    movw %si, LOCAL_X(%rbp)
    # %dx - uint16_t y
    movw %dx, LOCAL_Y(%rbp)

    # Compute data offset for the hires coordinate X/Y:

    movq $0, LOCAL_OFFSET(%rbp)
    # uint16_t offset = 0

    # uint16_t offset = (y / 8) * 40 + (x / 8)

    movw LOCAL_Y(%rbp), %ax
    shrw $3, %ax
    mulw size_of_screen_row_data(%rip)
    addw %ax, LOCAL_OFFSET(%rbp)

    movw LOCAL_X(%rbp), %ax
    shrw $3, %ax
    addw %ax, LOCAL_OFFSET(%rbp)

    movq LOCAL_SCREEN_PTR(%rbp), %rdi
    # %rdi - Screen *screen
    movzwq LOCAL_OFFSET(%rbp), %rsi
    # %rsi - uint64_t offset
    call scr_get_value_at
    # %al - Byte value

    leave
    ret
