.include "const.s"

.section .data

.type too_many_hpi_colours_error_message, @object
too_many_hpi_colours_error_message:
    .ascii "too many colours in a hires 8x8 char block at X=%d, Y=%d\n\0"

.type too_many_mcp_colours_error_message, @object
too_many_mcp_colours_error_message:
    .ascii "too many colours in a multicolour 8x8 char block at X=%d, Y=%d\n\0"

.section .text

# Hires *pix2hpi(
#   PixelMap *pixel_map,
#   bool interpolate,
# );
.globl pix2hpi
.type pix2hpi, @function

# PixelMap *pixel_map
.equ LOCAL_PIXEL_MAP_PTR, -8
# Byte bitmap_data[$BITMAP_DATA_LENGTH]
.equ LOCAL_BITMAP_DATA_PTR, -16
# Byte screen_data[$SCREEN_DATA_LENGTH]
.equ LOCAL_SCREEN_DATA_PTR, -24
# Hires *hires
.equ LOCAL_HIRES_PTR, -32
# bool interpolate
.equ LOCAL_INTERPOLATE, -33

# %rdi - PixelMap *pixel_map
# %sil - bool interpolate
pix2hpi:

    # Reserve space for 5 variables (aligned to 16 bytes):
    enter $0x30, $0
    # %rdi - PixelMap *pixel_map
    movq %rdi, LOCAL_PIXEL_MAP_PTR(%rbp)
    # %sil - bool interpolate
    movb %sil, LOCAL_INTERPOLATE(%rbp)

    # Allocate the bitmap data array - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq $BITMAP_DATA_LENGTH, %rdi
    # %rdi - uint64_t bitmap_data_length
    call malloc@plt
    # %rax - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq %rax, LOCAL_BITMAP_DATA_PTR(%rbp)

    # Allocate the screen data array - Byte screen_data[$SCREEN_DATA_LENGTH]
    movq $SCREEN_DATA_LENGTH, %rdi
    # %rdi - uint64_t screen_data_length
    call malloc@plt
    # %rax - Byte screen_data[$SCREEN_DATA_LENGTH]
    movq %rax, LOCAL_SCREEN_DATA_PTR(%rbp)

    # Iterate over the entire pixel map collecting colour data for every 8x8 block:
    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movq LOCAL_BITMAP_DATA_PTR(%rbp), %rsi
    # %rsi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq LOCAL_SCREEN_DATA_PTR(%rbp), %rdx
    # %rdx - Byte screen_data[$SCREEN_DATA_LENGTH]
    movq $0, %rcx
    # %rcx - nullptr
    leaq collect_hpi_block_colour_data(%rip), %r8
    # %r8 - void (*collect_block_colour_data)(PixelMap *, uint16_t, uint16_t, Byte *, Byte *, Byte *, Byte, bool)
    movb $-1, %r9b
    # %r9b - -1
    movzbq LOCAL_INTERPOLATE(%rbp), %rax
    pushq %rax
    # (%rsp)[0] - bool interpolate
    call for_each_char_block
    addq $8, %rsp

    movq LOCAL_BITMAP_DATA_PTR(%rbp), %rdi
    # %rdi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq LOCAL_SCREEN_DATA_PTR(%rbp), %rsi
    # %rsi - Byte screen_data[$SCREEN_DATA_SIZE]
    call new_hpi
    # %rax - Hires *hires
    movq %rax, LOCAL_HIRES_PTR(%rbp)

    # Deallocate the bitmap data array:
    movq LOCAL_BITMAP_DATA_PTR(%rbp), %rdi
    # %rdi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq $BITMAP_DATA_LENGTH, %rsi
    # %rsi - uint64_t bitmap_data_length
    call free_with_zero_fill

    # Deallocate the screen data array:
    movq LOCAL_SCREEN_DATA_PTR(%rbp), %rdi
    # %rdi - Byte screen_data[$SCREEN_DATA_LENGTH]
    movq $SCREEN_DATA_LENGTH, %rsi
    # %rsi - uint64_t screen_data_length
    call free_with_zero_fill

    movq LOCAL_HIRES_PTR(%rbp), %rax
    # %rax - Hires *hires

    leave
    ret

# Multicolour *pix2mcp(
#   PixelMap *pixel_map,
#   Byte background_colour,
#   bool interpolate,
# );
.globl pix2mcp
.type pix2mcp, @function

# PixelMap *pixel_map
.equ LOCAL_PIXEL_MAP_PTR, -8
# Byte bitmap_data[$BITMAP_DATA_LENGTH]
.equ LOCAL_BITMAP_DATA_PTR, -16
# Byte screen_data[$SCREEN_DATA_LENGTH]
.equ LOCAL_SCREEN_DATA_PTR, -24
# Byte colours_data[$SCREEN_DATA_LENGTH]
.equ LOCAL_COLOURS_DATA_PTR, -32
# Multicolour *multicolour
.equ LOCAL_MULTICOLOUR_PTR, -40
# Byte background_colour
.equ LOCAL_BACKGROUND_COLOUR, -41
# bool interpolate
.equ LOCAL_INTERPOLATE, -42

# %rdi - PixelMap *pixel_map
# %sil - Byte background_colour
# %dl - bool interpolate
pix2mcp:

    # Reserve space for 7 variables (aligned to 16 bytes):
    enter $0x30, $0
    # %rdi - PixelMap *pixel_map
    movq %rdi, LOCAL_PIXEL_MAP_PTR(%rbp)
    # %sil - Byte background_colour
    movb %sil, LOCAL_BACKGROUND_COLOUR(%rbp)
    # %dl - bool interpolate
    movb %dl, LOCAL_INTERPOLATE(%rbp)

    # Allocate the bitmap data array - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq $BITMAP_DATA_LENGTH, %rdi
    # %rdi - uint64_t bitmap_data_length
    call malloc@plt
    # %rax - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq %rax, LOCAL_BITMAP_DATA_PTR(%rbp)

    # Allocate the screen data array - Byte screen_data[$SCREEN_DATA_LENGTH]
    movq $SCREEN_DATA_LENGTH, %rdi
    # %rdi - uint64_t screen_data_length
    call malloc@plt
    # %rax - Byte screen_data[$SCREEN_DATA_LENGTH]
    movq %rax, LOCAL_SCREEN_DATA_PTR(%rbp)

    # Allocate the colours data array - Byte colours_data[$SCREEN_DATA_LENGTH]
    movq $SCREEN_DATA_LENGTH, %rdi
    # %rdi - uint64_t colours_data_length
    call malloc@plt
    # %rax - Byte colours_data[$SCREEN_DATA_LENGTH]
    movq %rax, LOCAL_COLOURS_DATA_PTR(%rbp)

    # If there has been no explicit background colour provided:
    cmpb $INCLUDE_BACKGROUND_COLOUR_COUNT, LOCAL_BACKGROUND_COLOUR(%rbp)
    jne __pix2mcp_1
    # Identify the most common colour as the image background:
    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    call identify_most_common_colour
    # %al - Byte most_common_cbm_colour
    movb %al, LOCAL_BACKGROUND_COLOUR(%rbp)
    # Byte background_colour = %al

__pix2mcp_1:

    # Iterate over the entire pixel map collecting colour data for every 8x8 block:
    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movq LOCAL_BITMAP_DATA_PTR(%rbp), %rsi
    # %rsi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq LOCAL_SCREEN_DATA_PTR(%rbp), %rdx
    # %rdx - Byte screen_data[$SCREEN_DATA_LENGTH]
    movq LOCAL_COLOURS_DATA_PTR(%rbp), %rcx
    # %rcx - Byte colours_data[$SCREEN_DATA_LENGTH]
    leaq __collect_mcp_block_colour_data(%rip), %r8
    # %r8 - void (*collect_block_colour_data)(PixelMap *, uint16_t, uint16_t, Byte *, Byte *, Byte *, Byte, bool)
    movb LOCAL_BACKGROUND_COLOUR(%rbp), %r9b
    # %r9b - Byte background_colour
    movzbq LOCAL_INTERPOLATE(%rbp), %rax
    pushq %rax
    # (%rsp)[0] - bool interpolate
    call for_each_char_block
    addq $8, %rsp

    movq LOCAL_BITMAP_DATA_PTR(%rbp), %rdi
    # %rdi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq LOCAL_SCREEN_DATA_PTR(%rbp), %rsi
    # %rsi - Byte screen_data[$SCREEN_DATA_SIZE]
    movq LOCAL_COLOURS_DATA_PTR(%rbp), %rdx
    # %rdx - Byte colours_data[$SCREEN_DATA_SIZE]
    movb LOCAL_BACKGROUND_COLOUR(%rbp), %cl
    # %cl - Byte background_colour
    movb LOCAL_BACKGROUND_COLOUR(%rbp), %r8b
    # %r8b - Byte border_colour
    movw $SCREEN_DATA_LENGTH, %r9w
    # %r9w - uint16_t screen_size
    movq $MULTICOLOUR_SCREEN_COUNT, %rax
    pushq %rax
    # (%rsp)[0] - uint64_t screen_count = 1
    call new_mcp
    addq $8, %rsp
    # %rax - Multicolour *multicolour
    movq %rax, LOCAL_MULTICOLOUR_PTR(%rbp)

    # Deallocate the bitmap data array:
    movq LOCAL_BITMAP_DATA_PTR(%rbp), %rdi
    # %rdi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq $BITMAP_DATA_LENGTH, %rsi
    # %rsi - uint64_t bitmap_data_length
    call free_with_zero_fill

    # Deallocate the screen data array:
    movq LOCAL_SCREEN_DATA_PTR(%rbp), %rdi
    # %rdi - Byte screen_data[$SCREEN_DATA_LENGTH]
    movq $SCREEN_DATA_LENGTH, %rsi
    # %rsi - uint64_t screen_data_length
    call free_with_zero_fill

    # Deallocate the colours data array:
    movq LOCAL_COLOURS_DATA_PTR(%rbp), %rdi
    # %rdi - Byte colours_data[$SCREEN_DATA_LENGTH]
    movq $SCREEN_DATA_LENGTH, %rsi
    # %rsi - uint64_t colours_data_length
    call free_with_zero_fill

    movq LOCAL_MULTICOLOUR_PTR(%rbp), %rax
    # %rax - Multicolour *multicolour

    leave
    ret

# Iterate over the entire pixel map collecting colour data for every 8x8 block:
# void for_each_char_block(
#   PixelMap *pixel_map,
#   Byte bitmap_data[$BITMAP_DATA_LENGTH],
#   Byte screen_data[$SCREEN_DATA_LENGTH],
#   Byte colours_data[$SCREEN_DATA_LENGTH],
#   void (*collect_block_colour_data)(PixelMap *, uint16_t, uint16_t, Byte *, Byte *, Byte *, Byte, bool),
#   Byte background_colour,
#   bool interpolate,
# );
.type for_each_char_block, @function

# bool interpolate
.equ LOCAL_INTERPOLATE, +16
# PixelMap *pixel_map
.equ LOCAL_PIXEL_MAP_PTR, -8
# Byte bitmap_data[$BITMAP_DATA_LENGTH]
.equ LOCAL_BITMAP_DATA_PTR, -16
# Byte screen_data[$SCREEN_DATA_LENGTH]
.equ LOCAL_SCREEN_DATA_PTR, -24
# Byte colours_data[$SCREEN_DATA_LENGTH]
.equ LOCAL_COLOURS_DATA_PTR, -32
# void (*collect_block_colour_data)(PixelMap *pixel_map, uint16_t offset_x, uint16_t offset_y, Byte *target_bitmap_data, Byte *target_screen_data, Byte *target_colours_data, Byte background_colour, bool interpolate)
.equ LOCAL_COLLECT_BLOCK_COLOUR_DATA_FUN_PTR, -40
# Byte *target_bitmap_data
.equ LOCAL_TARGET_BITMAP_DATA_PTR, -48
# Byte *target_screen_data
.equ LOCAL_TARGET_SCREEN_DATA_PTR, -56
# Byte *target_colours_data
.equ LOCAL_TARGET_COLOURS_DATA_PTR, -64
# Byte background_colour
.equ LOCAL_BACKGROUND_COLOUR, -65
# uint8_t x
.equ LOCAL_X, -66
# uint8_t y
.equ LOCAL_Y, -67
# uint16_t offset_x
.equ LOCAL_OFFSET_X, -69
# uint16_t offset_y
.equ LOCAL_OFFSET_Y, -71

# %rdi - PixelMap *pixel_map
# %rsi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
# %rdx - Byte screen_data[$SCREEN_DATA_LENGTH]
# %rcx - Byte colours_data[$SCREEN_DATA_LENGTH]
# %r8 - void (*collect_block_colour_data)(PixelMap *, uint16_t, uint16_t, Byte *, Byte *, Byte *, Byte, bool)
# %r9b - Byte background_colour
# (%rbp)[0] - bool interpolate
for_each_char_block:

    # Reserve space for 13 variables (aligned to 16 bytes):
    enter $0x50, $0
    # %rdi - PixelMap *pixel_map
    movq %rdi, LOCAL_PIXEL_MAP_PTR(%rbp)
    # %rsi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq %rsi, LOCAL_BITMAP_DATA_PTR(%rbp)
    # %rdx - Byte screen_data[$SCREEN_DATA_LENGTH]
    movq %rdx, LOCAL_SCREEN_DATA_PTR(%rbp)
    # %rcx - Byte colours_data[$SCREEN_DATA_LENGTH]
    movq %rcx, LOCAL_COLOURS_DATA_PTR(%rbp)
    # %r8 - void (*collect_block_colour_data)(PixelMap *, uint16_t, uint16_t, Byte *, Byte *, Byte *, Byte, bool)
    movq %r8, LOCAL_COLLECT_BLOCK_COLOUR_DATA_FUN_PTR(%rbp)
    # %r9b - Byte background_colour
    movb %r9b, LOCAL_BACKGROUND_COLOUR(%rbp)

    # for (uint8_t y = 0; y < SCREEN_HEIGHT; ++y) {
    #   for (uint8_t x = 0; x < SCREEN_WIDTH; ++x) {
    #     collect_block_colour_data(
    #       pixel_map,
    #       x * CHAR_WIDTH,
    #       y * CHAR_HEIGHT,
    #       bitmap_data + y * SIZE_OF_BITMAP_ROW_DATA + x * SIZE_OF_BITMAP_CHAR_DATA,
    #       screen_data + y * SIZE_OF_SCREEN_ROW_DATA + x,
    #       colours_data + y * SIZE_OF_SCREEN_ROW_DATA + x,
    #       background_colour,
    #       interpolate,
    #     );
    #   }
    # }

    movb $0, LOCAL_Y(%rbp)

__for_each_char_block_1:

    movb $0, LOCAL_X(%rbp)

__for_each_char_block_2:

    # Compute bitmap data pointer of the target 8x8 char block:
    movq LOCAL_BITMAP_DATA_PTR(%rbp), %rdi
    # %rdi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq $SIZE_OF_BITMAP_ROW_DATA, %rcx
    # %rcx - SIZE_OF_BITMAP_ROW_DATA = 320
    movzbq LOCAL_Y(%rbp), %rax
    # %rax - uint8_t y
    mulq %rcx
    # %rax - y * SIZE_OF_BITMAP_ROW_DATA = y * 320
    addq %rax, %rdi
    # %rdi - bitmap_data + y * SIZE_OF_BITMAP_ROW_DATA = bitmap_data + y * 320
    movq $SIZE_OF_BITMAP_CHAR_DATA, %rcx
    # %rcx - SIZE_OF_BITMAP_CHAR_DATA = 8
    movzbq LOCAL_X(%rbp), %rax
    # %rax - uint8_t x
    mulq %rcx
    # %rax - x * SIZE_OF_BITMAP_CHAR_DATA = x * 8
    addq %rax, %rdi
    # %rdi - bitmap_data + y * SIZE_OF_BITMAP_ROW_DATA + x * SIZE_OF_BITMAP_CHAR_DATA = bitmap_data + y * 320 + x * 8
    movq %rdi, LOCAL_TARGET_BITMAP_DATA_PTR(%rbp)
    # %rdi - Byte *target_bitmap_data

    # Initialise bitmap data of the target 8x8 char block with zeroes:
    movq LOCAL_TARGET_BITMAP_DATA_PTR(%rbp), %rdi
    movq $SIZE_OF_BITMAP_CHAR_DATA, %rcx
    movb $0, %al
    cld
    rep stosb
    # *target_bitmap_data = { 0, 0, 0, 0, 0, 0, 0, 0 };

    # Compute screen data pointer of the target 8x8 char block:
    movq LOCAL_SCREEN_DATA_PTR(%rbp), %rdi
    # %rdi - Byte screen_data[$SCREEN_DATA_LENGTH]
    movq $SIZE_OF_SCREEN_ROW_DATA, %rcx
    # %rcx - SIZE_OF_SCREEN_ROW_DATA = 40
    movzbq LOCAL_Y(%rbp), %rax
    # %rax - uint8_t y
    mulq %rcx
    # %rax - y * SIZE_OF_SCREEN_ROW_DATA = y * 40
    addq %rax, %rdi
    # %rdi - screen_data + y * SIZE_OF_SCREEN_ROW_DATA = screen_data + y * 40
    movzbq LOCAL_X(%rbp), %rax
    addq %rax, %rdi
    # %rdi - screen_data + y * SIZE_OF_SCREEN_ROW_DATA + x = screen_data + y * 40 + x
    movq %rdi, LOCAL_TARGET_SCREEN_DATA_PTR(%rbp)
    # %rdi - Byte *target_screen_data

    # Initialise screen data of the target 8x8 char block with zero:
    movq LOCAL_TARGET_SCREEN_DATA_PTR(%rbp), %rdi
    movb $0, (%rdi)
    # *target_screen_data = { 0 };

    # Skip computing and initialising target colours data if it is not required:
    cmpq $0, LOCAL_COLOURS_DATA_PTR(%rbp)
    jz __for_each_char_block_3

    # Compute colours data pointer of the target 8x8 char block:
    movq LOCAL_COLOURS_DATA_PTR(%rbp), %rdi
    # %rdi - Byte colours_data[$COLOURS_DATA_LENGTH]
    movq $SIZE_OF_SCREEN_ROW_DATA, %rcx
    # %rcx - SIZE_OF_SCREEN_ROW_DATA = 40
    movzbq LOCAL_Y(%rbp), %rax
    # %rax - uint8_t y
    mulq %rcx
    # %rax - y * SIZE_OF_SCREEN_ROW_DATA = y * 40
    addq %rax, %rdi
    # %rdi - colours_data + y * SIZE_OF_SCREEN_ROW_DATA = colours_data + y * 40
    movzbq LOCAL_X(%rbp), %rax
    addq %rax, %rdi
    # %rdi - colours_data + y * SIZE_OF_SCREEN_ROW_DATA + x = colours_data + y * 40 + x
    movq %rdi, LOCAL_TARGET_COLOURS_DATA_PTR(%rbp)
    # %rdi - Byte *target_colours_data

    # Initialise colours data of the target 8x8 char block with zero:
    movq LOCAL_TARGET_COLOURS_DATA_PTR(%rbp), %rdi
    movb $0, (%rdi)
    # *target_colours_data = { 0 };

__for_each_char_block_3:

    # Compute offset X of the source data in the pixel map:
    movzbw LOCAL_X(%rbp), %ax
    # %al - uint8_t x
    movw $CHAR_WIDTH, %cx
    # %cx - uint16_t char_width
    mulw %cx
    # %dx:%ax - uint16_t offset_x = x * char_width
    movw %ax, LOCAL_OFFSET_X(%rbp)

    # Compute offset Y of the source data in the pixel map:
    movzbw LOCAL_Y(%rbp), %ax
    # %al - uint8_t y
    movw $CHAR_HEIGHT, %cx
    # %cx - uint16_t char_height
    mulw %cx
    # %dx:%ax - uint16_t offset_y = y * char_height
    movw %ax, LOCAL_OFFSET_Y(%rbp)

    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movw LOCAL_OFFSET_X(%rbp), %si
    # %si - uint16_t offset_x
    movw LOCAL_OFFSET_Y(%rbp), %dx
    # %dx - uint16_t offset_y
    movq LOCAL_TARGET_BITMAP_DATA_PTR(%rbp), %rcx
    # %rcx - Byte *target_bitmap_data
    movq LOCAL_TARGET_SCREEN_DATA_PTR(%rbp), %r8
    # %r8 - Byte *target_screen_data
    movq LOCAL_TARGET_COLOURS_DATA_PTR(%rbp), %r9
    # %r9 - Byte *target_colours_data
    movzbq LOCAL_INTERPOLATE(%rbp), %rax
    pushq %rax
    # (%rsp)[1] - bool interpolate
    movzbq LOCAL_BACKGROUND_COLOUR(%rbp), %rax
    pushq %rax
    # (%rsp)[0] - Byte background_colour
    call *LOCAL_COLLECT_BLOCK_COLOUR_DATA_FUN_PTR(%rbp)
    addq $16, %rsp

    incb LOCAL_X(%rbp)
    cmpb $SCREEN_WIDTH, LOCAL_X(%rbp)
    jb __for_each_char_block_2

    incb LOCAL_Y(%rbp)
    cmpb $SCREEN_HEIGHT, LOCAL_Y(%rbp)
    jb __for_each_char_block_1

    leave
    ret

# void collect_hpi_block_colour_data(
#   PixelMap *pixel_map,
#   uint16_t offset_x,
#   uint16_t offset_y,
#   Byte *target_bitmap_data,
#   Byte *target_screen_data,
#   Byte *target_colours_data,
#   Byte background_colour,
#   bool interpolate,
# );

# bool interpolate
.equ LOCAL_INTERPOLATE, +24
# PixelMap *pixel_map
.equ LOCAL_PIXEL_MAP_PTR, -8
# Byte *target_bitmap_data
.equ LOCAL_TARGET_BITMAP_DATA_PTR, -16
# Byte *target_screen_data
.equ LOCAL_TARGET_SCREEN_DATA_PTR, -24
# uint16_t offset_x
.equ LOCAL_OFFSET_X, -26
# uint16_t offset_y
.equ LOCAL_OFFSET_Y, -28
# Byte most_frequent_colours[2]
.equ LOCAL_MOST_FREQUENT_COLOURS, -30
# uint16_t i
.equ LOCAL_I, -32
# uint16_t j
.equ LOCAL_J, -34
# Byte accepted_interpolate_colours[2]
.equ LOCAL_ACCEPTED_INTERPOLATE_COLOURS, -36
# uint16_t x
.equ LOCAL_X, -38
# uint16_t y
.equ LOCAL_Y, -40
# Byte bitmap_byte
.equ LOCAL_BITMAP_BYTE, -41
# Byte cbm_value
.equ LOCAL_CBM_VALUE, -42

# %rdi - PixelMap *pixel_map
# %si - uint16_t offset_x
# %dx - uint16_t offset_y
# %rcx - Byte *target_bitmap_data
# %r8 - Byte *target_screen_data
# %r9 - Byte *target_colours_data
# (%rbp)[0] - Byte background_colour
# (%rsp)[1] - bool interpolate
collect_hpi_block_colour_data:

    # Reserve space for 13 variables (aligned to 16 bytes):
    enter $0x30, $0
    # %rdi - PixelMap *pixel_map
    movq %rdi, LOCAL_PIXEL_MAP_PTR(%rbp)
    # %si - uint16_t offset_x
    movw %si, LOCAL_OFFSET_X(%rbp)
    # %dx - uint16_t offset_y
    movw %dx, LOCAL_OFFSET_Y(%rbp)
    # %rcx - Byte *target_bitmap_data
    movq %rcx, LOCAL_TARGET_BITMAP_DATA_PTR(%rbp)
    # %r8 - Byte *target_screen_data
    movq %r8, LOCAL_TARGET_SCREEN_DATA_PTR(%rbp)

    # Iterate over all pixels and collect 2 most frequent colours:

    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movw LOCAL_OFFSET_X(%rbp), %si
    # %si - uint16_t offset_x
    movw LOCAL_OFFSET_Y(%rbp), %dx
    # %dx - uint16_t offset_y
    movw $CHAR_WIDTH, %cx
    # %cx - uint16_t length_x
    movw $CHAR_HEIGHT, %r8w
    # %r8w - uint16_t length_y
    leaq LOCAL_MOST_FREQUENT_COLOURS(%rbp), %r9
    # %r9 - Byte most_frequent_colours[max_count]
    movq $1, %rax
    pushq %rax
    # (%rbp)[2] - uint16_t increment_x
    movq $INCLUDE_BACKGROUND_COLOUR_COUNT, %rax
    pushq %rax
    # (%rbp)[1] - Byte background_colour
    movq $2, %rax
    pushq %rax
    # (%rbp)[0] - uint8_t max_count
    call collect_most_frequent_colours
    addq $24, %rsp

    # Assume the following pixel colour mapping:
    #
    # most_frequent_colours[0]
    # bit = "0": Colour from bits 0-3 of screen memory
    #
    # most_frequent_colours[1]
    # bit = "1": Colour from bits 4-7 of screen memory

    # Fill target screen data:

    movq $1, %rcx
    movb LOCAL_MOST_FREQUENT_COLOURS(%rbp, %rcx), %al
    # %al - most_frequent_colours[1]
    shlb $4, %al
    # %al - most_frequent_colours[1] << 4
    movq $0, %rcx
    orb LOCAL_MOST_FREQUENT_COLOURS(%rbp, %rcx), %al
    # %al - (most_frequent_colours[1] << 4) | most_frequent_colours[0]
    movq LOCAL_TARGET_SCREEN_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *target_screen_data
    movb %al, (%rdi)
    # *target_screen_data = (most_frequent_colours[1] << 4) | most_frequent_colours[0]

    # Fill target bitmap data:

    movw $0, LOCAL_I(%rbp)

__collect_hpi_block_colour_data_1:

    movb $0, LOCAL_BITMAP_BYTE(%rbp)

    movw $0, LOCAL_J(%rbp)

__collect_hpi_block_colour_data_2:

    shlb $1, LOCAL_BITMAP_BYTE(%rbp)

    movw LOCAL_OFFSET_X(%rbp), %ax
    # %ax - uint16_t offset_x
    addw LOCAL_J(%rbp), %ax
    # %ax - uint16_t x = offset_x + j
    movw %ax, LOCAL_X(%rbp)

    movw LOCAL_OFFSET_Y(%rbp), %ax
    # %ax - uint16_t offset_y
    addw LOCAL_I(%rbp), %ax
    # %ax - uint16_t y = offset_y + i
    movw %ax, LOCAL_Y(%rbp)

    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call pix_get_cbm_colour_at
    # %al - Byte cbm_value
    movb %al, LOCAL_CBM_VALUE(%rbp)

__collect_hpi_block_colour_data_6:

    movq $0, %rcx
    movb LOCAL_MOST_FREQUENT_COLOURS(%rbp, %rcx), %al
    # %al - most_frequent_colours[0]
    cmpb %al, LOCAL_CBM_VALUE(%rbp)
    # most_frequent_colours[0] == cbm_value
    je __collect_hpi_block_colour_data_4

    movq $1, %rcx
    movb LOCAL_MOST_FREQUENT_COLOURS(%rbp, %rcx), %al
    # %al - most_frequent_colours[1]
    cmpb %al, LOCAL_CBM_VALUE(%rbp)
    # most_frequent_colours[1] == cbm_value
    jne __collect_hpi_block_colour_data_3

    orb $0b00000001, LOCAL_BITMAP_BYTE(%rbp)
    # Byte bitmap_byte |= 0x01
    jmp __collect_hpi_block_colour_data_4

__collect_hpi_block_colour_data_3:

    # Optionally interpolate extraneous pixel colours:
    cmpb $0, LOCAL_INTERPOLATE(%rbp)
    jnz __collect_hpi_block_colour_data_5

    leaq too_many_hpi_colours_error_message(%rip), %rsi
    movzwq LOCAL_OFFSET_X(%rbp), %rdx
    movzwq LOCAL_OFFSET_Y(%rbp), %rcx
    jmp throw_runtime_error

__collect_hpi_block_colour_data_5:

    # Set up accepted interpolate colours array (most frequent colours):

    leaq LOCAL_ACCEPTED_INTERPOLATE_COLOURS(%rbp), %rdi
    # %rdi - Byte accepted_interpolate_colours[2]
    leaq LOCAL_MOST_FREQUENT_COLOURS(%rbp), %rsi
    # %rsi - Byte most_frequent_colours[2]
    movq $2, %rcx
    cld
    rep movsb
    # accepted_interpolate_colours[0..1] = most_frequent_colours[0..1]

    # Interpolate additional colour to an existing one:
    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    leaq LOCAL_ACCEPTED_INTERPOLATE_COLOURS(%rbp), %rcx
    # %rcx - Byte accepted_interpolate_colours[max_count]
    movb $2, %r8b
    # %r8b - uint8_t max_count
    call interpolate_rgb_colour
    # %al - Byte cbm_value
    movb %al, LOCAL_CBM_VALUE(%rbp)

    jmp __collect_hpi_block_colour_data_6

__collect_hpi_block_colour_data_4:

    addw $1, LOCAL_J(%rbp)
    cmpw $CHAR_WIDTH, LOCAL_J(%rbp)
    jb __collect_hpi_block_colour_data_2

    movq LOCAL_TARGET_BITMAP_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *target_bitmap_data
    movzwq LOCAL_I(%rbp), %rcx
    # %rcx - uint64_t bitmap_offset
    movb LOCAL_BITMAP_BYTE(%rbp), %al
    # %al - Byte bitmap_byte
    movb %al, (%rdi, %rcx)
    # *(target_bitmap_data + bitmap_offset) = bitmap_byte

    incw LOCAL_I(%rbp)
    cmpw $CHAR_HEIGHT, LOCAL_I(%rbp)
    jb __collect_hpi_block_colour_data_1

    leave
    ret

# void collect_mcp_block_colour_data(
#   PixelMap *pixel_map,
#   uint16_t offset_x,
#   uint16_t offset_y,
#   Byte *target_bitmap_data,
#   Byte *target_screen_data,
#   Byte *target_colours_data,
#   Byte background_colour,
#   bool interpolate,
# );
.globl collect_mcp_block_colour_data
.type collect_mcp_block_colour_data, @function

# bool interpolate
.equ LOCAL_INTERPOLATE, +24
# Byte background_colour
.equ LOCAL_BACKGROUND_COLOUR, +16
# PixelMap *pixel_map
.equ LOCAL_PIXEL_MAP_PTR, -8
# Byte *target_bitmap_data
.equ LOCAL_TARGET_BITMAP_DATA_PTR, -16
# Byte *target_screen_data
.equ LOCAL_TARGET_SCREEN_DATA_PTR, -24
# Byte *target_colours_data
.equ LOCAL_TARGET_COLOURS_DATA_PTR, -32
# uint16_t offset_x
.equ LOCAL_OFFSET_X, -34
# uint16_t offset_y
.equ LOCAL_OFFSET_Y, -36
# Byte most_frequent_colours[3]
.equ LOCAL_MOST_FREQUENT_COLOURS, -39
# Byte accepted_interpolate_colours[4]
.equ LOCAL_ACCEPTED_INTERPOLATE_COLOURS, -43
# uint16_t i
.equ LOCAL_I, -45
# uint16_t j
.equ LOCAL_J, -47
# Byte bitmap_byte
.equ LOCAL_BITMAP_BYTE, -48
# uint16_t x
.equ LOCAL_X, -50
# uint16_t y
.equ LOCAL_Y, -52
# Byte cbm_value
.equ LOCAL_CBM_VALUE, -53

# %rdi - PixelMap *pixel_map
# %si - uint16_t offset_x
# %dx - uint16_t offset_y
# %rcx - Byte *target_bitmap_data
# %r8 - Byte *target_screen_data
# %r9 - Byte *target_colours_data
# (%rbp)[0] - Byte background_colour
# (%rsp)[1] - bool interpolate
collect_mcp_block_colour_data:

    # Reserve space for 14 variables (aligned to 16 bytes):
    enter $0x40, $0
    # %rdi - PixelMap *pixel_map
    movq %rdi, LOCAL_PIXEL_MAP_PTR(%rbp)
    # %si - uint16_t offset_x
    movw %si, LOCAL_OFFSET_X(%rbp)
    # %dx - uint16_t offset_y
    movw %dx, LOCAL_OFFSET_Y(%rbp)
    # %rcx - Byte *target_bitmap_data
    movq %rcx, LOCAL_TARGET_BITMAP_DATA_PTR(%rbp)
    # %r8 - Byte *target_screen_data
    movq %r8, LOCAL_TARGET_SCREEN_DATA_PTR(%rbp)
    # %r9 - Byte *target_colours_data
    movq %r9, LOCAL_TARGET_COLOURS_DATA_PTR(%rbp)

    # Iterate over all pixels and collect 3 most frequent colours:

    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movw LOCAL_OFFSET_X(%rbp), %si
    # %si - uint16_t offset_x
    movw LOCAL_OFFSET_Y(%rbp), %dx
    # %dx - uint16_t offset_y
    movw $CHAR_WIDTH, %cx
    # %cx - uint16_t length_x
    movw $CHAR_HEIGHT, %r8w
    # %r8w - uint16_t length_y
    leaq LOCAL_MOST_FREQUENT_COLOURS(%rbp), %r9
    # %r9 - Byte most_frequent_colours[max_count]
    movq $2, %rax
    pushq %rax
    # (%rbp)[2] - uint16_t increment_x
    movq LOCAL_BACKGROUND_COLOUR(%rbp), %rax
    pushq %rax
    # (%rbp)[1] - Byte background_colour
    movq $3, %rax
    pushq %rax
    # (%rbp)[0] - uint8_t max_count
    call collect_most_frequent_colours
    addq $24, %rsp

    # Assume the following pixel colour mapping:
    #
    # most_frequent_colours[0]
    # bits = "01": Colour from bits 4-7 of screen memory
    #
    # most_frequent_colours[1]
    # bits = "10": Colour from bits 0-3 of screen memory
    #
    # most_frequent_colours[2]
    # bits = "11": Colour from bits 8-11 of colour memory
    #
    # background_colour
    # bits = "00": Colour from background register $d021

    # Fill target screen data:

    movq $0, %rcx
    movb LOCAL_MOST_FREQUENT_COLOURS(%rbp, %rcx), %al
    # %al - most_frequent_colours[0]
    shlb $4, %al
    # %al - most_frequent_colours[0] << 4
    movq $1, %rcx
    orb LOCAL_MOST_FREQUENT_COLOURS(%rbp, %rcx), %al
    # %al - (most_frequent_colours[0] << 4) | most_frequent_colours[1]
    movq LOCAL_TARGET_SCREEN_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *target_screen_data
    movb %al, (%rdi)
    # *target_screen_data = (most_frequent_colours[0] << 4) | most_frequent_colours[1]

    # Fill target colours data:

    movq $2, %rcx
    movb LOCAL_MOST_FREQUENT_COLOURS(%rbp, %rcx), %al
    # %al - most_frequent_colours[2]
    movq LOCAL_TARGET_COLOURS_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *target_colours_data
    movb %al, (%rdi)
    # *target_colours_data = most_frequent_colours[2]

    # Fill target bitmap data:

    movw $0, LOCAL_I(%rbp)

__collect_mcp_block_colour_data_1:

    movb $0, LOCAL_BITMAP_BYTE(%rbp)

    movw $0, LOCAL_J(%rbp)

__collect_mcp_block_colour_data_2:

    shlb $2, LOCAL_BITMAP_BYTE(%rbp)

    movw LOCAL_OFFSET_X(%rbp), %ax
    # %ax - uint16_t offset_x
    addw LOCAL_J(%rbp), %ax
    # %ax - uint16_t x = offset_x + j
    movw %ax, LOCAL_X(%rbp)

    movw LOCAL_OFFSET_Y(%rbp), %ax
    # %ax - uint16_t offset_y
    addw LOCAL_I(%rbp), %ax
    # %ax - uint16_t y = offset_y + i
    movw %ax, LOCAL_Y(%rbp)

    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call pix_get_cbm_colour_at
    # %al - Byte cbm_value
    movb %al, LOCAL_CBM_VALUE(%rbp)

__collect_mcp_block_colour_data_8:

    movq $0, %rcx
    movb LOCAL_MOST_FREQUENT_COLOURS(%rbp, %rcx), %al
    # %al - most_frequent_colours[0]
    cmpb %al, LOCAL_CBM_VALUE(%rbp)
    # most_frequent_colours[0] == cbm_value
    jne __collect_mcp_block_colour_data_3

    cmpb %al, LOCAL_BACKGROUND_COLOUR(%rbp)
    # most_frequent_colours[0] == background_colour
    je __collect_mcp_block_colour_data_6

    orb $0b00000001, LOCAL_BITMAP_BYTE(%rbp)
    # Byte bitmap_byte |= 0x01
    jmp __collect_mcp_block_colour_data_6

__collect_mcp_block_colour_data_3:

    movq $1, %rcx
    movb LOCAL_MOST_FREQUENT_COLOURS(%rbp, %rcx), %al
    # %al - most_frequent_colours[1]
    cmpb %al, LOCAL_CBM_VALUE(%rbp)
    # most_frequent_colours[1] == cbm_value
    jne __collect_mcp_block_colour_data_4

    cmpb %al, LOCAL_BACKGROUND_COLOUR(%rbp)
    # most_frequent_colours[1] == background_colour
    je __collect_mcp_block_colour_data_6

    orb $0b00000010, LOCAL_BITMAP_BYTE(%rbp)
    # Byte bitmap_byte |= 0x02
    jmp __collect_mcp_block_colour_data_6

__collect_mcp_block_colour_data_4:

    movq $2, %rcx
    movb LOCAL_MOST_FREQUENT_COLOURS(%rbp, %rcx), %al
    # %al - most_frequent_colours[2]
    cmpb %al, LOCAL_CBM_VALUE(%rbp)
    # most_frequent_colours[2] == cbm_value
    jne __collect_mcp_block_colour_data_5

    cmpb %al, LOCAL_BACKGROUND_COLOUR(%rbp)
    # most_frequent_colours[2] == background_colour
    je __collect_mcp_block_colour_data_6

    orb $0b00000011, LOCAL_BITMAP_BYTE(%rbp)
    # Byte bitmap_byte |= 0x03
    jmp __collect_mcp_block_colour_data_6

__collect_mcp_block_colour_data_5:

    movb LOCAL_BACKGROUND_COLOUR(%rbp), %al
    # %al - background_colour
    cmpb %al, LOCAL_CBM_VALUE(%rbp)
    # background_colour == cbm_value
    je __collect_mcp_block_colour_data_6

    # Optionally interpolate extraneous pixel colours:
    cmpb $0, LOCAL_INTERPOLATE(%rbp)
    jnz __collect_mcp_block_colour_data_7

    leaq too_many_mcp_colours_error_message(%rip), %rsi
    movzwq LOCAL_OFFSET_X(%rbp), %rdx
    movzwq LOCAL_OFFSET_Y(%rbp), %rcx
    jmp throw_runtime_error

__collect_mcp_block_colour_data_7:

    # Set up accepted interpolate colours array (most frequent colours + background colour):

    leaq LOCAL_ACCEPTED_INTERPOLATE_COLOURS(%rbp), %rdi
    # %rdi - Byte accepted_interpolate_colours[4]
    leaq LOCAL_MOST_FREQUENT_COLOURS(%rbp), %rsi
    # %rsi - Byte most_frequent_colours[3]
    movq $3, %rcx
    cld
    rep movsb
    # accepted_interpolate_colours[0..2] = most_frequent_colours[0..2]

    leaq LOCAL_ACCEPTED_INTERPOLATE_COLOURS(%rbp), %rdi
    # %rdi - Byte accepted_interpolate_colours[4]
    movb LOCAL_BACKGROUND_COLOUR(%rbp), %al
    # %al - Byte background_colour
    movq $3, %rcx
    movb %al, (%rdi, %rcx)
    # accepted_interpolate_colours[3] = background_colour

    # Interpolate additional colour to an existing one:
    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    leaq LOCAL_ACCEPTED_INTERPOLATE_COLOURS(%rbp), %rcx
    # %rcx - Byte accepted_interpolate_colours[max_count]
    movb $4, %r8b
    # %r8b - uint8_t max_count
    call interpolate_rgb_colour
    # %al - Byte cbm_value
    movb %al, LOCAL_CBM_VALUE(%rbp)

    jmp __collect_mcp_block_colour_data_8

__collect_mcp_block_colour_data_6:

    addw $2, LOCAL_J(%rbp)
    cmpw $CHAR_WIDTH, LOCAL_J(%rbp)
    jb __collect_mcp_block_colour_data_2

    movq LOCAL_TARGET_BITMAP_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *target_bitmap_data
    movzwq LOCAL_I(%rbp), %rcx
    # %rcx - uint64_t bitmap_offset
    movb LOCAL_BITMAP_BYTE(%rbp), %al
    # %al - Byte bitmap_byte
    movb %al, (%rdi, %rcx)
    # *(target_bitmap_data + bitmap_offset) = bitmap_byte

    incw LOCAL_I(%rbp)
    cmpw $CHAR_HEIGHT, LOCAL_I(%rbp)
    jb __collect_mcp_block_colour_data_1

    leave
    ret

# void __collect_mcp_block_colour_data(
#   PixelMap *pixel_map,
#   uint16_t offset_x,
#   uint16_t offset_y,
#   Byte *target_bitmap_data,
#   Byte *target_screen_data,
#   Byte *target_colours_data,
#   Byte background_colour,
#   bool interpolate,
# );
.type __collect_mcp_block_colour_data, @function

# %rdi - PixelMap *pixel_map
# %si - uint16_t offset_x
# %dx - uint16_t offset_y
# %rcx - Byte *target_bitmap_data
# %r8 - Byte *target_screen_data
# %r9 - Byte *target_colours_data
# (%rbp)[0] - Byte background_colour
# (%rsp)[1] - bool interpolate
__collect_mcp_block_colour_data:

    jmp collect_mcp_block_colour_data

# void collect_most_frequent_colours(
#   PixelMap *pixel_map,
#   uint16_t offset_x,
#   uint16_t offset_y,
#   uint16_t length_x,
#   uint16_t length_y,
#   Byte most_frequent_colours[max_count],
#   uint8_t max_count,
#   Byte background_colour,
#   uint16_t increment_x,
# );
.globl collect_most_frequent_colours
.type collect_most_frequent_colours, @function

# uint16_t increment_x
.equ LOCAL_INCREMENT_X, +32
# Byte background_colour
.equ LOCAL_BACKGROUND_COLOUR, +24
# uint8_t max_count
.equ LOCAL_MAX_COUNT, +16
# PixelMap *pixel_map
.equ LOCAL_PIXEL_MAP_PTR, -8
# Byte most_frequent_colours[max_count]
.equ LOCAL_MOST_FREQUENT_COLOURS_PTR, -16
# uint16_t indexed_colour_counts[CBM_COLOUR_COUNT]
.equ LOCAL_INDEXED_COLOUR_COUNTS_PTR, -24
# uint8_t sorted_colour_indexes[CBM_COLOUR_COUNT]
.equ LOCAL_SORTED_COLOUR_INDEXES_PTR, -32
# uint16_t offset_x
.equ LOCAL_OFFSET_X, -34
# uint16_t offset_y
.equ LOCAL_OFFSET_Y, -36
# uint16_t length_x
.equ LOCAL_LENGTH_X, -38
# uint16_t length_y
.equ LOCAL_LENGTH_Y, -40
# uint16_t indexed_colour_counts_size
.equ LOCAL_INDEXED_COLOUR_COUNTS_SIZE, -42
# uint16_t i
.equ LOCAL_I, -44
# uint16_t j
.equ LOCAL_J, -46
# uint16_t x
.equ LOCAL_X, -48
# uint16_t y
.equ LOCAL_Y, -50
# Byte cbm_value
.equ LOCAL_CBM_VALUE, -51

# %rdi - PixelMap *pixel_map
# %si - uint16_t offset_x
# %dx - uint16_t offset_y
# %cx - uint16_t length_x
# %r8w - uint16_t length_y
# %r9 - Byte most_frequent_colours[max_count]
# (%rbp)[0] - uint8_t max_count
# (%rbp)[1] - Byte background_colour
# (%rbp)[2] - uint16_t increment_x
collect_most_frequent_colours:

    # Reserve space for 14 variables (aligned to 16 bytes):
    enter $0x40, $0
    # %rdi - PixelMap *pixel_map
    movq %rdi, LOCAL_PIXEL_MAP_PTR(%rbp)
    # %si - uint16_t offset_x
    movw %si, LOCAL_OFFSET_X(%rbp)
    # %dx - uint16_t offset_y
    movw %dx, LOCAL_OFFSET_Y(%rbp)
    # %cx - uint16_t length_x
    movw %cx, LOCAL_LENGTH_X(%rbp)
    # %r8w - uint16_t length_y
    movw %r8w, LOCAL_LENGTH_Y(%rbp)
    # %r9 - Byte most_frequent_colours[max_count]
    movq %r9, LOCAL_MOST_FREQUENT_COLOURS_PTR(%rbp)

    # Store indexed colour occurrence counts as uint16_t's:
    movw $CBM_COLOUR_COUNT, %ax
    movw $INDEXED_COLOUR_COUNT_SIZE, %cx
    mulw %cx
    # %ax = CBM_COLOUR_COUNT * INDEXED_COLOUR_COUNT_SIZE
    movw %ax, LOCAL_INDEXED_COLOUR_COUNTS_SIZE(%rbp)

    # Allocate memory to store indexed colour occurrence counts:
    movzwq LOCAL_INDEXED_COLOUR_COUNTS_SIZE(%rbp), %rdi
    call malloc@plt
    # %rax - uint16_t indexed_colour_counts[CBM_COLOUR_COUNT]
    movq %rax, LOCAL_INDEXED_COLOUR_COUNTS_PTR(%rbp)

    # Initialise indexed colour occurrence counts with zeroes:
    movq LOCAL_INDEXED_COLOUR_COUNTS_PTR(%rbp), %rdi
    movzwq LOCAL_INDEXED_COLOUR_COUNTS_SIZE(%rbp), %rcx
    movb $0, %al
    cld
    rep stosb

    # Allocate memory to store colour indexes while sorting:
    movq $CBM_COLOUR_COUNT, %rdi
    call malloc@plt
    # %rax - uint8_t sorted_colour_indexes[CBM_COLOUR_COUNT]
    movq %rax, LOCAL_SORTED_COLOUR_INDEXES_PTR(%rbp)

    # Initialise colour indexes with values before sorting:

    movw $0, LOCAL_I(%rbp)

__collect_most_frequent_colours_6:

    movzwq LOCAL_I(%rbp), %rcx
    # %rcx - uint16_t i
    movq LOCAL_SORTED_COLOUR_INDEXES_PTR(%rbp), %rdi
    # %rdi - uint8_t sorted_colour_indexes[CBM_COLOUR_COUNT]
    movb %cl, (%rdi, %rcx)
    # sorted_colour_indexes[i] = i

    incw LOCAL_I(%rbp)
    cmpw $CBM_COLOUR_COUNT, LOCAL_I(%rbp)
    jb __collect_most_frequent_colours_6

    # for (uint16_t i = 0; i < length_x; i = i + increment_x) {
    #   for (uint16_t j = 0; j < length_y; ++j) {
    #     uint16_t x = offset_x + i;
    #     uint16_t y = offset_y + j;
    #     Byte cbm_colour = pix_get_cbm_colour_at(pixel_map, x, y);
    #     if (background_colour == 0xff || cbm_colour != background_colour) {
    #       indexed_colour_counts[cbm_colour] += 1;
    #     }
    #   }
    # }

    movw $0, LOCAL_I(%rbp)

__collect_most_frequent_colours_1:

    movw $0, LOCAL_J(%rbp)

__collect_most_frequent_colours_2:

    movw LOCAL_OFFSET_X(%rbp), %ax
    # %ax - uint16_t offset_x
    addw LOCAL_I(%rbp), %ax
    # %ax - uint16_t x = offset_x + i
    movw %ax, LOCAL_X(%rbp)

    movw LOCAL_OFFSET_Y(%rbp), %ax
    # %ax - uint16_t offset_y
    addw LOCAL_J(%rbp), %ax
    # %ax - uint16_t y = offset_y + j
    movw %ax, LOCAL_Y(%rbp)

    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call pix_get_cbm_colour_at
    # %al - Byte cbm_value
    movb %al, LOCAL_CBM_VALUE(%rbp)

    cmpb $INCLUDE_BACKGROUND_COLOUR_COUNT, LOCAL_BACKGROUND_COLOUR(%rbp)
    je __collect_most_frequent_colours_3

    movb LOCAL_CBM_VALUE(%rbp), %al
    # %al - Byte cbm_value
    cmpb LOCAL_BACKGROUND_COLOUR(%rbp), %al
    je __collect_most_frequent_colours_4

__collect_most_frequent_colours_3:

    movq LOCAL_INDEXED_COLOUR_COUNTS_PTR(%rbp), %rdi
    # %rdi - uint16_t indexed_colour_counts[CBM_COLOUR_COUNT]
    movzbq LOCAL_CBM_VALUE(%rbp), %rcx
    # %rcx - Byte cbm_value
    incw (%rdi, %rcx, INDEXED_COLOUR_COUNT_SIZE)
    # indexed_colour_counts[cbm_value] += 1

__collect_most_frequent_colours_4:

    incw LOCAL_J(%rbp)
    movw LOCAL_LENGTH_Y(%rbp), %ax
    cmpw %ax, LOCAL_J(%rbp)
    jb __collect_most_frequent_colours_2

    movw LOCAL_INCREMENT_X(%rbp), %ax
    addw %ax, LOCAL_I(%rbp)
    movw LOCAL_LENGTH_X(%rbp), %ax
    cmpw %ax, LOCAL_I(%rbp)
    jb __collect_most_frequent_colours_1

    # Sort counted colour frequencies:
    movq LOCAL_INDEXED_COLOUR_COUNTS_PTR(%rbp), %rdi
    # %rdi - uint16_t indexed_colour_counts[CBM_COLOUR_COUNT]
    movq LOCAL_SORTED_COLOUR_INDEXES_PTR(%rbp), %rsi
    # %rsi - uint8_t sorted_colour_indexes[CBM_COLOUR_COUNT]
    movq $0, %rdx
    # %rdx - uint64_t low = 0
    movq $CBM_COLOUR_COUNT, %rcx
    subq $1, %rcx
    # %rcx - uint64_t high = CBM_COLOUR_COUNT - 1
    call sort_colour_count_frequencies

    # Copy "max_count" results to "most_frequent_colours":
    movzwq LOCAL_I(%rbp), %rcx
    # %rcx - uint16_t i
    movq LOCAL_SORTED_COLOUR_INDEXES_PTR(%rbp), %rsi
    # %rsi - uint8_t sorted_colour_indexes[CBM_COLOUR_COUNT]
    movq LOCAL_MOST_FREQUENT_COLOURS_PTR(%rbp), %rdi
    # %rdi - Byte most_frequent_colours[max_count]
    movzbq LOCAL_MAX_COUNT(%rbp), %rcx
    # %rcx - uint8_t max_count
    # for (1 .. max_count) {
    #   most_frequent_colours[i] = sorted_colour_indexes[i];
    # }
    cld
    rep movsb

    # Replace all results with a zero count with a background colour:

    movw $0, LOCAL_I(%rbp)

__collect_most_frequent_colours_5:

    movzwq LOCAL_I(%rbp), %rcx
    # %rcx - uint16_t i
    movq LOCAL_INDEXED_COLOUR_COUNTS_PTR(%rbp), %rdi
    # %rdi - uint16_t indexed_colour_counts[CBM_COLOUR_COUNT]
    cmpw $0, (%rdi, %rcx, INDEXED_COLOUR_COUNT_SIZE)
    # indexed_colour_counts[i] == 0
    jnz __collect_most_frequent_colours_7

    movzwq LOCAL_I(%rbp), %rcx
    # %rcx - uint16_t i
    movq LOCAL_MOST_FREQUENT_COLOURS_PTR(%rbp), %rdi
    # %rdi - Byte most_frequent_colours[max_count]
    movb LOCAL_BACKGROUND_COLOUR(%rbp), %al
    # %al - Byte background_colour
    movb %al, (%rdi, %rcx)
    # most_frequent_colours[i] = background_colour

__collect_most_frequent_colours_7:

    incw LOCAL_I(%rbp)
    movw LOCAL_I(%rbp), %ax
    cmpw LOCAL_MAX_COUNT(%rbp), %ax
    jb __collect_most_frequent_colours_5

    # Deallocate an array of indexed colour occurrence counts:
    movq LOCAL_INDEXED_COLOUR_COUNTS_PTR(%rbp), %rdi
    # %rdi - uint16_t indexed_colour_counts[CBM_COLOUR_COUNT]
    movzwq LOCAL_INDEXED_COLOUR_COUNTS_SIZE(%rbp), %rsi
    # %rsi - uint64_t length
    call free_with_zero_fill

    # Deallocate an array of sorted colour indexes:
    movq LOCAL_SORTED_COLOUR_INDEXES_PTR(%rbp), %rdi
    # %rdi - uint8_t sorted_colour_indexes[CBM_COLOUR_COUNT]
    movq $CBM_COLOUR_COUNT, %rsi
    # %rsi - uint64_t length
    call free_with_zero_fill

    leave
    ret

# void sort_colour_count_frequencies(
#   uint16_t indexed_colour_counts[CBM_COLOUR_COUNT],
#   uint8_t sorted_colour_indexes[CBM_COLOUR_COUNT],
#   uint64_t low,
#   uint64_t high,
# );
.globl sort_colour_count_frequencies
.type sort_colour_count_frequencies, @function

# uint16_t indexed_colour_counts[CBM_COLOUR_COUNT]
.equ LOCAL_INDEXED_COLOUR_COUNTS_PTR, -8
# uint8_t sorted_colour_indexes[CBM_COLOUR_COUNT]
.equ LOCAL_SORTED_COLOUR_INDEXES_PTR, -16
# uint64_t low
.equ LOCAL_LOW, -24
# uint64_t high
.equ LOCAL_HIGH, -32
# uint64_t pivot_index
.equ LOCAL_PIVOT_INDEX, -40

# %rdi - uint16_t indexed_colour_counts[CBM_COLOUR_COUNT]
# %rsi - uint8_t sorted_colour_indexes[CBM_COLOUR_COUNT]
# %rdx - uint64_t low
# %rcx - uint64_t high
sort_colour_count_frequencies:

    # Reserve space for 5 variables (aligned to 16 bytes):
    enter $0x30, $0
    # %rdi - uint16_t indexed_colour_counts[CBM_COLOUR_COUNT]
    movq %rdi, LOCAL_INDEXED_COLOUR_COUNTS_PTR(%rbp)
    # %rsi - uint8_t sorted_colour_indexes[CBM_COLOUR_COUNT]
    movq %rsi, LOCAL_SORTED_COLOUR_INDEXES_PTR(%rbp)
    # %rdx - uint64_t low
    movq %rdx, LOCAL_LOW(%rbp)
    # %rcx - uint64_t high
    movq %rcx, LOCAL_HIGH(%rbp)

    # if (low < high) {
    #   uint64_t pivot_index = sort_colour_count_partition(indexed_colour_counts, sorted_colour_indexes, low, high);
    #   sort_colour_count_frequencies(indexed_colour_counts, sorted_colour_indexes, low, pivot_index - 1);
    #   sort_colour_count_frequencies(indexed_colour_counts, sorted_colour_indexes, pivot_index + 1, high);
    # }

    movq LOCAL_LOW(%rbp), %rax
    cmpq LOCAL_HIGH(%rbp), %rax
    jge __sort_colour_count_frequencies_1

    movq LOCAL_INDEXED_COLOUR_COUNTS_PTR(%rbp), %rdi
    # %rdi - uint16_t indexed_colour_counts[CBM_COLOUR_COUNT]
    movq LOCAL_SORTED_COLOUR_INDEXES_PTR(%rbp), %rsi
    # %rsi - uint8_t sorted_colour_indexes[CBM_COLOUR_COUNT]
    movq LOCAL_LOW(%rbp), %rdx
    # %rdx - uint64_t low
    movq LOCAL_HIGH(%rbp), %rcx
    # %rcx - uint64_t high
    call sort_colour_count_partition
    # %rax - uint64_t pivot_index
    movq %rax, LOCAL_PIVOT_INDEX(%rbp)

    movq LOCAL_INDEXED_COLOUR_COUNTS_PTR(%rbp), %rdi
    # %rdi - uint16_t indexed_colour_counts[CBM_COLOUR_COUNT]
    movq LOCAL_SORTED_COLOUR_INDEXES_PTR(%rbp), %rsi
    # %rsi - uint8_t sorted_colour_indexes[CBM_COLOUR_COUNT]
    movq LOCAL_LOW(%rbp), %rdx
    # %rdx - uint64_t low
    movq LOCAL_PIVOT_INDEX(%rbp), %rcx
    subq $1, %rcx
    # %rcx - uint64_t high = pivot_index - 1
    call sort_colour_count_frequencies

    movq LOCAL_INDEXED_COLOUR_COUNTS_PTR(%rbp), %rdi
    # %rdi - uint16_t indexed_colour_counts[CBM_COLOUR_COUNT]
    movq LOCAL_SORTED_COLOUR_INDEXES_PTR(%rbp), %rsi
    # %rsi - uint8_t sorted_colour_indexes[CBM_COLOUR_COUNT]
    movq LOCAL_PIVOT_INDEX(%rbp), %rdx
    addq $1, %rdx
    # %rdx - uint64_t low = pivot_index + 1
    movq LOCAL_HIGH(%rbp), %rcx
    # %rcx - uint64_t high
    call sort_colour_count_frequencies

__sort_colour_count_frequencies_1:

    leave
    ret

# uint64_t sort_colour_count_partition(
#   uint16_t indexed_colour_counts[CBM_COLOUR_COUNT],
#   uint8_t sorted_colour_indexes[CBM_COLOUR_COUNT],
#   uint64_t low,
#   uint64_t high,
# );
.type sort_colour_count_partition, @function

# uint16_t indexed_colour_counts[CBM_COLOUR_COUNT]
.equ LOCAL_INDEXED_COLOUR_COUNTS_PTR, -8
# uint8_t sorted_colour_indexes[CBM_COLOUR_COUNT]
.equ LOCAL_SORTED_COLOUR_INDEXES_PTR, -16
# uint64_t low
.equ LOCAL_LOW, -24
# uint64_t high
.equ LOCAL_HIGH, -32
# uint64_t i
.equ LOCAL_I, -40
# uint64_t j
.equ LOCAL_J, -48
# uint16_t pivot
.equ LOCAL_PIVOT, -50

# %rdi - uint16_t indexed_colour_counts[CBM_COLOUR_COUNT]
# %rsi - uint8_t sorted_colour_indexes[CBM_COLOUR_COUNT]
# %rdx - uint64_t low
# %rcx - uint64_t high
sort_colour_count_partition:

    # Reserve space for 7 variables (aligned to 16 bytes):
    enter $0x40, $0
    # %rdi - uint16_t indexed_colour_counts[CBM_COLOUR_COUNT]
    movq %rdi, LOCAL_INDEXED_COLOUR_COUNTS_PTR(%rbp)
    # %rsi - uint8_t sorted_colour_indexes[CBM_COLOUR_COUNT]
    movq %rsi, LOCAL_SORTED_COLOUR_INDEXES_PTR(%rbp)
    # %rdx - uint64_t low
    movq %rdx, LOCAL_LOW(%rbp)
    # %rcx - uint64_t high
    movq %rcx, LOCAL_HIGH(%rbp)

    # uint16_t pivot = indexed_colour_counts[high];
    # uint64_t i = low - 1;
    #
    # for (uint64_t j = low; j <= high - 1; ++j) {
    #   if (indexed_colour_counts[j] < pivot) {
    #     ++i;
    #     swap(indexed_colour_counts[i], indexed_colour_counts[j]);
    #     swap(sorted_colour_indexes[i], sorted_colour_indexes[j]);
    #   }
    # }
    #
    # swap(indexed_colour_counts[i + 1], indexed_colour_counts[high]);
    # swap(sorted_colour_indexes[i + 1], sorted_colour_indexes[high]);
    #
    # return i + 1;

    movq LOCAL_HIGH(%rbp), %rcx
    # %rcx - uint64_t high
    movq LOCAL_INDEXED_COLOUR_COUNTS_PTR(%rbp), %rdi
    # %rdi - uint16_t indexed_colour_counts[CBM_COLOUR_COUNT]
    movw (%rdi, %rcx, INDEXED_COLOUR_COUNT_SIZE), %ax
    # %ax - uint16_t pivot = indexed_colour_counts[high]
    movw %ax, LOCAL_PIVOT(%rbp)

    movq LOCAL_LOW(%rbp), %rax
    # %rax - uint64_t low
    subq $1, %rax
    # %rax - uint64_t low -= 1
    movq %rax, LOCAL_I(%rbp)
    # uint64_t i = low - 1

    movq LOCAL_LOW(%rbp), %rax
    # %rax - uint64_t low
    movq %rax, LOCAL_J(%rbp)
    # uint64_t j = low

__sort_colour_count_partition_1:

    movq LOCAL_J(%rbp), %rcx
    # %rcx - uint64_t j
    movq LOCAL_INDEXED_COLOUR_COUNTS_PTR(%rbp), %rdi
    # %rdi - uint16_t indexed_colour_counts[CBM_COLOUR_COUNT]
    movw (%rdi, %rcx, INDEXED_COLOUR_COUNT_SIZE), %ax
    # %ax - uint16_t colour_count = indexed_colour_counts[j]
    cmpw LOCAL_PIVOT(%rbp), %ax
    jbe __sort_colour_count_partition_2

    incq LOCAL_I(%rbp)

    movq LOCAL_INDEXED_COLOUR_COUNTS_PTR(%rbp), %rdi
    # %rdi - uint16_t indexed_colour_counts[CBM_COLOUR_COUNT]
    movq LOCAL_I(%rbp), %rsi
    # %rsi - uint64_t i
    movq LOCAL_J(%rbp), %rdx
    # %rdx - uint64_t j
    movq $INDEXED_COLOUR_COUNT_SIZE, %rcx
    # %rcx - uint64_t item_size = INDEXED_COLOUR_COUNT_SIZE
    call swap_array_items

    movq LOCAL_SORTED_COLOUR_INDEXES_PTR(%rbp), %rdi
    # %rdi - uint16_t sorted_colour_indexes[CBM_COLOUR_COUNT]
    movq LOCAL_I(%rbp), %rsi
    # %rsi - uint64_t i
    movq LOCAL_J(%rbp), %rdx
    # %rdx - uint64_t j
    movq $1, %rcx
    # %rcx - uint64_t item_size = 1
    call swap_array_items

__sort_colour_count_partition_2:

    incq LOCAL_J(%rbp)
    movq LOCAL_HIGH(%rbp), %rax
    # %rax - uint64_t high
    subq $1, %rax
    # %rax - uint64_t high -= 1
    cmpq %rax, LOCAL_J(%rbp)
    jbe __sort_colour_count_partition_1

    incq LOCAL_I(%rbp)
    # uint64_t i = i + 1

    movq LOCAL_INDEXED_COLOUR_COUNTS_PTR(%rbp), %rdi
    # %rdi - uint16_t indexed_colour_counts[CBM_COLOUR_COUNT]
    movq LOCAL_I(%rbp), %rsi
    # %rsi - uint64_t i = i + 1
    movq LOCAL_HIGH(%rbp), %rdx
    # %rdx - uint64_t high
    movq $INDEXED_COLOUR_COUNT_SIZE, %rcx
    # %rcx - uint64_t item_size = INDEXED_COLOUR_COUNT_SIZE
    call swap_array_items

    movq LOCAL_SORTED_COLOUR_INDEXES_PTR(%rbp), %rdi
    # %rdi - uint16_t sorted_colour_indexes[CBM_COLOUR_COUNT]
    movq LOCAL_I(%rbp), %rsi
    # %rsi - uint64_t i = i + 1
    movq LOCAL_HIGH(%rbp), %rdx
    # %rdx - uint64_t high
    movq $1, %rcx
    # %rcx - uint64_t item_size = 1
    call swap_array_items

    movq LOCAL_I(%rbp), %rax
    # %rax - uint64_t pivot_index = i + 1

    leave
    ret

# template<typename T>
# void swap_array_items(T *array, uint64_t index_1, uint64_t index_2, uint64_t item_size);
.globl swap_array_items
.type swap_array_items, @function

# T *array
.equ LOCAL_ARRAY_PTR, -8
# uint64_t index_1
.equ LOCAL_INDEX_1, -16
# uint64_t index_2
.equ LOCAL_INDEX_2, -24
# uint64_t item_size
.equ LOCAL_ITEM_SIZE, -32
# T temp
.equ LOCAL_TEMP, -40
# T *item_1
.equ LOCAL_ITEM_1_PTR, -48
# T *item_2
.equ LOCAL_ITEM_2_PTR, -56

# %rdi - T *array
# %rsi - uint64_t index_1
# %rdx - uint64_t index_2
# %rcx - uint64_t item_size
swap_array_items:

    # Reserve space for 7 variables (aligned to 16 bytes):
    enter $0x40, $0
    # %rdi - T *array
    movq %rdi, LOCAL_ARRAY_PTR(%rbp)
    # %rsi - uint64_t index_1
    movq %rsi, LOCAL_INDEX_1(%rbp)
    # %rdx - uint64_t index_2
    movq %rdx, LOCAL_INDEX_2(%rbp)
    # %rcx - uint64_t item_size
    movq %rcx, LOCAL_ITEM_SIZE(%rbp)

    # Calculate pointer to an array item at index 1:
    movq LOCAL_ARRAY_PTR(%rbp), %rdi
    # %rdi - T *array
    movq LOCAL_INDEX_1(%rbp), %rax
    # %rax - uint64_t index_1
    mulq LOCAL_ITEM_SIZE(%rbp)
    # %rax - uint64_t item_1_offset = index_1 * item_size
    addq %rax, %rdi
    # %rdi - T *item_1 = array + item_1_offset
    movq %rdi, LOCAL_ITEM_1_PTR(%rbp)

    # Calculate pointer to an array item at index 2:
    movq LOCAL_ARRAY_PTR(%rbp), %rdi
    # %rdi - T *array
    movq LOCAL_INDEX_2(%rbp), %rax
    # %rax - uint64_t index_2
    mulq LOCAL_ITEM_SIZE(%rbp)
    # %rax - uint64_t item_2_offset = index_2 * item_size
    addq %rax, %rdi
    # %rdi - T *item_2 = array + item_2_offset
    movq %rdi, LOCAL_ITEM_2_PTR(%rbp)

    leaq LOCAL_TEMP(%rbp), %rdi
    # %rdi - T *temp = &temp
    movq LOCAL_ITEM_1_PTR(%rbp), %rsi
    # %rsi - T *item_1 = &array[index_1]
    movq LOCAL_ITEM_SIZE(%rbp), %rcx
    # %rcx - uint64_t item_size
    cld
    rep movsb
    # T temp = array[index_1];

    movq LOCAL_ITEM_1_PTR(%rbp), %rdi
    # %rdi - T *item_1 = &array[index_1]
    movq LOCAL_ITEM_2_PTR(%rbp), %rsi
    # %rsi - T *item_2 = &array[index_2]
    movq LOCAL_ITEM_SIZE(%rbp), %rcx
    # %rcx - uint64_t item_size
    cld
    rep movsb
    # array[index_1] = array[index_2];

    movq LOCAL_ITEM_2_PTR(%rbp), %rdi
    # %rdi - T *item_2 = &array[index_2]
    leaq LOCAL_TEMP(%rbp), %rsi
    # %rsi - T *temp = &temp
    movq LOCAL_ITEM_SIZE(%rbp), %rcx
    # %rcx - uint64_t item_size
    cld
    rep movsb
    # array[index_2] = temp;

    leave
    ret

# Byte identify_most_common_colour(PixelMap *pixel_map);
.globl identify_most_common_colour
.type identify_most_common_colour, @function

# PixelMap *pixel_map
.equ LOCAL_PIXEL_MAP_PTR, -8
# Byte most_frequent_colour
.equ LOCAL_MOST_FREQUENT_COLOUR, -9

# %rdi - PixelMap *pixel_map
identify_most_common_colour:

    # Reserve space for 2 variables (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - PixelMap *pixel_map
    movq %rdi, LOCAL_PIXEL_MAP_PTR(%rbp)

    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movw $0, %si
    # %si - uint16_t offset_x
    movw $0, %dx
    # %dx - uint16_t offset_y
    call pix_get_width
    movw %ax, %cx
    # %cx - uint16_t length_x
    call pix_get_height
    movw %ax, %r8w
    # %r8w - uint16_t length_y
    leaq LOCAL_MOST_FREQUENT_COLOUR(%rbp), %r9
    # %r9 - Byte most_frequent_colours[max_count]
    movq $2, %rax
    pushq %rax
    # (%rbp)[2] - uint16_t increment_x
    movq $INCLUDE_BACKGROUND_COLOUR_COUNT, %rax
    pushq %rax
    # (%rbp)[1] - Byte background_colour
    movq $1, %rax
    pushq %rax
    # (%rbp)[0] - uint8_t max_count
    call collect_most_frequent_colours
    addq $24, %rsp

    movb LOCAL_MOST_FREQUENT_COLOUR(%rbp), %al
    # %al - Byte most_common_cbm_colour

    leave
    ret
