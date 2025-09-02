.include "const.s"

.section .data

.type data_length_error_message, @object
data_length_error_message:
    .ascii "invalid data length: got $%04x, expected $%04x\n\0"

.type load_address_error_message, @object
load_address_error_message:
    .ascii "invalid load address: got $%04x, expected $%04x\n\0"

.type get_cbm_value_at_xy_error_message, @object
get_cbm_value_at_xy_error_message:
    .ascii "fatal error when attempting to get CBM colour value at X=%d, Y=%d\n\0"

.section .text

# Hires *load_hpi(Byte *data, uint64_t data_size, HiresConfig *image_config);
.globl load_hpi
.type load_hpi, @function

# Byte *data
.equ LOCAL_DATA_PTR, -8
# uint64_t data_size
.equ LOCAL_DATA_SIZE, -16
# HiresConfig *image_config
.equ LOCAL_IMAGE_CONFIG_PTR, -24
# uint64_t bitmap_offset
.equ LOCAL_BITMAP_OFFSET, -32
# uint64_t screen_offset
.equ LOCAL_SCREEN_OFFSET, -40

# %rdi - Byte *data
# %rsi - uint64_t data_size
# %rdx - HiresConfig *image_config
load_hpi:

    # Reserve space for 5 variables (aligned to 16 bytes):
    enter $0x30, $0
    # %rdi - Byte *data
    movq %rdi, LOCAL_DATA_PTR(%rbp)
    # %rsi - uint64_t data_size
    movq %rsi, LOCAL_DATA_SIZE(%rbp)
    # %rdx - HiresConfig *image_config
    movq %rdx, LOCAL_IMAGE_CONFIG_PTR(%rbp)

    # Assert data_size == image_config->data_length:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - HiresConfig *image_config
    movq $HIRES_CONFIG_DATA_LENGTH_OFFSET, %rsi
    # %rsi - uint64_t data_length_offset
    call get_hires_config_value
    # %ax - uint64_t image_config->data_length
    cmpw %ax, LOCAL_DATA_SIZE(%rbp)
    jz __load_hpi_1

    leaq data_length_error_message(%rip), %rsi
    movzwq LOCAL_DATA_SIZE(%rbp), %rdx
    movzwq %ax, %rcx
    jmp throw_runtime_error

__load_hpi_1:

    # Assert *(uint16_t)data == image_config->load_address:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - HiresConfig *image_config
    movq $HIRES_CONFIG_LOAD_ADDRESS_OFFSET, %rsi
    # %rsi - uint64_t load_address_offset
    call get_hires_config_value
    # %ax - uint16_t image_config->load_address
    movq LOCAL_DATA_PTR(%rbp), %rdi
    cmpw %ax, (%rdi)
    jz __load_hpi_2

    leaq load_address_error_message(%rip), %rsi
    movzwq (%rdi), %rdx
    movzwq %ax, %rcx
    jmp throw_runtime_error

__load_hpi_2:

    # Get image_config->bitmap_offset value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - HiresConfig *image_config
    movq $HIRES_CONFIG_BITMAP_DATA_OFFSET, %rsi
    # %rsi - uint64_t bitmap_data_offset
    call get_hires_config_value
    # %rax - uint64_t image_config->bitmap_offset
    movq %rax, LOCAL_BITMAP_OFFSET(%rbp)

    # Get image_config->screen_offset value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - HiresConfig *image_config
    movq $HIRES_CONFIG_SCREEN_DATA_OFFSET, %rsi
    # %rsi - uint64_t screen_data_offset
    call get_hires_config_value
    # %rax - uint64_t image_config->screen_offset
    movq %rax, LOCAL_SCREEN_OFFSET(%rbp)

    # Allocate and initialise Hires object instance:
    movq LOCAL_DATA_PTR(%rbp), %rax
    # %rax - Byte *data
    movq %rax, %rdi
    addq LOCAL_BITMAP_OFFSET(%rbp), %rdi
    # %rdi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq %rax, %rsi
    addq LOCAL_SCREEN_OFFSET(%rbp), %rsi
    # %rsi - Byte screen_data[$SCREEN_DATA_LENGTH]
    call new_hpi
    # %rax - Hires *hires

    leave
    ret

# uint64_t get_hires_config_value(HiresConfig *image_config, uint64_t offset);
.type get_hires_config_value, @function

# %rdi - HiresConfig *image_config
# %rsi - uint64_t offset
get_hires_config_value:

    movzwq (%rdi, %rsi), %rax
    # %rax - uint64_t config_value = *(static_cast<uint16_t *>(static_cast<uint8_t *>(image_config) + offset))

    ret

# Hires *new_hpi(Byte *bitmap_data, Byte *screen_data, Byte *colours_data, Byte background_colour);
.globl new_hpi
.type new_hpi, @function

# Byte bitmap_data[$BITMAP_DATA_LENGTH]
.equ LOCAL_BITMAP_DATA_PTR, -8
# Byte screen_data[$SCREEN_DATA_SIZE]
.equ LOCAL_SCREEN_DATA_PTR, -16
# Hires *hires
.equ LOCAL_HIRES_PTR, -24

# %rdi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
# %rsi - Byte screen_data[$SCREEN_DATA_SIZE]
new_hpi:

    # Reserve space for 5 variables (aligned to 16 bytes):
    enter $0x30, $0
    # %rdi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq %rdi, LOCAL_BITMAP_DATA_PTR(%rbp)
    # %rsi - Byte screen_data[$SCREEN_DATA_SIZE]
    movq %rsi, LOCAL_SCREEN_DATA_PTR(%rbp)

    # Allocate memory to store the new Hires object:
    movq $HIRES_TOTAL_SIZE, %rdi
    call malloc@plt
    # %rax - Hires *hires
    movq %rax, LOCAL_HIRES_PTR(%rbp)

    # Allocate and initialise the member variable - BaseImage *hires->base_image
    movq LOCAL_BITMAP_DATA_PTR(%rbp), %rdi
    # %rdi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq LOCAL_SCREEN_DATA_PTR(%rbp), %rsi
    # %rsi - Byte screen_data[$SCREEN_DATA_SIZE]
    call new_base_image
    # %rax - BaseImage *base_image
    movq LOCAL_HIRES_PTR(%rbp), %rdi
    # %rdi - Hires *hires
    movq %rax, HIRES_BASE_IMAGE_PTR_OFFSET(%rdi)

    movq LOCAL_HIRES_PTR(%rbp), %rax
    # %rax - Hires *hires

    leave
    ret

# void delete_hpi(Hires *hires);
.globl delete_hpi
.type delete_hpi, @function

# Hires *hires
.equ LOCAL_HIRES_PTR, -8

# %rdi - Hires *hires
delete_hpi:

    # Reserve space for 1 variable (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - Hires *hires
    movq %rdi, LOCAL_HIRES_PTR(%rbp)
    # Do not deallocate a null pointer:
    cmpq $0, %rdi
    jz __delete_hpi_1

    # Deallocate the member variable - BaseImage *base_image
    movq LOCAL_HIRES_PTR(%rbp), %rax
    # %rax - Hires *hires
    movq HIRES_BASE_IMAGE_PTR_OFFSET(%rax), %rdi
    # %rdi - BaseImage *hires->base_image
    call delete_base_image

    # Deallocate the Hires object:
    movq LOCAL_HIRES_PTR(%rbp), %rdi
    # %rdi - Hires *hires
    movq $HIRES_TOTAL_SIZE, %rsi
    # %rsi - uint64_t length
    call free_with_zero_fill

__delete_hpi_1:

    leave
    ret

# BaseImage *hpi_get_base_image(Hires *hires);
.type hpi_get_base_image, @function

# %rdi - Hires *hires
hpi_get_base_image:

    # %rdi - Hires *hires
    movq HIRES_BASE_IMAGE_PTR_OFFSET(%rdi), %rax
    # %rax - BaseImage *base_image

    ret

# Bitmap *hpi_get_bitmap(Hires *hires);
.globl hpi_get_bitmap
.type hpi_get_bitmap, @function

# %rdi - Hires *hires
hpi_get_bitmap:

    # %rdi - Hires *hires
    call hpi_get_base_image
    # %rax - BaseImage *base_image
    movq %rax, %rdi
    # %rdi - BaseImage *base_image
    call base_image_get_bitmap
    # %rax - Bitmap *bitmap

    ret

# Screen *hpi_get_screen(Hires *hires);
.globl hpi_get_screen
.type hpi_get_screen, @function

# %rdi - Hires *hires
hpi_get_screen:

    # %rdi - Hires *hires
    call hpi_get_base_image
    # %rax - BaseImage *base_image
    movq %rax, %rdi
    # %rdi - BaseImage *base_image
    call base_image_get_screen
    # %rax - Screen *screen

    ret

# Byte hpi_get_cbm_value_at_xy(Hires *hires, uint16_t x, uint16_t y);
# x = 0..319, y = 0..199
.globl hpi_get_cbm_value_at_xy
.type hpi_get_cbm_value_at_xy, @function

# Hires *hires
.equ LOCAL_HIRES_PTR, -8
# uint16_t x
.equ LOCAL_X, -10
# uint16_t y
.equ LOCAL_Y, -12
# uint8_t bits
.equ LOCAL_BITS, -13
# Byte value
.equ LOCAL_VALUE, -14

# %rdi - Hires *hires
# %si - uint16_t x
# %dx - uint16_t y
hpi_get_cbm_value_at_xy:

    # Reserve space for 5 variables (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - Hires *hires
    movq %rdi, LOCAL_HIRES_PTR(%rbp)
    # %si - uint16_t x
    movw %si, LOCAL_X(%rbp)
    # %dx - uint16_t y
    movw %dx, LOCAL_Y(%rbp)

    # Get bitmap bit at the hires coordinate X/Y:
    movq LOCAL_HIRES_PTR(%rbp), %rdi
    # %rdi - Hires *hires
    call hpi_get_bitmap
    # %rax - Bitmap *bitmap
    movq %rax, %rdi
    # %rdi - Bitmap *bitmap
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t hires_x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call bmp_get_hpi_bit_at_xy
    # %al - uint8_t bit
    movb %al, LOCAL_BITS(%rbp)

    # bit = "0": Colour from bits 0-3 of screen memory
    cmpb $0, LOCAL_BITS(%rbp)
    jne __hpi_get_cbm_value_at_xy_1

    # Get screen value at the hires coordinate X/Y:
    movq LOCAL_HIRES_PTR(%rbp), %rdi
    # %rdi - Hires *hires
    call hpi_get_screen
    # %rax - Screen *screen
    movq %rax, %rdi
    # %rdi - Screen *screen
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t hires_x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call scr_get_value_at_pixel_xy
    # %al - uint8_t value

    andb $0x0f, %al
    movb %al, LOCAL_VALUE(%rbp)

    jmp __hpi_get_cbm_value_at_xy_3

__hpi_get_cbm_value_at_xy_1:

    # bit = "1": Colour from bits 4-7 of screen memory
    cmpb $1, LOCAL_BITS(%rbp)
    jne __hpi_get_cbm_value_at_xy_2

    # Get screen value at the hires coordinate X/Y:
    movq LOCAL_HIRES_PTR(%rbp), %rdi
    # %rdi - Hires *hires
    call hpi_get_screen
    # %rax - Screen *screen
    movq %rax, %rdi
    # %rdi - Screen *screen
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t hires_x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call scr_get_value_at_pixel_xy
    # %al - uint8_t value

    andb $0xf0, %al
    shrb $4, %al
    movb %al, LOCAL_VALUE(%rbp)

    jmp __hpi_get_cbm_value_at_xy_3

__hpi_get_cbm_value_at_xy_2:

    leaq get_cbm_value_at_xy_error_message(%rip), %rsi
    movzwq LOCAL_X(%rbp), %rdx
    movzwq LOCAL_Y(%rbp), %rcx
    jmp throw_runtime_error

__hpi_get_cbm_value_at_xy_3:

    movb LOCAL_VALUE(%rbp), %al
    # %al - Byte value

    leave
    ret

# Byte __hpi_get_cbm_value_at_xy(Hires *hires, uint16_t x, uint16_t y);
# x = 0..319, y = 0..199
.type __hpi_get_cbm_value_at_xy, @function

# %rdi - Hires *hires
# %si - uint16_t x
# %dx - uint16_t y
__hpi_get_cbm_value_at_xy:

    jmp hpi_get_cbm_value_at_xy

# Byte __hpi_get_original_rgb_value_at_xy(Hires *hires, uint16_t x, uint16_t y);
# x = 0..319, y = 0..199
.type __hpi_get_original_rgb_value_at_xy, @function

# %rdi - Hires *hires
# %si - uint16_t x
# %dx - uint16_t y
__hpi_get_original_rgb_value_at_xy:

    movq $0, %rax
    # %rax - png_bytep original_rgb_value = nullptr

    ret

# PixelMap *hpi_get_pixels(Hires *hires, enum colour_palette palette);
.globl hpi_get_pixels
.type hpi_get_pixels, @function

# Hires *hires
.equ LOCAL_HIRES_PTR, -8
# enum colour_palette palette
.equ LOCAL_COLOUR_PALETTE, -9

# %rdi - Hires *hires
# %sil - enum colour_palette palette
hpi_get_pixels:

    # Reserve space for 1 variable (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - Hires *hires
    movq %rdi, LOCAL_HIRES_PTR(%rbp)
    # %sil - enum colour_palette palette
    movb %sil, LOCAL_COLOUR_PALETTE(%rbp)

    # PixelMap *pixel_map = new_pixel_map(
    #   uint16_t width,
    #   uint16_t height
    #   Hires *hires,
    #   Byte (*get_cbm_value)(Hires *hires, uint16_t x, uint16_t y),
    #   enum colour_palette palette,
    #   png_bytep (*get_original_rgb_value)(Hires *hires, uint16_t x, uint16_t y),
    # );

    movw $BITMAP_WIDTH, %di
    # %di - uint16_t width
    movw $BITMAP_HEIGHT, %si
    # %si - uint16_t height
    movq LOCAL_HIRES_PTR(%rbp), %rdx
    # %rdx - Hires *hires
    leaq __hpi_get_cbm_value_at_xy(%rip), %rcx
    # %rcx - Byte (*get_cbm_value)(Hires *hires, uint16_t x, uint16_t y)
    movb LOCAL_COLOUR_PALETTE(%rbp), %r8b
    # %r8b - enum colour_palette palette
    leaq __hpi_get_original_rgb_value_at_xy(%rip), %r9
    # %r9 - png_bytep (*get_original_rgb_value)(Hires *hires, uint16_t x, uint16_t y)
    call new_pixel_map
    # %rax - PixelMap pixel_map

    leave
    ret

# Byte *export_hpi(Hires *hires, HiresConfig *image_config);
.globl export_hpi
.type export_hpi, @function

# Hires *hires
.equ LOCAL_HIRES_PTR, -8
# HiresConfig *image_config
.equ LOCAL_IMAGE_CONFIG_PTR, -16
# uint64_t data_length
.equ LOCAL_DATA_LENGTH, -24
# Byte *data
.equ LOCAL_DATA_PTR, -32
# uint64_t bitmap_offset
.equ LOCAL_BITMAP_OFFSET, -40
# uint64_t screen_offset
.equ LOCAL_SCREEN_OFFSET, -48
# uint16_t load_address
.equ LOCAL_LOAD_ADDRESS, -50

# %rdi - Hires *hires
# %rsi - HiresConfig *image_config
export_hpi:

    # Reserve space for 7 variables (aligned to 16 bytes):
    enter $0x40, $0
    # %rdi - Hires *hires
    movq %rdi, LOCAL_HIRES_PTR(%rbp)
    # %rsi - HiresConfig *image_config
    movq %rsi, LOCAL_IMAGE_CONFIG_PTR(%rbp)

    # Get base image configuration:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - HiresConfig *image_config
    movq $HIRES_CONFIG_DATA_LENGTH_OFFSET, %rsi
    # %rsi - uint64_t data_length_offset
    call get_hires_config_value
    # %ax - uint64_t image_config->data_length
    movq %rax, LOCAL_DATA_LENGTH(%rbp)
    movq $HIRES_CONFIG_LOAD_ADDRESS_OFFSET, %rsi
    # %rsi - uint64_t load_address_offset
    call get_hires_config_value
    # %ax - uint16_t image_config->load_address
    movw %ax, LOCAL_LOAD_ADDRESS(%rbp)
    movq $HIRES_CONFIG_BITMAP_DATA_OFFSET, %rsi
    # %rsi - uint64_t bitmap_data_offset
    call get_hires_config_value
    # %rax - uint64_t image_config->bitmap_offset
    movq %rax, LOCAL_BITMAP_OFFSET(%rbp)
    movq $HIRES_CONFIG_SCREEN_DATA_OFFSET, %rsi
    # %rsi - uint64_t screen_data_offset
    call get_hires_config_value
    # %rax - uint64_t image_config->screen_offset
    movq %rax, LOCAL_SCREEN_OFFSET(%rbp)

    # Allocate memory to store the exported Hires data and initialise base image data:
    movq LOCAL_HIRES_PTR(%rbp), %rdi
    # %rdi - Hires *hires
    call hpi_get_base_image
    # %rax - BaseImage *base_image
    movq %rax, %rdi
    # %rdi - BaseImage *base_image
    movq LOCAL_DATA_LENGTH(%rbp), %rsi
    # %rsi - uint64_t data_length
    movw LOCAL_LOAD_ADDRESS(%rbp), %dx
    # %dx - uint16_t load_address
    movq LOCAL_BITMAP_OFFSET(%rbp), %rcx
    # %rcx - uint64_t bitmap_offset
    movq LOCAL_SCREEN_OFFSET(%rbp), %r8
    # %r8 - uint64_t screen_offset
    call export_base
    # %rax - Byte *data
    movq %rax, LOCAL_DATA_PTR(%rbp)

    movq LOCAL_DATA_PTR(%rbp), %rax
    # %rax - Byte *data

    leave
    ret
