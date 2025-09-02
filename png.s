.include "const.s"

.section .text

# PngImport *new_png_import(
#   png_bytep *row_pointers,
#   enum colour_palette palette,
#   uint32_t width,
#   uint32_t height,
#   Byte background_colour,
# );
.globl new_png_import
.type new_png_import, @function

# png_bytep *row_pointers
.equ LOCAL_ROW_POINTERS_PTR, -8
# ColourPalette *colour_palette
.equ LOCAL_COLOUR_PALETTE_PTR, -16
# PngImport *png_import
.equ LOCAL_PNG_IMPORT_PTR, -24
# uint32_t width
.equ LOCAL_WIDTH, -28
# uint32_t height
.equ LOCAL_HEIGHT, -32
# enum colour_palette palette
.equ LOCAL_COLOUR_PALETTE, -33
# Byte background_colour
.equ LOCAL_BACKGROUND_COLOUR, -34

# %rdi - png_bytep *row_pointers
# %sil - enum colour_palette palette
# %edx - uint32_t width
# %ecx - uint32_t height
# %r8b - Byte background_colour
new_png_import:

    # Reserve space for 7 variables (aligned to 16 bytes):
    enter $0x30, $0
    # %rdi - png_bytep *row_pointers
    movq %rdi, LOCAL_ROW_POINTERS_PTR(%rbp)
    # %sil - enum colour_palette palette
    movb %sil, LOCAL_COLOUR_PALETTE(%rbp)
    # %edx - uint32_t width
    movl %edx, LOCAL_WIDTH(%rbp)
    # %ecx - uint32_t height
    movl %ecx, LOCAL_HEIGHT(%rbp)
    # %r8b - Byte background_colour
    movb %r8b, LOCAL_BACKGROUND_COLOUR(%rbp)

    # Resolve colour palette enumeration into colour palette data structure:
    movb LOCAL_COLOUR_PALETTE(%rbp), %dil
    # %dil - enum colour_palette palette
    call get_colour_palette
    # %rax - ColourPalette *colour_palette
    movq %rax, LOCAL_COLOUR_PALETTE_PTR(%rbp)

    # Allocate memory to store the new PngImport object:
    movq $PNG_IMPORT_TOTAL_SIZE, %rdi
    call malloc@plt
    # %rax - PngImport *png_import
    movq %rax, LOCAL_PNG_IMPORT_PTR(%rbp)

    # Initialise the member variable - png_bytep *png_import->row_pointers
    movq LOCAL_ROW_POINTERS_PTR(%rbp), %rax
    # %rax - png_bytep *row_pointers
    movq LOCAL_PNG_IMPORT_PTR(%rbp), %rdi
    # %rdi - PngImport *png_import
    movq %rax, PNG_IMPORT_ROW_POINTERS_OFFSET(%rdi)

    # Initialise the member variable - uint32_t png_import->width
    movl LOCAL_WIDTH(%rbp), %eax
    # %eax - uint32_t width
    movq LOCAL_PNG_IMPORT_PTR(%rbp), %rdi
    # %rdi - PngImport *png_import
    movl %eax, PNG_IMPORT_WIDTH_OFFSET(%rdi)

    # Initialise the member variable - uint32_t png_import->height
    movl LOCAL_HEIGHT(%rbp), %eax
    # %eax - uint32_t height
    movq LOCAL_PNG_IMPORT_PTR(%rbp), %rdi
    # %rdi - PngImport *png_import
    movl %eax, PNG_IMPORT_HEIGHT_OFFSET(%rdi)

    # Initialise the member variable - ColourPalette *png_import->colour_palette
    movq LOCAL_COLOUR_PALETTE_PTR(%rbp), %rax
    # %rax - ColourPalette *colour_palette
    movq LOCAL_PNG_IMPORT_PTR(%rbp), %rdi
    # %rdi - PngImport *png_import
    movq %rax, PNG_IMPORT_COLOUR_PALETTE_OFFSET(%rdi)

    # Initialise the member variable - Byte png_import->background_colour
    movb LOCAL_BACKGROUND_COLOUR(%rbp), %al
    # %al - Byte background_colour
    movq LOCAL_PNG_IMPORT_PTR(%rbp), %rdi
    # %rdi - PngImport *png_import
    movb %al, PNG_IMPORT_BACKGROUND_COLOUR_OFFSET(%rdi)

    movq LOCAL_PNG_IMPORT_PTR(%rbp), %rax
    # %rax - PngImport *png_import

    leave
    ret

# void delete_png_import(PngImport *png_import);
.globl delete_png_import
.type delete_png_import, @function

# PngImport *png_import
.equ LOCAL_PNG_IMPORT_PTR, -8

# %rdi - PngImport *png_import
delete_png_import:

    # Reserve space for 1 variable (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - PngImport *png_import
    movq %rdi, LOCAL_PNG_IMPORT_PTR(%rbp)
    # Do not deallocate a null pointer:
    cmpq $0, %rdi
    jz __delete_png_import_1

    # Deallocate the PngImport object:
    movq LOCAL_PNG_IMPORT_PTR(%rbp), %rdi
    # %rdi - PngImport *png_import
    movq $PNG_IMPORT_TOTAL_SIZE, %rsi
    # %rsi - uint64_t length
    call free_with_zero_fill

__delete_png_import_1:

    leave
    ret

# uint32_t png_import_get_row_pointers(PngImport *png_import);
.type png_import_get_row_pointers, @function

# %rdi - PngImport *png_import
png_import_get_row_pointers:

    # %rdi - PngImport *png_import
    movq PNG_IMPORT_ROW_POINTERS_OFFSET(%rdi), %rax
    # %rax - png_bytep *row_pointers

    ret

# uint32_t png_import_get_width(PngImport *png_import);
.type png_import_get_width, @function

# %rdi - PngImport *png_import
png_import_get_width:

    # %rdi - PngImport *png_import
    movl PNG_IMPORT_WIDTH_OFFSET(%rdi), %eax
    # %eax - uint32_t width

    ret

# uint32_t png_import_get_height(PngImport *png_import);
.type png_import_get_height, @function

# %rdi - PngImport *png_import
png_import_get_height:

    # %rdi - PngImport *png_import
    movl PNG_IMPORT_HEIGHT_OFFSET(%rdi), %eax
    # %eax - uint32_t height

    ret

# uint32_t png_import_get_colour_palette(PngImport *png_import);
.type png_import_get_colour_palette, @function

# %rdi - PngImport *png_import
png_import_get_colour_palette:

    # %rdi - PngImport *png_import
    movq PNG_IMPORT_COLOUR_PALETTE_OFFSET(%rdi), %rax
    # %rax - ColourPalette *colour_palette

    ret

# Byte png_import_get_background_colour(PngImport *png_import);
.type png_import_get_background_colour, @function

# %rdi - PngImport *png_import
png_import_get_background_colour:

    # %rdi - PngImport *png_import
    movb PNG_IMPORT_BACKGROUND_COLOUR_OFFSET(%rdi), %al
    # %al - Byte background_colour

    ret

# Byte png_import_get_cbm_value_at_xy(PngImport *png_import, uint16_t x, uint16_t y);
.type png_import_get_cbm_value_at_xy, @function

# PngImport *png_import
.equ LOCAL_PNG_IMPORT_PTR, -8
# png_bytep pixel
.equ LOCAL_PIXEL_PTR, -16
# png_color rgba_value
.equ LOCAL_RGBA_VALUE, -20
# uint16_t x
.equ LOCAL_X, -22
# uint16_t y
.equ LOCAL_Y, -24

# %rdi - PngImport *png_import
# %si - uint16_t x
# %dx - uint16_t y
png_import_get_cbm_value_at_xy:

    # Reserve space for 5 variables (aligned to 16 bytes):
    enter $0x20, $0
    # %rdi - PngImport *png_import
    movq %rdi, LOCAL_PNG_IMPORT_PTR(%rbp)
    # %si - uint16_t x
    movw %si, LOCAL_X(%rbp)
    # %dx - uint16_t y
    movw %dx, LOCAL_Y(%rbp)

    # if (y >= height || x >= width) {
    #   return background_colour;
    # }

    movq LOCAL_PNG_IMPORT_PTR(%rbp), %rdi
    # %rdi - PngImport *png_import
    call png_import_get_height
    # %eax - uint32_t height
    movzwl LOCAL_Y(%rbp), %edx
    # %edx - uint16_t y
    cmpl %eax, %edx
    jae __png_import_get_cbm_value_at_xy_1

    movq LOCAL_PNG_IMPORT_PTR(%rbp), %rdi
    # %rdi - PngImport *png_import
    call png_import_get_width
    # %eax - uint32_t width
    movzwl LOCAL_X(%rbp), %edx
    # %edx - uint16_t y
    cmpl %eax, %edx
    jae __png_import_get_cbm_value_at_xy_1

    jmp __png_import_get_cbm_value_at_xy_2

__png_import_get_cbm_value_at_xy_1:

    movq LOCAL_PNG_IMPORT_PTR(%rbp), %rdi
    # %rdi - PngImport *png_import
    call png_import_get_background_colour
    # %al - Byte background_colour

    # If there has been no explicit background colour provided:
    cmpb $INCLUDE_BACKGROUND_COLOUR_COUNT, %al
    # Return requested background colour:
    jne __png_import_get_cbm_value_at_xy_3

    # Return default background colour:
    movb $DEFAULT_BACKGROUND_COLOUR, %al

__png_import_get_cbm_value_at_xy_3:

    leave
    ret

__png_import_get_cbm_value_at_xy_2:

    movq LOCAL_PNG_IMPORT_PTR(%rbp), %rdi
    # %rdi - PngImport *png_import
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call png_import_get_original_rgb_value_at_xy
    # %rax - png_bytep pixel
    movq %rax, LOCAL_PIXEL_PTR(%rbp)

    movq LOCAL_PIXEL_PTR(%rbp), %rdi
    # %rdi - png_bytep pixel
    movl (%rdi), %eax
    # %eax - png_color rgba_value
    movl %eax, LOCAL_RGBA_VALUE(%rbp)

    # Get nearest pixel colour in the selected colour palette:
    movq LOCAL_PNG_IMPORT_PTR(%rbp), %rdi
    # %rdi - PngImport *png_import
    call png_import_get_colour_palette
    # %rax - ColourPalette *palette
    movq %rax, %rdi
    # %rdi - ColourPalette *palette
    movl LOCAL_RGBA_VALUE(%rbp), %esi
    # %esi - png_color rgba_value
    call get_nearest_cbm_value
    # %al - Byte cbm_value

    leave
    ret

# Byte (*png_import_get_cbm_value_callback(void))(PngImport *, uint16_t, uint16_t);
.globl png_import_get_cbm_value_callback
.type png_import_get_cbm_value_callback, @function

png_import_get_cbm_value_callback:

    leaq png_import_get_cbm_value_at_xy(%rip), %rax
    # %rax - Byte (*png_import_get_cbm_value_at_xy)(PngImport *png_import, uint16_t x, uint16_t y)

    ret

# png_bytep png_import_get_original_rgb_value_at_xy(PngImport *png_import, uint16_t x, uint16_t y);
.type png_import_get_original_rgb_value_at_xy, @function

# PngImport *png_import
.equ LOCAL_PNG_IMPORT_PTR, -8
# png_bytep row
.equ LOCAL_ROW_PTR, -16
# uint16_t x
.equ LOCAL_X, -18
# uint16_t y
.equ LOCAL_Y, -20

# %rdi - PngImport *png_import
# %si - uint16_t x
# %dx - uint16_t y
png_import_get_original_rgb_value_at_xy:

    # Reserve space for 4 variables (aligned to 16 bytes):
    enter $0x20, $0
    # %rdi - PngImport *png_import
    movq %rdi, LOCAL_PNG_IMPORT_PTR(%rbp)
    # %si - uint16_t x
    movw %si, LOCAL_X(%rbp)
    # %dx - uint16_t y
    movw %dx, LOCAL_Y(%rbp)

    # png_bytep row = row_pointers[y];

    movq LOCAL_PNG_IMPORT_PTR(%rbp), %rdi
    # %rdi - PngImport *png_import
    call png_import_get_row_pointers
    # %rax - png_bytep *row_pointers
    movzwq LOCAL_Y(%rbp), %rdx
    # %rdx - uint16_t y
    movq (%rax, %rdx, SIZE_OF_POINTER), %rdi
    # %rdi - png_bytep row
    movq %rdi, LOCAL_ROW_PTR(%rbp)

    # png_bytep pixel = &(row[x * 4]);
    movq LOCAL_ROW_PTR(%rbp), %rdi
    # %rdi - png_bytep row
    movzwq LOCAL_X(%rbp), %rdx
    # %rdx - uint16_t x
    leaq (%rdi, %rdx, SIZE_OF_PNG_PIXEL_DATA), %rax
    # %rax - png_bytep pixel

    leave
    ret

# png_bytep (*png_import_get_original_rgb_value_callback(void))(PngImport *, uint16_t, uint16_t);
.globl png_import_get_original_rgb_value_callback
.type png_import_get_original_rgb_value_callback, @function

png_import_get_original_rgb_value_callback:

    leaq png_import_get_original_rgb_value_at_xy(%rip), %rax
    # %rax - png_bytep (*png_import_get_original_rgb_value_at_xy)(PngImport *png_import, uint16_t x, uint16_t y)

    ret
