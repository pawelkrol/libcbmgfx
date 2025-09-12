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

# Multicolour *load_mcp(Byte *data, uint64_t data_size, MulticolourConfig *image_config);
.globl load_mcp
.type load_mcp, @function

# Byte *data
.equ LOCAL_DATA_PTR, -8
# uint64_t data_size
.equ LOCAL_DATA_SIZE, -16
# MulticolourConfig *image_config
.equ LOCAL_IMAGE_CONFIG_PTR, -24
# uint64_t bitmap_offset
.equ LOCAL_BITMAP_OFFSET, -32
# uint64_t screen_offset
.equ LOCAL_SCREEN_OFFSET, -40
# uint64_t colours_offset
.equ LOCAL_COLOURS_OFFSET, -48
# uint64_t background_colour_offset
.equ LOCAL_BACKGROUND_COLOUR_OFFSET, -56
# uint64_t border_colour_offset
.equ LOCAL_BORDER_COLOUR_OFFSET, -64

# %rdi - Byte *data
# %rsi - uint64_t data_size
# %rdx - MulticolourConfig *image_config
load_mcp:

    # Reserve space for 8 variables (aligned to 16 bytes):
    enter $0x40, $0
    # %rdi - Byte *data
    movq %rdi, LOCAL_DATA_PTR(%rbp)
    # %rsi - uint64_t data_size
    movq %rsi, LOCAL_DATA_SIZE(%rbp)
    # %rdx - MulticolourConfig *image_config
    movq %rdx, LOCAL_IMAGE_CONFIG_PTR(%rbp)

    # Assert data_size == image_config->data_length:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - MulticolourConfig *image_config
    movq $MULTICOLOUR_CONFIG_DATA_LENGTH_OFFSET, %rsi
    # %rsi - uint64_t data_length_offset
    call get_multicolour_config_value
    # %ax - uint64_t image_config->data_length
    cmpw %ax, LOCAL_DATA_SIZE(%rbp)
    jz __load_mcp_1

    leaq data_length_error_message(%rip), %rsi
    movzwq LOCAL_DATA_SIZE(%rbp), %rdx
    movzwq %ax, %rcx
    jmp throw_runtime_error

__load_mcp_1:

    # Assert *(uint16_t)data == image_config->load_address:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - MulticolourConfig *image_config
    movq $MULTICOLOUR_CONFIG_LOAD_ADDRESS_OFFSET, %rsi
    # %rsi - uint64_t load_address_offset
    call get_multicolour_config_value
    # %ax - uint16_t image_config->load_address
    movq LOCAL_DATA_PTR(%rbp), %rdi
    cmpw %ax, (%rdi)
    jz __load_mcp_2

    leaq load_address_error_message(%rip), %rsi
    movzwq (%rdi), %rdx
    movzwq %ax, %rcx
    jmp throw_runtime_error

__load_mcp_2:

    # Get image_config->bitmap_offset value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - MulticolourConfig *image_config
    movq $MULTICOLOUR_CONFIG_BITMAP_DATA_OFFSET, %rsi
    # %rsi - uint64_t bitmap_data_offset
    call get_multicolour_config_value
    # %rax - uint64_t image_config->bitmap_offset
    movq %rax, LOCAL_BITMAP_OFFSET(%rbp)

    # Get image_config->screen_offset value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - MulticolourConfig *image_config
    movq $MULTICOLOUR_CONFIG_SCREEN_DATA_OFFSET, %rsi
    # %rsi - uint64_t screen_data_offset
    call get_multicolour_config_value
    # %rax - uint64_t image_config->screen_offset
    movq %rax, LOCAL_SCREEN_OFFSET(%rbp)

    # Get image_config->colours_offset value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - MulticolourConfig *image_config
    movq $MULTICOLOUR_CONFIG_COLOURS_DATA_OFFSET, %rsi
    # %rsi - uint64_t colours_data_offset
    call get_multicolour_config_value
    # %rax - uint64_t image_config->colours_offset
    movq %rax, LOCAL_COLOURS_OFFSET(%rbp)

    # Get image_config->background_colour_offset value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - MulticolourConfig *image_config
    movq $MULTICOLOUR_CONFIG_BACKGROUND_COLOUR_OFFSET, %rsi
    # %rsi - uint64_t background_colour_offset
    call get_multicolour_config_value
    # %rax - uint64_t image_config->background_colour_offset
    movq %rax, LOCAL_BACKGROUND_COLOUR_OFFSET(%rbp)

    # Get image_config->border_colour_offset value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - MulticolourConfig *image_config
    movq $MULTICOLOUR_CONFIG_BORDER_COLOUR_OFFSET, %rsi
    # %rsi - uint64_t border_colour_offset
    call get_multicolour_config_value
    # %rax - uint64_t image_config->border_colour_offset
    movq %rax, LOCAL_BORDER_COLOUR_OFFSET(%rbp)

    # Allocate and initialise Multicolour object instance:
    movq LOCAL_DATA_PTR(%rbp), %rax
    # %rax - Byte *data
    movq %rax, %rdi
    addq LOCAL_BITMAP_OFFSET(%rbp), %rdi
    # %rdi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq %rax, %rsi
    addq LOCAL_SCREEN_OFFSET(%rbp), %rsi
    # %rsi - Byte screen_data[$SCREEN_DATA_LENGTH]
    movq %rax, %rdx
    addq LOCAL_COLOURS_OFFSET(%rbp), %rdx
    # %rdx - Byte colours_data[$SCREEN_DATA_LENGTH]
    movq LOCAL_BACKGROUND_COLOUR_OFFSET(%rbp), %r9
    movb (%rax, %r9), %cl
    # %cl - Byte background_colour
    movb %cl, %r8b
    # %r8b - Byte border_colour = background_colour (default)
    cmpw $-1, LOCAL_BORDER_COLOUR_OFFSET(%rbp)
    je __load_mcp_3
    movq LOCAL_BORDER_COLOUR_OFFSET(%rbp), %r9
    movb (%rax, %r9), %r8b
    # %r8b - Byte border_colour = background_colour (custom)
__load_mcp_3:
    call new_mcp
    # %rax - Multicolour *multicolour

    leave
    ret

# uint64_t get_multicolour_config_value(MulticolourConfig *image_config, uint64_t offset);
.type get_multicolour_config_value, @function

# %rdi - MulticolourConfig *image_config
# %rsi - uint64_t offset
get_multicolour_config_value:

    movzwq (%rdi, %rsi), %rax
    # %rax - uint64_t config_value = *(static_cast<uint16_t *>(static_cast<uint8_t *>(image_config) + offset))

    ret

# Multicolour *new_mcp(
#   Byte *bitmap_data,
#   Byte *screen_data,
#   Byte *colours_data,
#   Byte background_colour,
#   Byte border_colour,
# );
.globl new_mcp
.type new_mcp, @function

# Byte bitmap_data[$BITMAP_DATA_LENGTH]
.equ LOCAL_BITMAP_DATA_PTR, -8
# Byte screen_data[$SCREEN_DATA_SIZE]
.equ LOCAL_SCREEN_DATA_PTR, -16
# Byte colours_data[$SCREEN_DATA_SIZE]
.equ LOCAL_COLOURS_DATA_PTR, -24
# Multicolour *multicolour
.equ LOCAL_MULTICOLOUR_PTR, -32
# Byte background_colour
.equ LOCAL_BACKGROUND_COLOUR, -33
# Byte border_colour
.equ LOCAL_BORDER_COLOUR, -34

# %rdi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
# %rsi - Byte screen_data[$SCREEN_DATA_SIZE]
# %rdx - Byte colours_data[$SCREEN_DATA_SIZE]
# %cl - Byte background_colour
# %r8b - Byte border_colour
new_mcp:

    # Reserve space for 6 variables (aligned to 16 bytes):
    enter $0x30, $0
    # %rdi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq %rdi, LOCAL_BITMAP_DATA_PTR(%rbp)
    # %rsi - Byte screen_data[$SCREEN_DATA_SIZE]
    movq %rsi, LOCAL_SCREEN_DATA_PTR(%rbp)
    # %rdx - Byte colours_data[$SCREEN_DATA_SIZE]
    movq %rdx, LOCAL_COLOURS_DATA_PTR(%rbp)
    # %cl - Byte background_colour
    movb %cl, LOCAL_BACKGROUND_COLOUR(%rbp)
    # %r8b - Byte border_colour
    movb %r8b, LOCAL_BORDER_COLOUR(%rbp)

    # Allocate memory to store the new Multicolour object:
    movq $MULTICOLOUR_TOTAL_SIZE, %rdi
    call malloc@plt
    # %rax - Multicolour *multicolour
    movq %rax, LOCAL_MULTICOLOUR_PTR(%rbp)

    # Allocate and initialise the member variable - BaseImage *multicolour->base_image
    movq LOCAL_BITMAP_DATA_PTR(%rbp), %rdi
    # %rdi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq LOCAL_SCREEN_DATA_PTR(%rbp), %rsi
    # %rsi - Byte screen_data[$SCREEN_DATA_SIZE]
    call new_base_image
    # %rax - BaseImage *base_image
    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rdi
    # %rdi - Multicolour *multicolour
    movq %rax, MULTICOLOUR_BASE_IMAGE_PTR_OFFSET(%rdi)

    # Allocate and initialise the member variable - ByteArray *multicolour->original_colours_data
    movq $SCREEN_DATA_LENGTH, %rdi
    # %rdi - uint64_t length
    movq LOCAL_COLOURS_DATA_PTR(%rbp), %rsi
    # %rsi - Byte *colours_data
    call new_byte_array
    # %rax - ByteArray *original_colours_data
    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rdi
    # %rdi - Multicolour *multicolour
    movq %rax, MULTICOLOUR_COLOURS_DATA_BYTES_PTR_OFFSET(%rdi)

    # Allocate and initialise the member variable - Screen *multicolour->colours
    movq LOCAL_COLOURS_DATA_PTR(%rbp), %rdi
    # %rdi - Byte data[$SCREEN_DATA_LENGTH]
    call new_screen
    # %rax - Screen *colours
    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rdi
    # %rdi - Multicolour multicolour
    movq %rax, MULTICOLOUR_COLOURS_PTR_OFFSET(%rdi)

    # Initialise the member variable - Byte multicolour->background_colour
    movb LOCAL_BACKGROUND_COLOUR(%rbp), %al
    # %al - Byte background_colour
    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rdi
    # %rdi - Multicolour *multicolour
    movb %al, MULTICOLOUR_BACKGROUND_COLOUR_OFFSET(%rdi)

    # Initialise the member variable - Byte multicolour->border_colour
    movb LOCAL_BORDER_COLOUR(%rbp), %al
    # %al - Byte border_colour
    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rdi
    # %rdi - Multicolour *multicolour
    movb %al, MULTICOLOUR_BORDER_COLOUR_OFFSET(%rdi)

    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rax
    # %rax - Multicolour *multicolour

    leave
    ret

# void delete_mcp(Multicolour *multicolour);
.globl delete_mcp
.type delete_mcp, @function

# Multicolour *multicolour
.equ LOCAL_MULTICOLOUR_PTR, -8

# %rdi - Multicolour *multicolour
delete_mcp:

    # Reserve space for 1 variable (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - Multicolour *multicolour
    movq %rdi, LOCAL_MULTICOLOUR_PTR(%rbp)
    # Do not deallocate a null pointer:
    cmpq $0, %rdi
    jz __delete_mcp_1

    # Deallocate the member variable - ByteArray *original_colours_data
    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rax
    # %rax - Multicolour *multicolour
    movq MULTICOLOUR_COLOURS_DATA_BYTES_PTR_OFFSET(%rax), %rdi
    # %rdi - ByteArray *multicolour->original_colours_data
    call delete_byte_array

    # Deallocate the member variable - Screen *colours
    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rax
    # %rax - Multicolour *multicolour
    movq MULTICOLOUR_COLOURS_PTR_OFFSET(%rax), %rdi
    # %rdi - Screen *multicolour->colours
    call delete_screen

    # Deallocate the member variable - BaseImage *base_image
    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rax
    # %rax - Multicolour *multicolour
    movq MULTICOLOUR_BASE_IMAGE_PTR_OFFSET(%rax), %rdi
    # %rdi - BaseImage *multicolour->base_image
    call delete_base_image

    # Deallocate the Multicolour object:
    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rdi
    # %rdi - Multicolour *multicolour
    movq $MULTICOLOUR_TOTAL_SIZE, %rsi
    # %rsi - uint64_t length
    call free_with_zero_fill

__delete_mcp_1:

    leave
    ret

# BaseImage *mcp_get_base_image(Multicolour *multicolour);
.type mcp_get_base_image, @function

# %rdi - Multicolour *multicolour
mcp_get_base_image:

    # %rdi - Multicolour *multicolour
    movq MULTICOLOUR_BASE_IMAGE_PTR_OFFSET(%rdi), %rax
    # %rax - BaseImage *base_image

    ret

# Bitmap *mcp_get_bitmap(Multicolour *multicolour);
.globl mcp_get_bitmap
.type mcp_get_bitmap, @function

# %rdi - Multicolour *multicolour
mcp_get_bitmap:

    # %rdi - Multicolour *multicolour
    call mcp_get_base_image
    # %rax - BaseImage *base_image
    movq %rax, %rdi
    # %rdi - BaseImage *base_image
    call base_image_get_bitmap
    # %rax - Bitmap *bitmap

    ret

# Screen *mcp_get_screen(Multicolour *multicolour);
.globl mcp_get_screen
.type mcp_get_screen, @function

# %rdi - Multicolour *multicolour
mcp_get_screen:

    # %rdi - Multicolour *multicolour
    call mcp_get_base_image
    # %rax - BaseImage *base_image
    movq %rax, %rdi
    # %rdi - BaseImage *base_image
    call base_image_get_screen
    # %rax - Screen *screen

    ret

# Screen *mcp_get_colours(Multicolour *multicolour);
.globl mcp_get_colours
.type mcp_get_colours, @function

# %rdi - Multicolour *multicolour
mcp_get_colours:

    # %rdi - Multicolour *multicolour
    movq MULTICOLOUR_COLOURS_PTR_OFFSET(%rdi), %rax
    # %rax - Screen *colours

    ret

# Byte mcp_get_background_colour(Multicolour *multicolour);
.globl mcp_get_background_colour
.type mcp_get_background_colour, @function

# %rdi - Multicolour *multicolour
mcp_get_background_colour:

    # %rdi - Multicolour *multicolour
    movb MULTICOLOUR_BACKGROUND_COLOUR_OFFSET(%rdi), %al
    # %al - Byte background_colour

    ret

# Byte mcp_get_border_colour(Multicolour *multicolour);
.globl mcp_get_border_colour
.type mcp_get_border_colour, @function

# %rdi - Multicolour *multicolour
mcp_get_border_colour:

    # %rdi - Multicolour *multicolour
    movb MULTICOLOUR_BORDER_COLOUR_OFFSET(%rdi), %al
    # %al - Byte border_colour

    ret

# Byte mcp_get_cbm_value_at_xy(Multicolour *multicolour, uint16_t x, uint16_t y);
# x = 0..159, y = 0..199
.globl mcp_get_cbm_value_at_xy
.type mcp_get_cbm_value_at_xy, @function

# Multicolour *multicolour
.equ LOCAL_MULTICOLOUR_PTR, -8
# uint16_t x
.equ LOCAL_X, -10
# uint16_t hires_x
.equ LOCAL_HIRES_X, -12
# uint16_t y
.equ LOCAL_Y, -14
# uint8_t bits
.equ LOCAL_BITS, -15
# Byte value
.equ LOCAL_VALUE, -16

# %rdi - Multicolour *multicolour
# %si - uint16_t x
# %dx - uint16_t y
mcp_get_cbm_value_at_xy:

    # Reserve space for 6 variables (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - Multicolour *multicolour
    movq %rdi, LOCAL_MULTICOLOUR_PTR(%rbp)
    # %si - uint16_t x
    movw %si, LOCAL_X(%rbp)
    # %dx - uint16_t y
    movw %dx, LOCAL_Y(%rbp)

    # Translate the multicolour coordinate X to the corresponding hires coordinate X:
    movw LOCAL_X(%rbp), %ax
    # %ax - uint16_t x
    shlw $1, %ax
    # %ax - uint16_t x = x * 2
    movw %ax, LOCAL_HIRES_X(%rbp)

    # Get bitmap bits at the multicolour coordinate X/Y:
    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rdi
    # %rdi - Multicolour *multicolour
    call mcp_get_bitmap
    # %rax - Bitmap *bitmap
    movq %rax, %rdi
    # %rdi - Bitmap *bitmap
    movw LOCAL_HIRES_X(%rbp), %si
    # %si - uint16_t hires_x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call bmp_get_mcp_bits_at_xy
    # %al - uint8_t bits
    movb %al, LOCAL_BITS(%rbp)

    # bits = "00": Background colour 0 ($d021)
    cmpb $0, LOCAL_BITS(%rbp)
    jne __mcp_get_cbm_value_at_xy_1

    # Get background colour of the Multicolour object:
    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rdi
    # %rdi - Multicolour *multicolour
    call mcp_get_background_colour
    # %al - Byte background_colour
    movb %al, LOCAL_VALUE(%rbp)

    jmp __mcp_get_cbm_value_at_xy_5

__mcp_get_cbm_value_at_xy_1:

    # bits = "01": Colour from bits 4-7 of screen memory
    cmpb $1, LOCAL_BITS(%rbp)
    jne __mcp_get_cbm_value_at_xy_2

    # Get screen value at the multicolour coordinate X/Y:
    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rdi
    # %rdi - Multicolour *multicolour
    call mcp_get_screen
    # %rax - Screen *screen
    movq %rax, %rdi
    # %rdi - Screen *screen
    movw LOCAL_HIRES_X(%rbp), %si
    # %si - uint16_t hires_x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call scr_get_value_at_pixel_xy
    # %al - uint8_t value

    andb $0xf0, %al
    shrb $4, %al
    movb %al, LOCAL_VALUE(%rbp)

    jmp __mcp_get_cbm_value_at_xy_5

__mcp_get_cbm_value_at_xy_2:

    # bits = "10": Colour from bits 0-3 of screen memory
    cmpb $2, LOCAL_BITS(%rbp)
    jne __mcp_get_cbm_value_at_xy_3

    # Get screen value at the multicolour coordinate X/Y:
    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rdi
    # %rdi - Multicolour *multicolour
    call mcp_get_screen
    # %rax - Screen *screen
    movq %rax, %rdi
    # %rdi - Screen *screen
    movw LOCAL_HIRES_X(%rbp), %si
    # %si - uint16_t hires_x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call scr_get_value_at_pixel_xy
    # %al - uint8_t value

    andb $0x0f, %al
    movb %al, LOCAL_VALUE(%rbp)

    jmp __mcp_get_cbm_value_at_xy_5

__mcp_get_cbm_value_at_xy_3:

    # bits = "11": Colour from bits 8-11 of colour memory
    cmpb $3, LOCAL_BITS(%rbp)
    jne __mcp_get_cbm_value_at_xy_4

    # Get colour value at the multicolour coordinate X/Y:
    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rdi
    # %rdi - Multicolour *multicolour
    call mcp_get_colours
    # %rax - Screen *colours
    movq %rax, %rdi
    # %rdi - Screen *colours
    movw LOCAL_HIRES_X(%rbp), %si
    # %si - uint16_t hires_x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call scr_get_value_at_pixel_xy
    # %al - uint8_t value

    andb $0x0f, %al
    movb %al, LOCAL_VALUE(%rbp)

    jmp __mcp_get_cbm_value_at_xy_5

__mcp_get_cbm_value_at_xy_4:

    leaq get_cbm_value_at_xy_error_message(%rip), %rsi
    movzwq LOCAL_X(%rbp), %rdx
    movzwq LOCAL_Y(%rbp), %rcx
    jmp throw_runtime_error

__mcp_get_cbm_value_at_xy_5:

    movb LOCAL_VALUE(%rbp), %al
    # %al - Byte value

    leave
    ret

# Byte mcp_get_cbm_value_at_hires_xy(Multicolour *multicolour, uint16_t x, uint16_t y);
# x = 0..319, y = 0..199
.type mcp_get_cbm_value_at_hires_xy, @function

# Multicolour *multicolour
.equ LOCAL_MULTICOLOUR_PTR, -8
# uint16_t x
.equ LOCAL_X, -10
# uint16_t multicolour_x
.equ LOCAL_MULTICOLOUR_X, -12
# uint16_t y
.equ LOCAL_Y, -14

# %rdi - Multicolour *multicolour
# %si - uint16_t x
# %dx - uint16_t y
mcp_get_cbm_value_at_hires_xy:

    # Reserve space for 4 variables (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - Multicolour *multicolour
    movq %rdi, LOCAL_MULTICOLOUR_PTR(%rbp)
    # %si - uint16_t x
    movw %si, LOCAL_X(%rbp)
    # %dx - uint16_t y
    movw %dx, LOCAL_Y(%rbp)

    # Translate the hires coordinate X to the corresponding multicolour coordinate X:
    movw LOCAL_X(%rbp), %ax
    # %ax - uint16_t x
    shrw $1, %ax
    # %ax - uint16_t x = x / 2
    movw %ax, LOCAL_MULTICOLOUR_X(%rbp)

    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rdi
    # %rdi - Multicolour *multicolour
    movw LOCAL_MULTICOLOUR_X(%rbp), %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call mcp_get_cbm_value_at_xy
    # %al - Byte value

    leave
    ret

# Byte mcp_get_original_rgb_value_at_hires_xy(Multicolour *multicolour, uint16_t x, uint16_t y);
# x = 0..319, y = 0..199
.type mcp_get_original_rgb_value_at_hires_xy, @function

# %rdi - Multicolour *multicolour
# %si - uint16_t x
# %dx - uint16_t y
mcp_get_original_rgb_value_at_hires_xy:

    movq $0, %rax
    # %rax - png_bytep original_rgb_value = nullptr

    ret

# PixelMap *mcp_get_pixels(Multicolour *multicolour, enum colour_palette palette);
.globl mcp_get_pixels
.type mcp_get_pixels, @function

# Multicolour *multicolour
.equ LOCAL_MULTICOLOUR_PTR, -8
# enum colour_palette palette
.equ LOCAL_COLOUR_PALETTE, -9

# %rdi - Multicolour *multicolour
# %sil - enum colour_palette palette
mcp_get_pixels:

    # Reserve space for 1 variable (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - Multicolour *multicolour
    movq %rdi, LOCAL_MULTICOLOUR_PTR(%rbp)
    # %sil - enum colour_palette palette
    movb %sil, LOCAL_COLOUR_PALETTE(%rbp)

    # PixelMap *pixel_map = new_pixel_map(
    #   uint16_t width,
    #   uint16_t height
    #   Multicolour *multicolour,
    #   Byte (*get_cbm_value)(Multicolour *multicolour, uint16_t x, uint16_t y),
    #   enum colour_palette palette,
    #   png_bytep (*get_original_rgb_value)(Multicolour *multicolour, uint16_t x, uint16_t y),
    # );

    movw $BITMAP_WIDTH, %di
    # %di - uint16_t width
    movw $BITMAP_HEIGHT, %si
    # %si - uint16_t height
    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rdx
    # %rdx - Multicolour *multicolour
    leaq mcp_get_cbm_value_at_hires_xy(%rip), %rcx
    # %rcx - Byte (*get_cbm_value)(Multicolour *multicolour, uint16_t x, uint16_t y)
    movb LOCAL_COLOUR_PALETTE(%rbp), %r8b
    # %r8b - enum colour_palette palette
    leaq mcp_get_original_rgb_value_at_hires_xy(%rip), %r9
    # %r9 - png_bytep (*get_original_rgb_value)(Multicolour *multicolour, uint16_t x, uint16_t y)
    call new_pixel_map
    # %rax - PixelMap pixel_map

    leave
    ret

# Byte *export_mcp(Multicolour *multicolour, MulticolourConfig *image_config);
.globl export_mcp
.type export_mcp, @function

# Multicolour *multicolour
.equ LOCAL_MULTICOLOUR_PTR, -8
# MulticolourConfig *image_config
.equ LOCAL_IMAGE_CONFIG_PTR, -16
# uint64_t data_length
.equ LOCAL_DATA_LENGTH, -24
# Byte *data
.equ LOCAL_DATA_PTR, -32
# uint64_t bitmap_offset
.equ LOCAL_BITMAP_OFFSET, -40
# uint64_t screen_offset
.equ LOCAL_SCREEN_OFFSET, -48
# uint64_t colours_offset
.equ LOCAL_COLOURS_OFFSET, -56
# uint64_t background_colour_offset
.equ LOCAL_BACKGROUND_COLOUR_OFFSET, -64
# uint64_t border_colour_offset
.equ LOCAL_BORDER_COLOUR_OFFSET, -72
# uint16_t load_address
.equ LOCAL_LOAD_ADDRESS, -74

# %rdi - Multicolour *multicolour
# %rsi - MulticolourConfig *image_config
export_mcp:

    # Reserve space for 10 variables (aligned to 16 bytes):
    enter $0x50, $0
    # %rdi - Multicolour *multicolour
    movq %rdi, LOCAL_MULTICOLOUR_PTR(%rbp)
    # %rsi - MulticolourConfig *image_config
    movq %rsi, LOCAL_IMAGE_CONFIG_PTR(%rbp)

    # Get base image configuration:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - MulticolourConfig *image_config
    movq $MULTICOLOUR_CONFIG_DATA_LENGTH_OFFSET, %rsi
    # %rsi - uint64_t data_length_offset
    call get_multicolour_config_value
    # %ax - uint64_t image_config->data_length
    movq %rax, LOCAL_DATA_LENGTH(%rbp)
    movq $MULTICOLOUR_CONFIG_LOAD_ADDRESS_OFFSET, %rsi
    # %rsi - uint64_t load_address_offset
    call get_multicolour_config_value
    # %ax - uint16_t image_config->load_address
    movw %ax, LOCAL_LOAD_ADDRESS(%rbp)
    movq $MULTICOLOUR_CONFIG_BITMAP_DATA_OFFSET, %rsi
    # %rsi - uint64_t bitmap_data_offset
    call get_multicolour_config_value
    # %rax - uint64_t image_config->bitmap_offset
    movq %rax, LOCAL_BITMAP_OFFSET(%rbp)
    movq $MULTICOLOUR_CONFIG_SCREEN_DATA_OFFSET, %rsi
    # %rsi - uint64_t screen_data_offset
    call get_multicolour_config_value
    # %rax - uint64_t image_config->screen_offset
    movq %rax, LOCAL_SCREEN_OFFSET(%rbp)

    # Get multicolour image configuration:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - MulticolourConfig *image_config
    movq $MULTICOLOUR_CONFIG_COLOURS_DATA_OFFSET, %rsi
    # %rsi - uint64_t colours_data_offset
    call get_multicolour_config_value
    # %rax - uint64_t image_config->colours_offset
    movq %rax, LOCAL_COLOURS_OFFSET(%rbp)
    movq $MULTICOLOUR_CONFIG_BACKGROUND_COLOUR_OFFSET, %rsi
    # %rsi - uint64_t background_colour_offset
    call get_multicolour_config_value
    # %rax - uint64_t image_config->background_colour_offset
    movq %rax, LOCAL_BACKGROUND_COLOUR_OFFSET(%rbp)
    movq $MULTICOLOUR_CONFIG_BORDER_COLOUR_OFFSET, %rsi
    # %rsi - uint64_t border_colour_offset
    call get_multicolour_config_value
    # %rax - uint64_t image_config->border_colour_offset
    movq %rax, LOCAL_BORDER_COLOUR_OFFSET(%rbp)

    # Allocate memory to store the exported Multicolour data and initialise base image data:
    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rdi
    # %rdi - Multicolour *multicolour
    call mcp_get_base_image
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

    # Store colours data into the exported BaseImage data:
    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rdi
    # %rdi - Multicolour *multicolour
    call mcp_get_colours
    # %rax - Screen *colours
    movq %rax, %rdi
    # %rdi - Screen *colours
    movq LOCAL_DATA_PTR(%rbp), %rsi
    # %rsi - Byte *data
    addq LOCAL_COLOURS_OFFSET(%rbp), %rsi
    # %rsi - Byte *target_data = data + colours_offset;
    call scr_copy_data

    # Store background colour into the exported BaseImage data:
    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rdi
    # %rdi - Multicolour *multicolour
    call mcp_get_background_colour
    # %al - Byte background_colour
    movq LOCAL_DATA_PTR(%rbp), %rsi
    # %rsi - Byte *data
    addq LOCAL_BACKGROUND_COLOUR_OFFSET(%rbp), %rsi
    # %rsi - Byte *target_data = data + background_colour_offset;
    movb %al, (%rsi)
    # data[background_colour_offset] = background_colour;

    # Store border colour (if present) into the exported BaseImage data:
    cmpw $-1, LOCAL_BORDER_COLOUR_OFFSET(%rbp)
    je __export_mcp_1
    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rdi
    # %rdi - Multicolour *multicolour
    call mcp_get_border_colour
    # %al - Byte border_colour
    movq LOCAL_DATA_PTR(%rbp), %rsi
    # %rsi - Byte *data
    addq LOCAL_BORDER_COLOUR_OFFSET(%rbp), %rsi
    # %rsi - Byte *target_data = data + border_colour_offset;
    movb %al, (%rsi)
    # data[border_colour_offset] = border_colour;

__export_mcp_1:

    movq LOCAL_DATA_PTR(%rbp), %rax
    # %rax - Byte *data

    leave
    ret
