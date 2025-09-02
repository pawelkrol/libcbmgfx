.include "const.s"

.section .data

.size size_of_bitmap_row_data, 2
.type size_of_bitmap_row_data, @object
size_of_bitmap_row_data:
    .2byte SIZE_OF_BITMAP_ROW_DATA

.size size_of_bitmap_char_data, 2
.type size_of_bitmap_char_data, @object
size_of_bitmap_char_data:
    .2byte SIZE_OF_BITMAP_CHAR_DATA

.size bit_masks_x, 4
.type bit_masks_x, @object
bit_masks_x:
    .byte 0b11000000
    .byte 0b00110000
    .byte 0b00001100
    .byte 0b00000011

.section .text

# Bitmap *new_bitmap(Byte data[$BITMAP_DATA_LENGTH]);
.globl new_bitmap
.type new_bitmap, @function

# Byte data[$BITMAP_DATA_LENGTH]
.equ LOCAL_DATA_PTR, -8
# Byte *bytes
.equ LOCAL_BYTES_PTR, -16
# Bitmap *bitmap
.equ LOCAL_BITMAP_PTR, -24

# %rdi - Byte data[$BITMAP_DATA_LENGTH]
new_bitmap:

    # Reserve space for 3 variables (aligned to 16 bytes):
    enter $0x20, $0
    # %rdi - Byte data[$BITMAP_DATA_LENGTH]
    movq %rdi, LOCAL_DATA_PTR(%rbp)

    movq $BITMAP_DATA_LENGTH, %rdi
    # %rdi - uint64_t data_length
    # Allocate memory to store the bytes:
    call malloc@plt
    # %rax - Byte *bytes
    movq %rax, LOCAL_BYTES_PTR(%rbp)

    # Allocate memory to store the new Bitmap object:
    movq $BITMAP_TOTAL_SIZE, %rdi
    call malloc@plt
    movq %rax, LOCAL_BITMAP_PTR(%rbp)

    movq LOCAL_BITMAP_PTR(%rbp), %rdi
    # %rdi - Bitmap *bitmap

    # Initialise bitmap->data with bytes pointer:
    movq LOCAL_BYTES_PTR(%rbp), %rax
    movq %rax, BITMAP_DATA_OFFSET(%rdi)

    # Copy $BITMAP_DATA_LENGTH of bytes to bitmap->data:
    movq LOCAL_BYTES_PTR(%rbp), %rdi
    movq LOCAL_DATA_PTR(%rbp), %rsi
    movq $BITMAP_DATA_LENGTH, %rcx
    cld
    rep movsb

    movq LOCAL_BITMAP_PTR(%rbp), %rax
    # %rax - Bitmap *bitmap

    leave
    ret

# void delete_bitmap(Bitmap *bitmap);
.globl delete_bitmap
.type delete_bitmap, @function

# Bitmap *bitmap
.equ LOCAL_BITMAP_PTR, -8
# Byte *bytes
.equ LOCAL_BYTES_PTR, -24

# %rdi - Bitmap *bitmap
delete_bitmap:

    # Reserve space for 3 variables (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - Bitmap *bitmap
    movq %rdi, LOCAL_BITMAP_PTR(%rbp)
    # Do not deallocate a null pointer:
    cmpq $0, %rdi
    jz __delete_bitmap_1

    # Byte *bytes = bitmap->data
    movq BITMAP_DATA_OFFSET(%rdi), %rax
    movq %rax, LOCAL_BYTES_PTR(%rbp)

    # Deallocate an array holding all data bytes:
    movq LOCAL_BYTES_PTR(%rbp), %rdi
    # %rdi - Byte *bytes
    movq $BITMAP_DATA_LENGTH, %rsi
    # %rsi - uint64_t data_length
    call free_with_zero_fill

    # Deallocate the Bitmap object:
    movq LOCAL_BITMAP_PTR(%rbp), %rdi
    # %rdi - Bitmap *bitmap
    movq $BITMAP_TOTAL_SIZE, %rsi
    # %rsi - uint64_t length
    call free_with_zero_fill

__delete_bitmap_1:

    leave
    ret

# void bmp_copy_data(Bitmap *bitmap, Byte *target_data);
.globl bmp_copy_data
.type bmp_copy_data, @function

# %rdi - Bitmap *bitmap
# %rsi - Byte *target_data
bmp_copy_data:

    # %rdi - Bitmap *bitmap
    # %rsi - Byte *target_data
    call bmp_get_data
    # %rax - Byte *source_data

    # Copy $BITMAP_DATA_LENGTH of bytes to target_data:
    movq %rsi, %rdi
    # %rdi - Byte *target_data
    movq %rax, %rsi
    # %rsi - Byte *source_data
    movq $BITMAP_DATA_LENGTH, %rcx
    # %rcx - uint64_t data_length
    cld
    rep movsb

    ret

# Byte *bmp_get_data(Bitmap *bitmap);
.globl bmp_get_data
.type bmp_get_data, @function

# %rdi - Bitmap *bitmap
bmp_get_data:

    # %rdi - Bitmap *bitmap
    movq BITMAP_DATA_OFFSET(%rdi), %rax
    # %rax - Byte *data

    ret

# Byte bmp_get_value_at_offset(Bitmap *bitmap, uint64_t offset);
.globl bmp_get_value_at_offset
.type bmp_get_value_at_offset, @function

# %rdi - Bitmap *bitmap
# %rsi - uint64_t offset
bmp_get_value_at_offset:

    # %rdi - Bitmap *bitmap
    call bmp_get_data
    # %rax - Byte *data
    movq %rax, %rdi
    movb (%rdi, %rsi, 1), %al
    # %al - Byte value

    ret

# Byte bmp_get_value_at_xy(Bitmap *bitmap, uint16_t x, uint16_t y);
.type bmp_get_value_at_xy, @function

# Bitmap *bitmap
.equ LOCAL_BITMAP_PTR, -8
# uint64_t offset
.equ LOCAL_OFFSET, -16
# uint16_t x
.equ LOCAL_X, -18
# uint16_t y
.equ LOCAL_Y, -20

# %rdi - Bitmap *bitmap
# %si - uint16_t x
# %dx - uint16_t y
bmp_get_value_at_xy:

    # Reserve space for 4 variables (aligned to 16 bytes):
    enter $0x20, $0
    # %rdi - Bitmap *bitmap
    movq %rdi, LOCAL_BITMAP_PTR(%rbp)
    # %si - uint16_t x
    movw %si, LOCAL_X(%rbp)
    # %dx - uint16_t y
    movw %dx, LOCAL_Y(%rbp)

    # Compute data offset for the hires coordinate X/Y:
    movq LOCAL_BITMAP_PTR(%rbp), %rdi
    # %rdi - Bitmap *bitmap
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call bmp_get_xy_offset
    # %rax - uint64_t offset
    movq %rax, LOCAL_OFFSET(%rbp)

    # Fetch bitmap byte value at the computed offset:
    movq LOCAL_BITMAP_PTR(%rbp), %rdi
    # %rdi - Bitmap *bitmap
    movq LOCAL_OFFSET(%rbp), %rsi
    # %rsi - uint64_t offset
    call bmp_get_value_at_offset
    # %al - Byte value

    leave
    ret

# Byte bmp_get_hpi_bit_at_xy(Bitmap *bitmap, uint16_t x, uint16_t y);
.globl bmp_get_hpi_bit_at_xy
.type bmp_get_hpi_bit_at_xy, @function

# Bitmap *bitmap
.equ LOCAL_BITMAP_PTR, -8
# uint16_t x
.equ LOCAL_X, -10
# uint16_t y
.equ LOCAL_Y, -12
# Byte value
.equ LOCAL_VALUE, -13
# Byte bit_mask
.equ LOCAL_BIT_MASK, -14
# Byte masked_value
.equ LOCAL_MASKED_VALUE, -15

# %rdi - Bitmap *bitmap
# %si - uint16_t x
# %dx - uint16_t y
bmp_get_hpi_bit_at_xy:

    # Reserve space for 6 variables (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - Bitmap *bitmap
    movq %rdi, LOCAL_BITMAP_PTR(%rbp)
    # %si - uint16_t x
    movw %si, LOCAL_X(%rbp)
    # %dx - uint16_t y
    movw %dx, LOCAL_Y(%rbp)

    # Fetch bitmap byte value at the hires coordinate X/Y:
    movq LOCAL_BITMAP_PTR(%rbp), %rdi
    # %rdi - Bitmap *bitmap
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call bmp_get_value_at_xy
    # %al - Byte value
    movb %al, LOCAL_VALUE(%rbp)

    # Compute bit mask for the hires coordinate X:
    movw LOCAL_X(%rbp), %cx
    # %cx - uint16_t x
    andw $0x0007, %cx
    # %cx - uint16_t x = x & $0007
    movb $0x80, %al
    # %al - uint8_t bit_mask = 0b10000000
    shrb %cl, %al
    # %al - Byte bit_mask
    movb %al, LOCAL_BIT_MASK(%rbp)

    # Mask byte value for the hires coordinate X/Y:
    movb LOCAL_VALUE(%rbp), %al
    andb LOCAL_BIT_MASK(%rbp), %al
    # %al - Byte masked_value
    movb %al, LOCAL_MASKED_VALUE(%rbp)

    # Compute bit shift count for the hires coordinate X:
    movw LOCAL_X(%rbp), %cx
    # %cx - uint16_t x = ~x & $0007
    notw %cx
    andw $0x0007, %cx
    # %cx - bit shift count

    # Shift masked byte value for the hires coordinate X/Y:
    movb LOCAL_MASKED_VALUE(%rbp), %al
    shrb %cl, %al
    # %al - uint8_t hpi_bit

    leave
    ret

# Byte bmp_get_mcp_bits_at_xy(Bitmap *bitmap, uint16_t x, uint16_t y);
.globl bmp_get_mcp_bits_at_xy
.type bmp_get_mcp_bits_at_xy, @function

# Bitmap *bitmap
.equ LOCAL_BITMAP_PTR, -8
# uint16_t x
.equ LOCAL_X, -10
# uint16_t y
.equ LOCAL_Y, -12
# Byte value
.equ LOCAL_VALUE, -13
# Byte bit_mask
.equ LOCAL_BIT_MASK, -14
# Byte masked_value
.equ LOCAL_MASKED_VALUE, -15

# %rdi - Bitmap *bitmap
# %si - uint16_t x
# %dx - uint16_t y
bmp_get_mcp_bits_at_xy:

    # Reserve space for 6 variables (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - Bitmap *bitmap
    movq %rdi, LOCAL_BITMAP_PTR(%rbp)
    # %si - uint16_t x
    movw %si, LOCAL_X(%rbp)
    # %dx - uint16_t y
    movw %dx, LOCAL_Y(%rbp)

    # Fetch bitmap byte value at the hires coordinate X/Y:
    movq LOCAL_BITMAP_PTR(%rbp), %rdi
    # %rdi - Bitmap *bitmap
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call bmp_get_value_at_xy
    # %al - Byte value
    movb %al, LOCAL_VALUE(%rbp)

    # Compute bit mask for the hires coordinate X:
    movzwq LOCAL_X(%rbp), %rcx
    # %rcx - uint64_t x
    shrq $1, %rcx
    andq $3, %rcx
    leaq bit_masks_x(%rip), %rsi
    movb (%rsi, %rcx, 1), %al
    # %al - Byte bit_mask
    movb %al, LOCAL_BIT_MASK(%rbp)

    # Mask byte value for the hires coordinate X/Y:
    movb LOCAL_VALUE(%rbp), %al
    andb LOCAL_BIT_MASK(%rbp), %al
    # %al - Byte masked_value
    movb %al, LOCAL_MASKED_VALUE(%rbp)

    # Compute bit shift count for the hires coordinate X:
    movw LOCAL_X(%rbp), %cx
    # %cx - uint16_t x
    shrw $1, %cx
    andw $3, %cx
    notw %cx
    andw $3, %cx
    shlw $1, %cx
    # %cx - bit shift count

    # Shift masked byte value for the hires coordinate X/Y:
    movb LOCAL_MASKED_VALUE(%rbp), %al
    shrb %cl, %al
    # %al - uint8_t mcp_bits

    leave
    ret

# Byte bmp_get_xy_offset(Bitmap *bitmap, uint16_t x, uint16_t y);
.type bmp_get_xy_offset, @function

# Bitmap *bitmap
.equ LOCAL_BITMAP_PTR, -8
# uint16_t x
.equ LOCAL_X, -10
# uint16_t y
.equ LOCAL_Y, -12
# uint16_t offset
.equ LOCAL_OFFSET, -14

# %rdi - Bitmap *bitmap
# %si - uint16_t x
# %dx - uint16_t y
bmp_get_xy_offset:

    # Reserve space for 4 variables (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - Bitmap *bitmap
    movq %rdi, LOCAL_BITMAP_PTR(%rbp)
    # %si - uint16_t x
    movw %si, LOCAL_X(%rbp)
    # %dx - uint16_t y
    movw %dx, LOCAL_Y(%rbp)

    movw $0, LOCAL_OFFSET(%rbp)
    # uint16_t offset = 0

    # uint16_t offset = ((y & 0xfff8) >> 3) * 0x0140 + (y & 0x0007) + ((x & fff8) >> 3) * 0x0008

    movw LOCAL_Y(%rbp), %ax
    andw $0xfff8, %ax
    shrw $3, %ax
    mulw size_of_bitmap_row_data(%rip)
    addw %ax, LOCAL_OFFSET(%rbp)

    movw LOCAL_Y(%rbp), %ax
    andw $0x0007, %ax
    addw %ax, LOCAL_OFFSET(%rbp)

    movw LOCAL_X(%rbp), %ax
    andw $0xfff8, %ax
    shrw $3, %ax
    mulw size_of_bitmap_char_data(%rip)
    addw %ax, LOCAL_OFFSET(%rbp)

    movzwq LOCAL_OFFSET(%rbp), %rax
    # %rax - uint64_t offset

    leave
    ret
