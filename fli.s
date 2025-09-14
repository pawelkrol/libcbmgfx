.include "const.s"

.section .data

.type data_length_error_message, @object
data_length_error_message:
    .ascii "invalid data length: got $%04x, expected $%04x\n\0"

.type load_address_error_message, @object
load_address_error_message:
    .ascii "invalid load address: got $%04x, expected $%04x\n\0"

.section .text

# FLI *load_fli(
#   Byte *data,
#   uint64_t data_size,
#   FLIConfig *image_config,
# );
.globl load_fli
.type load_fli, @function

# Byte *data
.equ LOCAL_DATA_PTR, -8
# uint64_t data_size
.equ LOCAL_DATA_SIZE, -16
# FLIConfig *image_config
.equ LOCAL_IMAGE_CONFIG_PTR, -24
# uint64_t bitmap_offset
.equ LOCAL_BITMAP_OFFSET, -32
# uint64_t screens_offset
.equ LOCAL_SCREENS_OFFSET, -40
# uint64_t colours_offset
.equ LOCAL_COLOURS_OFFSET, -48
# uint64_t background_colour_offset
.equ LOCAL_BACKGROUND_COLOUR_OFFSET, -56
# uint64_t border_colour_offset
.equ LOCAL_BORDER_COLOUR_OFFSET, -64
# uint64_t screen_size_offset
.equ LOCAL_SCREEN_SIZE_OFFSET, -72

# %rdi - Byte *data
# %rsi - uint64_t data_size
# %rdx - FLIConfig *image_config
load_fli:

    # Reserve space for 9 variables (aligned to 16 bytes):
    enter $0x50, $0
    # %rdi - Byte *data
    movq %rdi, LOCAL_DATA_PTR(%rbp)
    # %rsi - uint64_t data_size
    movq %rsi, LOCAL_DATA_SIZE(%rbp)
    # %rdx - FLIConfig *image_config
    movq %rdx, LOCAL_IMAGE_CONFIG_PTR(%rbp)

    # Assert data_size == image_config->data_length:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - FLIConfig *image_config
    movq $FLI_CONFIG_DATA_LENGTH_OFFSET, %rsi
    # %rsi - uint64_t data_length_offset
    call get_fli_config_value
    # %ax - uint64_t image_config->data_length
    cmpw %ax, LOCAL_DATA_SIZE(%rbp)
    jz __load_fli_1

    leaq data_length_error_message(%rip), %rsi
    movzwq LOCAL_DATA_SIZE(%rbp), %rdx
    movzwq %ax, %rcx
    jmp throw_runtime_error

__load_fli_1:

    # Assert *(uint16_t)data == image_config->load_address:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - FLIConfig *image_config
    movq $FLI_CONFIG_LOAD_ADDRESS_OFFSET, %rsi
    # %rsi - uint64_t load_address_offset
    call get_fli_config_value
    # %ax - uint16_t image_config->load_address
    movq LOCAL_DATA_PTR(%rbp), %rdi
    cmpw %ax, (%rdi)
    jz __load_fli_2

    leaq load_address_error_message(%rip), %rsi
    movzwq (%rdi), %rdx
    movzwq %ax, %rcx
    jmp throw_runtime_error

__load_fli_2:

    # Get image_config->bitmap_offset value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - FLIConfig *image_config
    movq $FLI_CONFIG_BITMAP_DATA_OFFSET, %rsi
    # %rsi - uint64_t bitmap_data_offset
    call get_fli_config_value
    # %rax - uint64_t image_config->bitmap_offset
    movq %rax, LOCAL_BITMAP_OFFSET(%rbp)

    # Get image_config->screens_offset value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - FLIConfig *image_config
    movq $FLI_CONFIG_SCREENS_DATA_OFFSET, %rsi
    # %rsi - uint64_t screens_data_offset
    call get_fli_config_value
    # %rax - uint64_t image_config->screens_offset
    movq %rax, LOCAL_SCREENS_OFFSET(%rbp)

    # Get image_config->colours_offset value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - FLIConfig *image_config
    movq $FLI_CONFIG_COLOURS_DATA_OFFSET, %rsi
    # %rsi - uint64_t colours_data_offset
    call get_fli_config_value
    # %rax - uint64_t image_config->colours_offset
    movq %rax, LOCAL_COLOURS_OFFSET(%rbp)

    # Get image_config->background_colour_offset value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - FLIConfig *image_config
    movq $FLI_CONFIG_BACKGROUND_COLOUR_OFFSET, %rsi
    # %rsi - uint64_t background_colour_offset
    call get_fli_config_value
    # %rax - uint64_t image_config->background_colour_offset
    movq %rax, LOCAL_BACKGROUND_COLOUR_OFFSET(%rbp)

    # Get image_config->border_colour_offset value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - FLIConfig *image_config
    movq $FLI_CONFIG_BORDER_COLOUR_OFFSET, %rsi
    # %rsi - uint64_t border_colour_offset
    call get_fli_config_value
    # %rax - uint64_t image_config->border_colour_offset
    movq %rax, LOCAL_BORDER_COLOUR_OFFSET(%rbp)

    # Get image_config->screen_size value:
    movq LOCAL_IMAGE_CONFIG_PTR(%rbp), %rdi
    # %rdi - FLIConfig *image_config
    movq $FLI_CONFIG_SCREEN_SIZE_OFFSET, %rsi
    # %rsi - uint64_t screen_size_offset
    call get_fli_config_value
    # %rax - uint64_t image_config->screen_size
    movq %rax, LOCAL_SCREEN_SIZE_OFFSET(%rbp)

    # Allocate and initialise FLI object instance:
    movq LOCAL_DATA_PTR(%rbp), %rax
    # %rax - Byte *data
    movq %rax, %rdi
    addq LOCAL_BITMAP_OFFSET(%rbp), %rdi
    # %rdi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq %rax, %rsi
    addq LOCAL_SCREENS_OFFSET(%rbp), %rsi
    # %rsi - Byte screen_data[screen_size * $FLI_SCREEN_COUNT]
    movq %rax, %rdx
    addq LOCAL_COLOURS_OFFSET(%rbp), %rdx
    # %rdx - Byte colours_data[$SCREEN_DATA_LENGTH]
    movb $DEFAULT_BACKGROUND_COLOUR, %cl
    # %cl - Byte background_colour = default_background_colour (default)
    cmpw $-1, LOCAL_BACKGROUND_COLOUR_OFFSET(%rbp)
    je __load_fli_3
    movq LOCAL_BACKGROUND_COLOUR_OFFSET(%rbp), %r9
    movb (%rax, %r9), %cl
    # %cl - Byte background_colour = background_colour (custom)
__load_fli_3:
    movb %cl, %r8b
    # %r8b - Byte border_colour = background_colour (default)
    cmpw $-1, LOCAL_BORDER_COLOUR_OFFSET(%rbp)
    je __load_fli_4
    movq LOCAL_BORDER_COLOUR_OFFSET(%rbp), %r9
    movb (%rax, %r9), %r8b
    # %r8b - Byte border_colour = border_colour (custom)
__load_fli_4:
    movw LOCAL_SCREEN_SIZE_OFFSET(%rbp), %r9w
    # %r9w - uint16_t screen_size
    call new_fli
    # %rax - FLI *fli

    leave
    ret

# uint64_t get_fli_config_value(FLIConfig *image_config, uint64_t offset);
.type get_fli_config_value, @function

# %rdi - FLIConfig *image_config
# %rsi - uint64_t offset
get_fli_config_value:

    movzwq (%rdi, %rsi), %rax
    # %rax - uint64_t config_value = *(static_cast<uint16_t *>(static_cast<uint8_t *>(image_config) + offset))

    ret

# FLI *new_fli(
#   Byte *bitmap_data,
#   Byte *screen_data,
#   Byte *colours_data,
#   Byte background_colour,
#   Byte border_colour,
#   uint16_t screen_size,
# );
.globl new_fli
.type new_fli, @function

# Byte bitmap_data[$BITMAP_DATA_LENGTH]
.equ LOCAL_BITMAP_DATA_PTR, -8
# Byte screen_data[screen_size * $FLI_SCREEN_COUNT]
.equ LOCAL_SCREEN_DATA_PTR, -16
# Byte colours_data[$SCREEN_DATA_SIZE]
.equ LOCAL_COLOURS_DATA_PTR, -24
# FLI *fli
.equ LOCAL_FLI_PTR, -32
# Byte background_colour
.equ LOCAL_BACKGROUND_COLOUR, -33
# Byte border_colour
.equ LOCAL_BORDER_COLOUR, -34
# uint16_t screen_size
.equ LOCAL_SCREEN_SIZE, -36

# %rdi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
# %rsi - Byte screen_data[screen_size * $FLI_SCREEN_COUNT]
# %rdx - Byte colours_data[$SCREEN_DATA_SIZE]
# %cl - Byte background_colour
# %r8b - Byte border_colour
# %r9w - uint16_t screen_size
new_fli:

    # Reserve space for 7 variables (aligned to 16 bytes):
    enter $0x30, $0
    # %rdi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq %rdi, LOCAL_BITMAP_DATA_PTR(%rbp)
    # %rsi - Byte screen_data[screen_size * $FLI_SCREEN_COUNT]
    movq %rsi, LOCAL_SCREEN_DATA_PTR(%rbp)
    # %rdx - Byte colours_data[$SCREEN_DATA_SIZE]
    movq %rdx, LOCAL_COLOURS_DATA_PTR(%rbp)
    # %cl - Byte background_colour
    movb %cl, LOCAL_BACKGROUND_COLOUR(%rbp)
    # %r8b - Byte border_colour
    movb %r8b, LOCAL_BORDER_COLOUR(%rbp)
    # %r9w - uint16_t screen_size
    movw %r9w, LOCAL_SCREEN_SIZE(%rbp)

    # Allocate memory to store the new FLI object:
    movq $FLI_TOTAL_SIZE, %rdi
    call malloc@plt
    # %rax - FLI *fli
    movq %rax, LOCAL_FLI_PTR(%rbp)

    # Allocate and initialise the member variable - Multicolour *fli->multicolour
    movq LOCAL_BITMAP_DATA_PTR(%rbp), %rdi
    # %rdi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq LOCAL_SCREEN_DATA_PTR(%rbp), %rsi
    # %rsi - Byte screen_data[screen_size * $FLI_SCREEN_COUNT]
    movq LOCAL_COLOURS_DATA_PTR(%rbp), %rdx
    # %rdx - Byte colours_data[$SCREEN_DATA_SIZE]
    movb LOCAL_BACKGROUND_COLOUR(%rbp), %cl
    # %cl - Byte background_colour
    movb LOCAL_BORDER_COLOUR(%rbp), %r8b
    # %r8b - Byte border_colour
    movw LOCAL_SCREEN_SIZE(%rbp), %r9w
    # %r9w - uint16_t screen_size
    movq $FLI_SCREEN_COUNT, %rax
    pushq %rax
    # (%rsp)[0] - uint64_t screen_count = 8
    call new_mcp
    addq $8, %rsp
    # %rax - Multicolour *multicolour
    movq LOCAL_FLI_PTR(%rbp), %rdi
    # %rdi - FLI *fli
    movq %rax, FLI_MULTICOLOUR_PTR_OFFSET(%rdi)

    movq LOCAL_FLI_PTR(%rbp), %rax
    # %rax - FLI *fli

    leave
    ret

# void delete_fli(FLI *fli);
.globl delete_fli
.type delete_fli, @function

# FLI *fli
.equ LOCAL_FLI_PTR, -8

# %rdi - FLI *fli
delete_fli:

    # Reserve space for 1 variable (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - FLI *fli
    movq %rdi, LOCAL_FLI_PTR(%rbp)
    # Do not deallocate a null pointer:
    cmpq $0, %rdi
    jz __delete_fli_1

    # Deallocate the member variable - Multicolour *multicolour
    movq LOCAL_FLI_PTR(%rbp), %rdi
    # %rdi - FLI *fli
    call fli_get_multicolour
    # %rax - Multicolour *fli->multicolour
    movq %rax, %rdi
    # %rdi - Multicolour *fli->multicolour
    call delete_mcp

    # Deallocate the FLI object:
    movq LOCAL_FLI_PTR(%rbp), %rdi
    # %rdi - FLI *fli
    movq $FLI_TOTAL_SIZE, %rsi
    # %rsi - uint64_t length
    call free_with_zero_fill

__delete_fli_1:

    leave
    ret

# Multicolour *fli_get_multicolour(FLI *fli);
.type fli_get_multicolour, @function

# %rdi - FLI *fli
fli_get_multicolour:

    # %rdi - FLI *fli
    movq FLI_MULTICOLOUR_PTR_OFFSET(%rdi), %rax
    # %rax - Multicolour *multicolour

    ret

# Bitmap *fli_get_bitmap(FLI *fli);
.globl fli_get_bitmap
.type fli_get_bitmap, @function

# %rdi - FLI *fli
fli_get_bitmap:

    # %rdi - FLI *fli
    call fli_get_multicolour
    # %rax - Multicolour *multicolour
    movq %rax, %rdi
    # %rdi - Multicolour *multicolour
    call mcp_get_bitmap
    # %rax - Bitmap *bitmap

    ret

# Bitmap *_fli_get_bitmap(FLI *fli);
.type _fli_get_bitmap, @function

# %rdi - FLI *fli
_fli_get_bitmap:

    jmp fli_get_bitmap

# Screen *fli_get_screen(FLI *fli, std::size_t screen_index);
.globl fli_get_screen
.type fli_get_screen, @function

# %rdi - FLI *fli
# %rsi - std::size_t screen_index
fli_get_screen:

    # %rdi - FLI *fli
    call fli_get_multicolour
    # %rax - Multicolour *multicolour
    movq %rax, %rdi
    # %rdi - Multicolour *multicolour
    call mcp_get_base_image
    # %rax - BaseImage *base_image
    movq %rax, %rdi
    # %rdi - BaseImage *base_image
    # %rsi - std::size_t screen_index
    call base_image_get_screen
    # %rax - Screen *screen

    ret

# Screen *fli_get_colours(FLI *fli);
.globl fli_get_colours
.type fli_get_colours, @function

# %rdi - FLI *fli
fli_get_colours:

    # %rdi - FLI *fli
    call fli_get_multicolour
    # %rax - Multicolour *multicolour
    movq %rax, %rdi
    # %rdi - Multicolour *multicolour
    call mcp_get_colours
    # %rax - Screen *colours

    ret

# Screen *_fli_get_colours(FLI *fli);
.type _fli_get_colours, @function

# %rdi - FLI *fli
_fli_get_colours:

    jmp fli_get_colours

# Byte fli_get_background_colour(FLI *fli);
.globl fli_get_background_colour
.type fli_get_background_colour, @function

# %rdi - FLI *fli
fli_get_background_colour:

    # %rdi - FLI *fli
    call fli_get_multicolour
    # %rax - Multicolour *multicolour
    movq %rax, %rdi
    # %rdi - Multicolour *multicolour
    call mcp_get_background_colour
    # %al - Byte background_colour

    ret

# Byte _fli_get_background_colour(FLI *fli);
.type _fli_get_background_colour, @function

# %rdi - FLI *fli
_fli_get_background_colour:

    jmp fli_get_background_colour

# Byte fli_get_border_colour(FLI *fli);
.globl fli_get_border_colour
.type fli_get_border_colour, @function

# %rdi - FLI *fli
fli_get_border_colour:

    # %rdi - FLI *fli
    call fli_get_multicolour
    # %rax - Multicolour *multicolour
    movq %rax, %rdi
    # %rdi - Multicolour *multicolour
    call mcp_get_border_colour
    # %al - Byte border_colour

    ret

# Screen *fli_get_screen_at_y(FLI *fli, uint16_t y);
.type fli_get_screen_at_y, @function

# %rdi - FLI *fli
# %si - uint16_t y
fli_get_screen_at_y:

    # %rdi - FLI *fli
    andq $0x0000000000000007, %rsi
    # %rsi - std::size_t screen_index = y % 8
    jmp fli_get_screen
    # %rax - Screen *screen

# Byte fli_get_cbm_value_at_xy(
#   FLI *fli,
#   uint16_t x,
#   uint16_t y,
#   Screen *(*get_screen)(FLI *, uint16_t),
# );
# x = 0..159, y = 0..199
.globl fli_get_cbm_value_at_xy
.type fli_get_cbm_value_at_xy, @function

# FLI *fli
.equ LOCAL_FLI_PTR, -8
# Screen *(*get_screen)(FLI *, uint16_t)
.equ LOCAL_GET_SCREEN_FUN_PTR, -16
# uint16_t x
.equ LOCAL_X, -18
# uint16_t y
.equ LOCAL_Y, -20

# %rdi - FLI *fli
# %si - uint16_t x
# %dx - uint16_t y
# %rcx - Screen *(*get_screen)(FLI *, uint16_t)
fli_get_cbm_value_at_xy:

    # Reserve space for 4 variables (aligned to 16 bytes):
    enter $0x20, $0
    # %rdi - FLI *fli
    movq %rdi, LOCAL_FLI_PTR(%rbp)
    # %si - uint16_t x
    movw %si, LOCAL_X(%rbp)
    # %dx - uint16_t y
    movw %dx, LOCAL_Y(%rbp)
    # %rcx - Screen *(*get_screen)(FLI *, uint16_t)
    movq %rcx, LOCAL_GET_SCREEN_FUN_PTR(%rbp)

    movq LOCAL_FLI_PTR(%rbp), %rdi
    # %rdi - FLI *fli
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    movq LOCAL_GET_SCREEN_FUN_PTR(%rbp), %rcx
    # %rcx - Screen *(*get_screen)(FLI *, uint16_t)
    leaq _fli_get_bitmap(%rip), %r8
    # %r8 - Bitmap *(*get_bitmap)(FLI *)
    leaq _fli_get_colours(%rip), %r9
    # %r9 - Screen *(*get_colours)(FLI *)
    leaq _fli_get_background_colour(%rip), %rax
    pushq %rax
    # (%rsp)[0] - Byte(*get_background_colour)(FLI *)
    call any_get_cbm_value_at_xy
    addq $8, %rsp
    # %al - Byte value

    leave
    ret

# Byte fli_get_cbm_value_at_hires_xy(FLI *fli, uint16_t x, uint16_t y);
# x = 0..319, y = 0..199
.type fli_get_cbm_value_at_hires_xy, @function

# FLI *fli
.equ LOCAL_FLI_PTR, -8
# uint16_t x
.equ LOCAL_X, -10
# uint16_t multicolour_x
.equ LOCAL_MULTICOLOUR_X, -12
# uint16_t y
.equ LOCAL_Y, -14

# %rdi - FLI *fli
# %si - uint16_t x
# %dx - uint16_t y
fli_get_cbm_value_at_hires_xy:

    # Reserve space for 4 variables (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - FLI *fli
    movq %rdi, LOCAL_FLI_PTR(%rbp)
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

    movq LOCAL_FLI_PTR(%rbp), %rdi
    # %rdi - FLI *fli
    movw LOCAL_MULTICOLOUR_X(%rbp), %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    leaq fli_get_screen_at_y(%rip), %rcx
    # %rcx - Screen *(*fli_get_screen_at_y)(FLI *, uint16_t)
    call fli_get_cbm_value_at_xy
    # %al - Byte value

    leave
    ret
