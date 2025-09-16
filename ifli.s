.include "const.s"

.section .data

.type data_length_error_message, @object
data_length_error_message:
    .ascii "invalid data length: got $%04x, expected $%04x\n\0"

.type load_address_error_message, @object
load_address_error_message:
    .ascii "invalid load address: got $%04x, expected $%04x\n\0"

.section .text

# IFLI *load_ifli(
#   Byte *data,
#   uint64_t data_size,
#   IFLIConfig *image_config,
# );
.globl load_ifli
.type load_ifli, @function

# Byte *data
.equ LOCAL_DATA_PTR, -8
# uint64_t data_size
.equ LOCAL_DATA_SIZE, -16
# IFLIConfig *image_config
.equ LOCAL_IMAGE_CONFIG_PTR, -24
# uint64_t bitmap_1_offset
.equ LOCAL_BITMAP_1_OFFSET, -32
# uint64_t screens_1_offset
.equ LOCAL_SCREENS_1_OFFSET, -40
# uint64_t bitmap_2_offset
.equ LOCAL_BITMAP_2_OFFSET, -48
# uint64_t screens_2_offset
.equ LOCAL_SCREENS_2_OFFSET, -56
# uint64_t colours_offset
.equ LOCAL_COLOURS_OFFSET, -64
# ByteArray *(*get_d021_colours_fun)(std::byte *)
.equ LOCAL_GET_D021_COLOURS_FUN_PTR, -72
# uint64_t border_colour_offset
.equ LOCAL_BORDER_COLOUR_OFFSET, -80
# uint64_t screen_size
.equ LOCAL_SCREEN_SIZE, -88
# ByteArray d021_colours[BITMAP_HEIGHT]
.equ LOCAL_D021_COLOURS_PTR, -96
# IFLI *ifli
.equ LOCAL_IFLI_PTR, -104

# %rdi - Byte *data
# %rsi - uint64_t data_size
# %rdx - IFLIConfig *image_config
load_ifli:

    # Reserve space for 13 variables (aligned to 16 bytes):
    enter $0x70, $0
    # %rdi - Byte *data
    movq %rdi, LOCAL_DATA_PTR(%rbp)
    # %rsi - uint64_t data_size
    movq %rsi, LOCAL_DATA_SIZE(%rbp)
    # %rdx - IFLIConfig *image_config
    movq %rdx, LOCAL_IMAGE_CONFIG_PTR(%rbp)

    # Assert data_size == image_config->data_length:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - IFLIConfig *image_config
    movq $IFLI_CONFIG_DATA_LENGTH_OFFSET, %rsi
    # %rsi - uint64_t data_length_offset
    call get_ifli_word_config_value
    # %ax - uint64_t image_config->data_length
    cmpw %ax, LOCAL_DATA_SIZE(%rbp)
    jz __load_ifli_1

    leaq data_length_error_message(%rip), %rsi
    movzwq LOCAL_DATA_SIZE(%rbp), %rdx
    movzwq %ax, %rcx
    jmp throw_runtime_error

__load_ifli_1:

    # Assert *(uint16_t)data == image_config->load_address:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - IFLIConfig *image_config
    movq $IFLI_CONFIG_LOAD_ADDRESS_OFFSET, %rsi
    # %rsi - uint64_t load_address_offset
    call get_ifli_word_config_value
    # %ax - uint16_t image_config->load_address
    movq LOCAL_DATA_PTR(%rbp), %rdi
    cmpw %ax, (%rdi)
    jz __load_ifli_2

    leaq load_address_error_message(%rip), %rsi
    movzwq (%rdi), %rdx
    movzwq %ax, %rcx
    jmp throw_runtime_error

__load_ifli_2:

    # Get image_config->bitmap_1_offset value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - IFLIConfig *image_config
    movq $IFLI_CONFIG_BITMAP_1_DATA_OFFSET, %rsi
    # %rsi - uint64_t bitmap_1_data_offset
    call get_ifli_word_config_value
    # %rax - uint64_t image_config->bitmap_1_offset
    movq %rax, LOCAL_BITMAP_1_OFFSET(%rbp)

    # Get image_config->screens_1_offset value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - IFLIConfig *image_config
    movq $IFLI_CONFIG_SCREENS_1_DATA_OFFSET, %rsi
    # %rsi - uint64_t screens_1_data_offset
    call get_ifli_word_config_value
    # %rax - uint64_t image_config->screens_1_offset
    movq %rax, LOCAL_SCREENS_1_OFFSET(%rbp)

    # Get image_config->bitmap_2_offset value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - IFLIConfig *image_config
    movq $IFLI_CONFIG_BITMAP_2_DATA_OFFSET, %rsi
    # %rsi - uint64_t bitmap_2_data_offset
    call get_ifli_word_config_value
    # %rax - uint64_t image_config->bitmap_2_offset
    movq %rax, LOCAL_BITMAP_2_OFFSET(%rbp)

    # Get image_config->screens_2_offset value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - IFLIConfig *image_config
    movq $IFLI_CONFIG_SCREENS_2_DATA_OFFSET, %rsi
    # %rsi - uint64_t screens_2_data_offset
    call get_ifli_word_config_value
    # %rax - uint64_t image_config->screens_2_offset
    movq %rax, LOCAL_SCREENS_2_OFFSET(%rbp)

    # Get image_config->colours_offset value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - IFLIConfig *image_config
    movq $IFLI_CONFIG_COLOURS_DATA_OFFSET, %rsi
    # %rsi - uint64_t colours_data_offset
    call get_ifli_word_config_value
    # %rax - uint64_t image_config->colours_offset
    movq %rax, LOCAL_COLOURS_OFFSET(%rbp)

    # Get image_config->get_d021_colours_fun value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - IFLIConfig *image_config
    movq $IFLI_CONFIG_GET_D021_COLOURS_FUN_PTR_OFFSET, %rsi
    # %rsi - uint64_t get_d021_colours_fun_offset
    call get_ifli_quad_config_value
    # %rax - ByteArray *(*get_d021_colours_fun)(std::byte *)
    movq %rax, LOCAL_GET_D021_COLOURS_FUN_PTR(%rbp)

    # Get image_config->border_colour_offset value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - IFLIConfig *image_config
    movq $IFLI_CONFIG_BORDER_COLOUR_OFFSET, %rsi
    # %rsi - uint64_t border_colour_offset
    call get_ifli_word_config_value
    # %rax - uint64_t image_config->border_colour_offset
    movq %rax, LOCAL_BORDER_COLOUR_OFFSET(%rbp)

    # Get image_config->screen_size value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - IFLIConfig *image_config
    movq $IFLI_CONFIG_SCREEN_SIZE_OFFSET, %rsi
    # %rsi - uint64_t screen_size_offset
    call get_ifli_word_config_value
    # %rax - uint64_t image_config->screen_size
    movq %rax, LOCAL_SCREEN_SIZE(%rbp)

    # Extract an array of $d021 colours from input data:
    movq LOCAL_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *data
    call *LOCAL_GET_D021_COLOURS_FUN_PTR(%rbp)
    # %rax - ByteArray d021_colours[BITMAP_HEIGHT]
    movq %rax, LOCAL_D021_COLOURS_PTR(%rbp)

    # Allocate and initialise IFLI object instance:
    movq LOCAL_DATA_PTR(%rbp), %rax
    # %rax - Byte *data
    movq %rax, %rdi
    addq LOCAL_BITMAP_1_OFFSET(%rbp), %rdi
    # %rdi - Byte bitmap_1_data[$BITMAP_DATA_LENGTH]
    movq %rax, %rsi
    addq LOCAL_SCREENS_1_OFFSET(%rbp), %rsi
    # %rsi - Byte screens_1_data[screen_size * $FLI_SCREEN_COUNT]
    movq %rax, %rdx
    addq LOCAL_BITMAP_2_OFFSET(%rbp), %rdx
    # %rdx - Byte bitmap_1_data[$BITMAP_DATA_LENGTH]
    movq %rax, %rcx
    addq LOCAL_SCREENS_2_OFFSET(%rbp), %rcx
    # %rcx - Byte screens_1_data[screen_size * $FLI_SCREEN_COUNT]
    movq %rax, %r8
    addq LOCAL_COLOURS_OFFSET(%rbp), %r8
    # %r8 - Byte colours_data[$SCREEN_DATA_LENGTH]
    movq LOCAL_D021_COLOURS_PTR(%rbp), %r9
    # %r9 - ByteArray d021_colours[BITMAP_HEIGHT]
    movq LOCAL_SCREEN_SIZE(%rbp), %rax
    pushq %rax
    # (%rsp)[1] - uint16_t screen_size
    movb $DEFAULT_BORDER_COLOUR, %r10b
    # %r10b - Byte border_colour = default_border_colour (default)
    cmpw $-1, LOCAL_BORDER_COLOUR_OFFSET(%rbp)
    je __load_ifli_3
    movq LOCAL_BORDER_COLOUR_OFFSET(%rbp), %r11
    movb (%rax, %r11), %r10b
    # %r10b - Byte border_colour = border_colour (custom)
__load_ifli_3:
    movzbq %r10b, %rax
    pushq %rax
    # (%rsp)[0] - Byte border_colour
    call new_ifli
    addq $16, %rsp
    # %rax - IFLI *ifli
    movq %rax, LOCAL_IFLI_PTR(%rbp)

    # Deallocate an array of extracted $d021 colours:
    movq LOCAL_D021_COLOURS_PTR(%rbp), %rdi
    # %rdi - ByteArray d021_colours[BITMAP_HEIGHT]
    call delete_byte_array

    movq LOCAL_IFLI_PTR(%rbp), %rax
    # %rax - IFLI *ifli

    leave
    ret

# uint64_t get_ifli_word_config_value(IFLIConfig *image_config, uint64_t offset);
.type get_ifli_word_config_value, @function

# %rdi - IFLIConfig *image_config
# %rsi - uint64_t offset
get_ifli_word_config_value:

    movzwq (%rdi, %rsi), %rax
    # %rax - uint64_t config_value = *(static_cast<uint16_t *>(static_cast<uint8_t *>(image_config) + offset))

    ret

# uint64_t get_ifli_quad_config_value(IFLIConfig *image_config, uint64_t offset);
.type get_ifli_quad_config_value, @function

# %rdi - IFLIConfig *image_config
# %rsi - uint64_t offset
get_ifli_quad_config_value:

    movq (%rdi, %rsi), %rax
    # %rax - uint64_t config_value = *(image_config + offset)

    ret

# IFLI *new_ifli(
#   Byte *bitmap_1_data,
#   Byte *screen_1_data,
#   Byte *bitmap_2_data,
#   Byte *screen_2_data,
#   Byte *colours_data,
#   ByteArray d021_colours[BITMAP_HEIGHT],
#   Byte border_colour,
#   uint16_t screen_size,
# );
.type new_ifli, @function

# uint16_t screen_size
.equ LOCAL_SCREEN_SIZE, +24
# Byte border_colour
.equ LOCAL_BORDER_COLOUR, +16
# Byte bitmap_1_data[$BITMAP_DATA_LENGTH]
.equ LOCAL_BITMAP_1_DATA_PTR, -8
# Byte screen_1_data[screen_size * $FLI_SCREEN_COUNT]
.equ LOCAL_SCREEN_1_DATA_PTR, -16
# Byte bitmap_2_data[$BITMAP_DATA_LENGTH]
.equ LOCAL_BITMAP_2_DATA_PTR, -24
# Byte screen_2_data[screen_size * $FLI_SCREEN_COUNT]
.equ LOCAL_SCREEN_2_DATA_PTR, -32
# Byte colours_data[$SCREEN_DATA_SIZE]
.equ LOCAL_COLOURS_DATA_PTR, -40
# ByteArray d021_colours[BITMAP_HEIGHT]
.equ LOCAL_D021_COLOURS_PTR, -48
# IFLI *ifli
.equ LOCAL_IFLI_PTR, -56

# %rdi - Byte *bitmap_1_data
# %rsi - Byte *screen_1_data
# %rdx - Byte *bitmap_2_data
# %rcx - Byte *screen_2_data
# %r8 - Byte *colours_data
# %r9 - ByteArray d021_colours[BITMAP_HEIGHT]
# (%rsp)[0] - Byte border_colour
# (%rsp)[1] - uint16_t screen_size
new_ifli:

    # Reserve space for 7 variables (aligned to 16 bytes):
    enter $0x40, $0
    # %rdi - Byte *bitmap_1_data
    movq %rdi, LOCAL_BITMAP_1_DATA_PTR(%rbp)
    # %rsi - Byte *screen_1_data
    movq %rsi, LOCAL_SCREEN_1_DATA_PTR(%rbp)
    # %rdx - Byte *bitmap_2_data
    movq %rdx, LOCAL_BITMAP_2_DATA_PTR(%rbp)
    # %rcx - Byte *screen_2_data
    movq %rcx, LOCAL_SCREEN_2_DATA_PTR(%rbp)
    # %r8 - Byte *colours_data
    movq %r8, LOCAL_COLOURS_DATA_PTR(%rbp)
    # %r9 - ByteArray d021_colours[BITMAP_HEIGHT]
    movq %r9, LOCAL_D021_COLOURS_PTR(%rbp)

    # Allocate memory to store the new IFLI object:
    movq $IFLI_TOTAL_SIZE, %rdi
    call malloc@plt
    # %rax - IFLI *ifli
    movq %rax, LOCAL_IFLI_PTR(%rbp)

    # Allocate and initialise the member variable - FLI *ifli->fli_1
    movq LOCAL_BITMAP_1_DATA_PTR(%rbp), %rdi
    # %rdi - Byte bitmap_1_data[$BITMAP_DATA_LENGTH]
    movq LOCAL_SCREEN_1_DATA_PTR(%rbp), %rsi
    # %rsi - Byte screen_1_data[screen_size * $FLI_SCREEN_COUNT]
    movq LOCAL_COLOURS_DATA_PTR(%rbp), %rdx
    # %rdx - Byte colours_data[$SCREEN_DATA_SIZE]
    movq LOCAL_D021_COLOURS_PTR(%rbp), %rcx
    # %rcx - ByteArray d021_colours[BITMAP_HEIGHT]
    movb LOCAL_BORDER_COLOUR(%rbp), %r8b
    # %r8b - Byte border_colour
    movw LOCAL_SCREEN_SIZE(%rbp), %r9w
    # %r9w - uint16_t screen_size
    call new_fli
    # %rax - FLI *fli_1
    movq LOCAL_IFLI_PTR(%rbp), %rdi
    # %rdi - IFLI *ifli
    movq %rax, IFLI_FLI_1_PTR_OFFSET(%rdi)
    # FLI *ifli->fli_1 = fli_1

    # Allocate and initialise the member variable - FLI *ifli->fli_2
    movq LOCAL_BITMAP_2_DATA_PTR(%rbp), %rdi
    # %rdi - Byte bitmap_2_data[$BITMAP_DATA_LENGTH]
    movq LOCAL_SCREEN_2_DATA_PTR(%rbp), %rsi
    # %rsi - Byte screen_2_data[screen_size * $FLI_SCREEN_COUNT]
    movq LOCAL_COLOURS_DATA_PTR(%rbp), %rdx
    # %rdx - Byte colours_data[$SCREEN_DATA_SIZE]
    movq LOCAL_D021_COLOURS_PTR(%rbp), %rcx
    # %rcx - ByteArray d021_colours[BITMAP_HEIGHT]
    movb LOCAL_BORDER_COLOUR(%rbp), %r8b
    # %r8b - Byte border_colour
    movw LOCAL_SCREEN_SIZE(%rbp), %r9w
    # %r9w - uint16_t screen_size
    call new_fli
    # %rax - FLI *fli_2
    movq LOCAL_IFLI_PTR(%rbp), %rdi
    # %rdi - IFLI *ifli
    movq %rax, IFLI_FLI_2_PTR_OFFSET(%rdi)
    # FLI *ifli->fli_2 = fli_2

    movq LOCAL_IFLI_PTR(%rbp), %rax
    # %rax - IFLI *ifli

    leave
    ret

# void delete_ifli(IFLI *ifli);
.globl delete_ifli
.type delete_ifli, @function

# IFLI *ifli
.equ LOCAL_IFLI_PTR, -8

# %rdi - IFLI *ifli
delete_ifli:

    # Reserve space for 1 variable (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - IFLI *ifli
    movq %rdi, LOCAL_IFLI_PTR(%rbp)
    # Do not deallocate a null pointer:
    cmpq $0, %rdi
    jz __delete_ifli_1

    # Deallocate the member variable - FLI *ifli->fli_1
    movq LOCAL_IFLI_PTR(%rbp), %rdi
    # %rdi - IFLI *ifli
    call ifli_get_fli_1
    # %rax - FLI *ifli->fli_1
    movq %rax, %rdi
    # %rdi - FLI *ifli->fli_1
    call delete_fli

    # Deallocate the member variable - FLI *ifli->fli_2
    movq LOCAL_IFLI_PTR(%rbp), %rdi
    # %rdi - IFLI *ifli
    call ifli_get_fli_2
    # %rax - FLI *ifli->fli_2
    movq %rax, %rdi
    # %rdi - FLI *ifli->fli_2
    call delete_fli

    # Deallocate the IFLI object:
    movq LOCAL_IFLI_PTR(%rbp), %rdi
    # %rdi - IFLI *ifli
    movq $IFLI_TOTAL_SIZE, %rsi
    # %rsi - uint64_t length
    call free_with_zero_fill

__delete_ifli_1:

    leave
    ret

# FLI *ifli_get_fli_1(IFLI *ifli);
.globl ifli_get_fli_1
.type ifli_get_fli_1, @function

# %rdi - IFLI *ifli
ifli_get_fli_1:

    # %rdi - IFLI *ifli
    movq IFLI_FLI_1_PTR_OFFSET(%rdi), %rax
    # %rax - FLI *ifli->fli_1

    ret

# FLI *ifli_get_fli_2(IFLI *ifli);
.globl ifli_get_fli_2
.type ifli_get_fli_2, @function

# %rdi - IFLI *ifli
ifli_get_fli_2:

    # %rdi - IFLI *ifli
    movq IFLI_FLI_2_PTR_OFFSET(%rdi), %rax
    # %rax - FLI *ifli->fli_2

    ret

# PixelMap *ifli_get_pixels(IFLI *ifli, enum colour_palette palette);
.globl ifli_get_pixels
.type ifli_get_pixels, @function

# IFLI *ifli
.equ LOCAL_IFLI_PTR, -8
# enum colour_palette palette
.equ LOCAL_COLOUR_PALETTE, -9

# %rdi - IFLI *ifli
# %sil - enum colour_palette palette
ifli_get_pixels:

    # Reserve space for 1 variable (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - IFLI *ifli
    movq %rdi, LOCAL_IFLI_PTR(%rbp)
    # %sil - enum colour_palette palette
    movb %sil, LOCAL_COLOUR_PALETTE(%rbp)

    # PixelMap *pixel_map = new_pixel_map(
    #   uint16_t width,
    #   uint16_t height
    #   IFLI *ifli,
    #   ByteArray *(*get_cbm_value)(IFLI *ifli, uint16_t x, uint16_t y),
    #   enum colour_palette palette,
    #   png_bytep (*get_original_rgb_value)(IFLI *ifli, uint16_t x, uint16_t y),
    # );

    movw $BITMAP_WIDTH, %di
    # %di - uint16_t width
    movw $BITMAP_HEIGHT, %si
    # %si - uint16_t height
    movq LOCAL_IFLI_PTR(%rbp), %rdx
    # %rdx - IFLI *ifli
    leaq ifli_get_cbm_value_at_hires_xy(%rip), %rcx
    # %rcx - ByteArray *(*get_cbm_value)(IFLI *ifli, uint16_t x, uint16_t y)
    movb LOCAL_COLOUR_PALETTE(%rbp), %r8b
    # %r8b - enum colour_palette palette
    leaq ifli_get_original_rgb_value_at_hires_xy(%rip), %r9
    # %r9 - png_bytep (*get_original_rgb_value)(IFLI *ifli, uint16_t x, uint16_t y)
    call new_pixel_map
    # %rax - PixelMap pixel_map

    leave
    ret

# Byte ifli_get_original_rgb_value_at_hires_xy(IFLI *ifli, uint16_t x, uint16_t y);
# x = 0..319, y = 0..199
.type ifli_get_original_rgb_value_at_hires_xy, @function

# %rdi - IFLI *ifli
# %si - uint16_t x
# %dx - uint16_t y
ifli_get_original_rgb_value_at_hires_xy:

    movq $0, %rax
    # %rax - png_bytep original_rgb_value = nullptr

    ret

# ByteArray *ifli_get_cbm_value_at_hires_xy(IFLI *ifli, uint16_t x, uint16_t y);
# x = 0..319, y = 0..199
.type ifli_get_cbm_value_at_hires_xy, @function

# IFLI *ifli
.equ LOCAL_IFLI_PTR, -8
# uint16_t x
.equ LOCAL_X, -10
# uint16_t multicolour_x
.equ LOCAL_MULTICOLOUR_X, -12
# uint16_t y
.equ LOCAL_Y, -14
# Byte cbm_value_1
.equ LOCAL_CBM_VALUE_1, -15
# Byte cbm_value_2
.equ LOCAL_CBM_VALUE_2, -16
# ByteArray *cbm_values
.equ LOCAL_CBM_VALUES_PTR, -24
# Byte data[2]
.equ LOCAL_DATA, -26

# %rdi - IFLI *ifli
# %si - uint16_t x
# %dx - uint16_t y
ifli_get_cbm_value_at_hires_xy:

    # Reserve space for 8 variables (aligned to 16 bytes):
    enter $0x20, $0
    # %rdi - IFLI *ifli
    movq %rdi, LOCAL_IFLI_PTR(%rbp)
    # %si - uint16_t x
    movw %si, LOCAL_X(%rbp)
    # %dx - uint16_t y
    movw %dx, LOCAL_Y(%rbp)

    # Get CBM colour value from the first FLI picture:

    movq LOCAL_IFLI_PTR(%rbp), %rdi
    # %rdi - IFLI *ifli
    call ifli_get_fli_1
    # %rax - FLI *ifli->fli_1
    movq %rax, %rdi
    # %rdi - FLI *fli_1
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call fli_get_cbm_value_at_hires_xy
    # %rax - ByteArray *cbm_values_1
    movq %rax, LOCAL_CBM_VALUES_PTR(%rbp)

    movq LOCAL_CBM_VALUES_PTR(%rbp), %rdi
    # %rdi - ByteArray *cbm_values_1
    movq $0, %rsi
    # %rsi - std::size_t offset = 0
    call byte_array_get_value_at
    # %al - Byte cbm_value_1
    movb %al, LOCAL_CBM_VALUE_1(%rbp)

    movq LOCAL_CBM_VALUES_PTR(%rbp), %rdi
    # %rdi - ByteArray *cbm_values_1
    call delete_byte_array

    # Get CBM colour value from the second (shifted) FLI picture:

    movq LOCAL_IFLI_PTR(%rbp), %rdi
    # %rdi - IFLI *ifli
    call ifli_get_fli_2
    # %rax - FLI *ifli->fli_2
    movq %rax, %rdi
    # %rdi - FLI *fli_2

    # if (x == 0) {
    #   Byte cbm_value_2 = fli_get_background_colour(fli_2, y);
    # }

    cmpw $0, LOCAL_X(%rbp)
    jnz __ifli_get_cbm_value_at_hires_xy_1

    movw LOCAL_Y(%rbp), %si
    # %si - uint16_t y
    call fli_get_background_colour
    # %al - Byte cbm_value_2 = background_colour[y]
    movb %al, LOCAL_CBM_VALUE_2(%rbp)

    jmp __ifli_get_cbm_value_at_hires_xy_2

__ifli_get_cbm_value_at_hires_xy_1:

    movw LOCAL_X(%rbp), %si
    subw $1, %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call fli_get_cbm_value_at_hires_xy
    # %rax - ByteArray *cbm_values_2
    movq %rax, LOCAL_CBM_VALUES_PTR(%rbp)

    movq LOCAL_CBM_VALUES_PTR(%rbp), %rdi
    # %rdi - ByteArray *cbm_values_2
    movq $0, %rsi
    # %rsi - std::size_t offset = 0
    call byte_array_get_value_at
    # %al - Byte cbm_value_2
    movb %al, LOCAL_CBM_VALUE_2(%rbp)

    movq LOCAL_CBM_VALUES_PTR(%rbp), %rdi
    # %rdi - ByteArray *cbm_values_2
    call delete_byte_array

__ifli_get_cbm_value_at_hires_xy_2:

    movb LOCAL_CBM_VALUE_2(%rbp), %al
    # %al - Byte cbm_value_2
    shlb $4, %al
    # %al - Byte cbm_value = cbm_value_2 << 4
    orb LOCAL_CBM_VALUE_1(%rbp), %al
    # %al - Byte cbm_value = (cbm_value_2 << 4) | cbm_value_1

    movb LOCAL_CBM_VALUE_1(%rbp), %al
    # %al - Byte cbm_value_1
    movb %al, LOCAL_DATA+0(%rbp)
    # cbm_values[0] = cbm_value_1

    movb LOCAL_CBM_VALUE_2(%rbp), %al
    # %al - Byte cbm_value_2
    movb %al, LOCAL_DATA+1(%rbp)
    # cbm_values[1] = cbm_value_2

    movq $2, %rdi
    # %rdi - std::size_t length = 2
    leaq LOCAL_DATA(%rbp), %rsi
    # %rsi - Byte data[2]
    call new_byte_array
    # %rax - ByteArray *cbm_values

    leave
    ret
