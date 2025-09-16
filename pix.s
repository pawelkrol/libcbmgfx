.include "const.s"

.section .text

# PixelMap *import_png(
#   png_bytep *row_pointers,
#   enum colour_palette palette,
#   uint32_t width,
#   uint32_t height,
#   Byte background_colour,
# );
.globl import_png
.type import_png, @function

# png_bytep *row_pointers
.equ LOCAL_ROW_POINTERS_PTR, -8
# PngImport *png_import
.equ LOCAL_PNG_IMPORT_PTR, -16
# PixelMap *pixel_map
.equ LOCAL_PIXEL_MAP_PTR, -24
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
import_png:

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

    # Allocate and initialise the imported picture - PngImport *png_import
    movq LOCAL_ROW_POINTERS_PTR(%rbp), %rdi
    # %rdi - png_bytep *row_pointers
    movb LOCAL_COLOUR_PALETTE(%rbp), %sil
    # %sil - enum colour_palette palette
    movl LOCAL_WIDTH(%rbp), %edx
    # %edx - uint32_t width
    movl LOCAL_HEIGHT(%rbp), %ecx
    # %ecx - uint32_t height
    movb LOCAL_BACKGROUND_COLOUR(%rbp), %r8b
    # %r8b - Byte background_colour
    call new_png_import
    # %rax - PngImport *png_import
    movq %rax, LOCAL_PNG_IMPORT_PTR(%rbp)

    movw LOCAL_WIDTH(%rbp), %di
    # %di - uint16_t width
    movw LOCAL_HEIGHT(%rbp), %si
    # %si - uint16_t height
    movq LOCAL_PNG_IMPORT_PTR(%rbp), %rdx
    # %rdx - PngImport *png_import
    call png_import_get_cbm_value_callback
    # %rax - Byte (*png_import_get_cbm_value_at_xy)(PngImport *png_import, uint16_t x, uint16_t y)
    movq %rax, %rcx
    # %rcx - ByteArray *(*get_cbm_value)(PngImport *png_import, uint16_t x, uint16_t y)
    movb LOCAL_COLOUR_PALETTE(%rbp), %r8b
    # %r8b - enum colour_palette palette
    call png_import_get_original_rgb_value_callback
    # %rax - png_bytep (*png_import_get_original_rgb_value_at_xy)(PngImport *png_import, uint16_t x, uint16_t y)
    movq %rax, %r9
    # %r9 - png_bytep (*get_original_rgb_value)(PngImport *png_import, uint16_t x, uint16_t y)
    call new_pixel_map
    # %rax - PixelMap *pixel_map
    movq %rax, LOCAL_PIXEL_MAP_PTR(%rbp)

    # Deallocate the PngImport object:
    movq LOCAL_PNG_IMPORT_PTR(%rbp), %rdi
    # %rdi - PngImport *png_import
    call delete_png_import

    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rax
    # %rax - PixelMap *pixel_map

    leave
    ret

# PixelMap *new_pixel_map(
#   uint16_t width,
#   uint16_t height,
#   void *picture,
#   ByteArray *(*get_cbm_value)(void *picture, uint16_t x, uint16_t y),
#   enum colour_palette palette,
#   png_bytep (*get_original_rgb_value)(void *picture, uint16_t x, uint16_t y),
# );
.globl new_pixel_map
.type new_pixel_map, @function

# ByteArray *(*get_cbm_value)(void *picture, uint16_t x, uint16_t y)
.equ LOCAL_GET_CBM_VALUE_FUN_PTR, -8
# uint64_t colour_data_size
.equ LOCAL_COLOUR_DATA_SIZE, -16
# PixelMap *pixel_map
.equ LOCAL_PIXEL_MAP_PTR, -24
# uint64_t x
.equ LOCAL_X, -32
# uint64_t y
.equ LOCAL_Y, -40
# Colour *colour
.equ LOCAL_COLOUR_PTR, -48
# void *picture
.equ LOCAL_PICTURE_PTR, -56
# ColourPalette *colour_palette
.equ LOCAL_COLOUR_PALETTE_PTR, -64
# png_bytep (*get_original_rgb_value)(void *picture, uint16_t x, uint16_t y)
.equ LOCAL_GET_ORIGINAL_RGB_VALUE_FUN_PTR, -72
# png_bytep original_rgb_value
.equ LOCAL_ORIGINAL_RGB_VALUE_PTR, -80
# ByteArray *cbm_values
.equ LOCAL_CBM_VALUES_PTR, -88
# uint16_t width
.equ LOCAL_WIDTH, -90
# uint16_t height
.equ LOCAL_HEIGHT, -92
# Byte cbm_value
.equ LOCAL_CBM_VALUE, -93
# enum colour_palette palette
.equ LOCAL_COLOUR_PALETTE, -94

# %di - uint16_t width
# %si - uint16_t height
# %rdx - void *picture
# %rcx - ByteArray *(*get_cbm_value)(void *picture, uint16_t x, uint16_t y)
# %r8b - enum colour_palette palette
# %r9 - png_bytep (*get_original_rgb_value)(void *picture, uint16_t x, uint16_t y)
new_pixel_map:

    # Reserve space for 15 variables (aligned to 16 bytes):
    enter $0x60, $0
    # %di - uint16_t width
    movw %di, LOCAL_WIDTH(%rbp)
    # %si - uint16_t height
    movw %si, LOCAL_HEIGHT(%rbp)
    # %rdx - void *picture
    movq %rdx, LOCAL_PICTURE_PTR(%rbp)
    # %rcx - ByteArray *(*get_cbm_value)(void *picture, uint16_t x, uint16_t y)
    movq %rcx, LOCAL_GET_CBM_VALUE_FUN_PTR(%rbp)
    # %r8b - enum colour_palette palette
    movb %r8b, LOCAL_COLOUR_PALETTE(%rbp)
    # %r9 - png_bytep (*get_original_rgb_value)(void *picture, uint16_t x, uint16_t y)
    movq %r9, LOCAL_GET_ORIGINAL_RGB_VALUE_FUN_PTR(%rbp)

    # Resolve colour palette enumeration into colour palette data structure:
    movb LOCAL_COLOUR_PALETTE(%rbp), %dil
    # %dil - enum colour_palette palette
    call get_colour_palette
    # %rax - ColourPalette *colour_palette
    movq %rax, LOCAL_COLOUR_PALETTE_PTR(%rbp)

    # Allocate memory to store the new PixelMap object:
    movq $PIXELMAP_TOTAL_SIZE, %rdi
    call malloc@plt
    # %rax - PixelMap *pixel_map
    movq %rax, LOCAL_PIXEL_MAP_PTR(%rbp)

    # Initialise the member variable - uint16_t pixel_map->width
    movw LOCAL_WIDTH(%rbp), %ax
    # %ax - uint16_t width
    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movw %ax, PIXELMAP_WIDTH_OFFSET(%rdi)

    # Initialise the member variable - uint16_t pixel_map->height
    movw LOCAL_HEIGHT(%rbp), %ax
    # %ax - uint16_t height
    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movw %ax, PIXELMAP_HEIGHT_OFFSET(%rdi)

    # Initialise the member variable - enum colour_palette pixel_map->colour_palette
    movb LOCAL_COLOUR_PALETTE(%rbp), %al
    # %al - enum colour_palette palette
    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movb %al, PIXELMAP_COLOUR_PALETTE_OFFSET(%rdi)

    # Compute memory size in bytes of Colour data to store in the PixelMap object:
    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    call pix_get_colour_data_size
    # %rax - uint64_t colour_data_size = (width * height) * size_of(Colour *)
    movq %rax, LOCAL_COLOUR_DATA_SIZE(%rbp)

    # Allocate and initialise the member variable - Colour *pixel_map->colour_data
    movq LOCAL_COLOUR_DATA_SIZE(%rbp), %rdi
    # %rdi - uint64_t colour_data_size
    # Allocate memory to store Colour pointers:
    call malloc@plt
    # %rax - Colour **colour_data
    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movq %rax, PIXELMAP_COLOUR_DATA_PTR_OFFSET(%rdi)

    # Initialise an array of Colour data objects with the actual pixels of the source picture:

    # ColourPalette *colour_palette = *(colour_palettes + palette_index)
    # for (uint64_t x = 0; x < width; ++x) {
    #   for (uint64_t y = 0; y < height; ++y) {
    #     ByteArray *cbm_values = get_cbm_value(picture, x, y);
    #     Colour *colour = pix_get_average_colour(cbm_values, colour_palette);
    #     uint64_t offset = pix_get_colour_data_offset(x, y);  // y * width + x
    #     *(colour_data + offset) = colour;
    #   }
    # }

    movq $0, LOCAL_X(%rbp)

__new_pixel_map_1:

    movq $0, LOCAL_Y(%rbp)

__new_pixel_map_2:

    movq LOCAL_PICTURE_PTR(%rbp), %rdi
    # %rdi - void *picture
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call *LOCAL_GET_CBM_VALUE_FUN_PTR(%rbp)
    # %rax - ByteArray *cbm_values
    movq %rax, LOCAL_CBM_VALUES_PTR(%rbp)

    movq LOCAL_PICTURE_PTR(%rbp), %rdi
    # %rdi - void *picture
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call *LOCAL_GET_ORIGINAL_RGB_VALUE_FUN_PTR(%rbp)
    # %rax - png_bytep original_rgb_value
    movq %rax, LOCAL_ORIGINAL_RGB_VALUE_PTR(%rbp)

    # Compute RGB value as a combination of multiple CBM colours (e.g. IFLI):
    movq LOCAL_CBM_VALUES_PTR(%rbp), %rdi
    # %rdi - ByteArray *cbm_values
    movq LOCAL_COLOUR_PALETTE_PTR(%rbp), %rsi
    # %rsi - ColourPalette *colour_palette
    movq LOCAL_ORIGINAL_RGB_VALUE_PTR(%rbp), %rdx
    # %rdx - png_bytep original_rgb_value
    call pix_get_average_colour
    # %rax - Colour *colour
    movq %rax, LOCAL_COLOUR_PTR(%rbp)

    movq LOCAL_CBM_VALUES_PTR(%rbp), %rdi
    # %rdi - ByteArray *cbm_values
    call delete_byte_array

    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call pix_get_colour_data_at_xy
    # %rax - Colour *destination_colour = colour_data + y * width + x;
    movq LOCAL_COLOUR_PTR(%rbp), %rsi
    # %rsi - Colour *colour
    movq %rsi, (%rax)
    # *(colour_data + y * width + x) = colour

    incq LOCAL_Y(%rbp)
    movq LOCAL_Y(%rbp), %rax
    movzwq LOCAL_HEIGHT(%rbp), %rdx
    cmpq %rax, %rdx
    ja __new_pixel_map_2

    incq LOCAL_X(%rbp)
    movq LOCAL_X(%rbp), %rax
    movzwq LOCAL_WIDTH(%rbp), %rdx
    cmpq %rax, %rdx
    ja __new_pixel_map_1

    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rax
    # %rax - PixelMap *pixel_map

    leave
    ret

# Colour *pix_get_average_colour(
#   ByteArray *cbm_values,
#   ColourPalette *colour_palette,
#   png_bytep original_rgb_value,
# );
.globl pix_get_average_colour
.type pix_get_average_colour, @function

# ByteArray *cbm_values
.equ LOCAL_CBM_VALUES_PTR, -8
# ColourPalette *colour_palette
.equ LOCAL_COLOUR_PALETTE_PTR, -16
# std::size_t length
.equ LOCAL_LENGTH, -24
# std::size_t i
.equ LOCAL_I, -32
# uint64_t red
.equ LOCAL_RED, -40
# uint64_t green
.equ LOCAL_GREEN, -48
# uint64_t blue
.equ LOCAL_BLUE, -56
# png_bytep original_rgb_value
.equ LOCAL_ORIGINAL_RGB_VALUE_PTR, -64
# Colour *colour
.equ LOCAL_COLOUR_PTR, -72
# uint32_t rgb_value
.equ LOCAL_RGB_VALUE, -76
# Byte cbm_value
.equ LOCAL_CBM_VALUE, -77

# %rdi - ByteArray *cbm_values
# %rsi - ColourPalette *colour_palette
# %rdx - png_bytep original_rgb_value
pix_get_average_colour:

    # Reserve space for 10 variables (aligned to 16 bytes):
    enter $0x50, $0
    # %rdi - ByteArray *cbm_values
    movq %rdi, LOCAL_CBM_VALUES_PTR(%rbp)
    # %rsi - ColourPalette *colour_palette
    movq %rsi, LOCAL_COLOUR_PALETTE_PTR(%rbp)
    # %rdx - png_bytep original_rgb_value
    movq %rdx, LOCAL_ORIGINAL_RGB_VALUE_PTR(%rbp)

    movq LOCAL_CBM_VALUES_PTR(%rbp), %rdi
    # %rdi - ByteArray *cbm_values
    call byte_array_get_length
    # %rax - std::size_t length
    movq %rax, LOCAL_LENGTH(%rbp)

    movq $0, LOCAL_RED(%rbp)
    # uint64_t red = 0
    movq $0, LOCAL_GREEN(%rbp)
    # uint64_t green = 0
    movq $0, LOCAL_BLUE(%rbp)
    # uint64_t blue = 0

    movq $0, LOCAL_I(%rbp)
    # std::size_t i = 0

__pix_get_average_colour_1:

    movq LOCAL_CBM_VALUES_PTR(%rbp), %rdi
    # %rdi - ByteArray *cbm_values
    movq LOCAL_I(%rbp), %rsi
    # %rsi - std::size_t offset = i
    call byte_array_get_value_at
    # %al - Byte cbm_value
    andb $0x0f, %al
    # %al - Byte cbm_value = cbm_value & $0f
    movb %al, LOCAL_CBM_VALUE(%rbp)

    movb LOCAL_CBM_VALUE(%rbp), %dil
    # dil - Byte cbm_value
    movq LOCAL_ORIGINAL_RGB_VALUE_PTR(%rbp), %rsi
    # %rsi - png_bytep original_rgb_value
    movq LOCAL_COLOUR_PALETTE_PTR(%rbp), %rdx
    # %rdx - ColourPalette *colour_palette
    call new_colour
    # %rax - Colour *i_colour
    movq %rax, LOCAL_COLOUR_PTR(%rbp)

    movq LOCAL_COLOUR_PTR(%rbp), %rdi
    # %rdi - Colour *i_colour
    call col_get_red
    # %al - png_byte i_red
    andq $0x00000000000000ff, %rax
    # %rax - uint64_t i_red
    addq %rax, LOCAL_RED(%rbp)
    # uint64_t red = red + i_red

    movq LOCAL_COLOUR_PTR(%rbp), %rdi
    # %rdi - Colour *i_colour
    call col_get_green
    # %al - png_byte i_green
    andq $0x00000000000000ff, %rax
    # %rax - uint64_t i_green
    addq %rax, LOCAL_GREEN(%rbp)
    # uint64_t green = green + i_green

    movq LOCAL_COLOUR_PTR(%rbp), %rdi
    # %rdi - Colour *i_colour
    call col_get_blue
    # %al - png_byte i_blue
    andq $0x00000000000000ff, %rax
    # %rax - uint64_t i_blue
    addq %rax, LOCAL_BLUE(%rbp)
    # uint64_t blue = blue + i_blue

    movq LOCAL_COLOUR_PTR(%rbp), %rdi
    # %rdi - Colour *i_colour
    call delete_colour

    # while (++i < length)
    incq LOCAL_I(%rbp)
    movq LOCAL_I(%rbp), %rax
    cmpq LOCAL_LENGTH(%rbp), %rax
    jb __pix_get_average_colour_1

    movq $0, %rdx
    # %rdx - 0
    movq LOCAL_RED(%rbp), %rax
    # %rax - uint64_t red
    divq LOCAL_LENGTH(%rbp)
    # %rax - uint64_t red = red / length
    movq %rax, LOCAL_RED(%rbp)

    movq $0, %rdx
    # %rdx - 0
    movq LOCAL_GREEN(%rbp), %rax
    # %rax - uint64_t green
    divq LOCAL_LENGTH(%rbp)
    # %rax - uint64_t green = green / length
    movq %rax, LOCAL_GREEN(%rbp)

    movq $0, %rdx
    # %rdx - 0
    movq LOCAL_BLUE(%rbp), %rax
    # %rax - uint64_t blue
    divq LOCAL_LENGTH(%rbp)
    # %rax - uint64_t blue = blue / length
    movq %rax, LOCAL_BLUE(%rbp)

    movq $0, LOCAL_RGB_VALUE(%rbp)
    # uint32_t rgb_value = 0x00000000
    movzbl LOCAL_RED(%rbp), %eax
    # %eax - uint32_t red
    shll $0x10, %eax
    # %eax - uint32_t red = red << 16
    orl %eax, LOCAL_RGB_VALUE(%rbp)
    # uint32_t rgb_value = 0x00RR0000
    movzbl LOCAL_GREEN(%rbp), %eax
    # %eax - uint32_t green
    shll $0x08, %eax
    # %eax - uint32_t green = green << 8
    orl %eax, LOCAL_RGB_VALUE(%rbp)
    # uint32_t rgb_value = 0x00RRGG00
    movzbl LOCAL_BLUE(%rbp), %eax
    # %eax - uint32_t blue
    orl %eax, LOCAL_RGB_VALUE(%rbp)
    # uint32_t rgb_value = 0x00RRGGBB

    cmpq $1, LOCAL_LENGTH(%rbp)
    ja __pix_get_average_colour_2

    movb LOCAL_CBM_VALUE(%rbp), %dil
    # dil - Byte cbm_value_1

    jmp __pix_get_average_colour_3

__pix_get_average_colour_2:

    movb $-1, %dil
    # %dil - Byte cbm_value

__pix_get_average_colour_3:

    movq LOCAL_ORIGINAL_RGB_VALUE_PTR(%rbp), %rsi
    # %rsi - png_bytep original_rgb_value
    movl LOCAL_RGB_VALUE(%rbp), %edx
    # %edx - uint32_t rgb_value
    call new_rgb_colour
    # %rax - Colour *colour

    leave
    ret

# void delete_pixel_map(PixelMap *pixel_map);
.globl delete_pixel_map
.type delete_pixel_map, @function

# PixelMap *pixel_map
.equ LOCAL_PIXEL_MAP_PTR, -8
# Colour *colour_data
.equ LOCAL_COLOUR_DATA_PTR, -16
# uint64_t colour_data_length
.equ LOCAL_COLOUR_DATA_LENGTH, -24
# uint64_t i
.equ LOCAL_I, -32
# Colour **colour
.equ LOCAL_COLOUR_PTR, -40
# uint64_t colour_data_size
.equ LOCAL_COLOUR_DATA_SIZE, -48

# %rdi - PixelMap *pixel_map
delete_pixel_map:

    # Reserve space for 6 variables (aligned to 16 bytes):
    enter $0x30, $0
    # %rdi - PixelMap *pixel_map
    movq %rdi, LOCAL_PIXEL_MAP_PTR(%rbp)
    # Do not deallocate a null pointer:
    cmpq $0, %rdi
    jz __delete_pixel_map_2

    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    call pix_get_colour_data
    # %rax - Colour *colour_data
    movq %rax, LOCAL_COLOUR_DATA_PTR(%rbp)

    # Compute length of Colour data stored in the PixelMap object:
    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    call pix_get_colour_data_length
    # %rax - uint64_t colour_data_length = width * height
    movq %rax, LOCAL_COLOUR_DATA_LENGTH(%rbp)

    # Compute memory size in bytes of Colour data stored in the PixelMap object:
    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    call pix_get_colour_data_size
    # %rax - uint64_t colour_data_size = (width * height) * size_of(Colour *)
    movq %rax, LOCAL_COLOUR_DATA_SIZE(%rbp)

    # Destroy an array of Colour data objects:

    # for (uint64_t i = 0; i < width * height; ++i) {
    #   delete *(colour_data + offset);
    # }

    movq $0, LOCAL_I(%rbp)

__delete_pixel_map_1:

    movq LOCAL_COLOUR_DATA_PTR(%rbp), %rdi
    # %rdi - Colour *colour_data
    movq LOCAL_I(%rbp), %rsi
    # %rsi - uint64_t i
    call pix_get_colour_data_memory_offset
    # %rax - Colour **colour = colour_data + offset
    movq %rax, LOCAL_COLOUR_PTR(%rbp)

    # Dereference pointer to Colour ** to get the actual Colour object:
    movq LOCAL_COLOUR_PTR(%rbp), %rsi
    # %rsi - Colour **colour
    movq (%rsi), %rdi
    # %rdi - Colour *colour
    call delete_colour

    incq LOCAL_I(%rbp)
    movq LOCAL_I(%rbp), %rax
    cmpq %rax, LOCAL_COLOUR_DATA_LENGTH(%rbp)
    ja __delete_pixel_map_1

    # Deallocate the member variable - Colour *pixel_map->colour_data
    movq LOCAL_COLOUR_DATA_PTR(%rbp), %rdi
    # %rdi - Colour **colour_data
    movq LOCAL_COLOUR_DATA_SIZE(%rbp), %rsi
    # %rsi - uint64_t length
    call free_with_zero_fill

    # Deallocate the PixelMap object:
    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movq $PIXELMAP_TOTAL_SIZE, %rsi
    # %rsi - uint64_t length
    call free_with_zero_fill

__delete_pixel_map_2:

    leave
    ret

# void pix_get_colour_data_offset(PixelMap *pixel_map, uint16_t x, uint16_t y);
.type pix_get_colour_data_offset, @function

# PixelMap *pixel_map
.equ LOCAL_PIXEL_MAP_PTR, -8
# uint64_t x
.equ LOCAL_X, -10
# uint64_t y
.equ LOCAL_Y, -12

# %rdi - PixelMap *pixel_map
# %si - uint16_t x
# %dx - uint16_t y
pix_get_colour_data_offset:

    # Reserve space for 3 variables (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - PixelMap *pixel_map
    movq %rdi, LOCAL_PIXEL_MAP_PTR(%rbp)
    # %si - uint16_t x
    movw %si, LOCAL_X(%rbp)
    # %dx - uint16_t y
    movw %dx, LOCAL_Y(%rbp)

    # uint64_t offset = y * width + x;

    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    call pix_get_width
    # %ax - uint16_t width
    andq $0x000000000000ffff, %rax
    # %rax - uint64_t width
    movzwq LOCAL_Y(%rbp), %rcx
    # %rcx - uint64_t y
    mulq %rcx
    movzwq LOCAL_X(%rbp), %rdx
    # %rdx - uint64_t x
    addq %rdx, %rax
    # %rax - uint64_t offset

    leave
    ret

# Colour **pix_get_colour_data_at_xy(PixelMap *pixel_map, uint16_t x, uint16_t y);
.type pix_get_colour_data_at_xy, @function

# PixelMap *pixel_map
.equ LOCAL_PIXEL_MAP_PTR, -8
# Colour *colour_data
.equ LOCAL_COLOUR_DATA_PTR, -16
# uint64_t offset
.equ LOCAL_OFFSET, -24
# uint64_t x
.equ LOCAL_X, -26
# uint64_t y
.equ LOCAL_Y, -28

# %rdi - PixelMap *pixel_map
# %si - uint16_t x
# %dx - uint16_t y
pix_get_colour_data_at_xy:

    # Reserve space for 5 variables (aligned to 16 bytes):
    enter $0x20, $0
    # %rdi - PixelMap *pixel_map
    movq %rdi, LOCAL_PIXEL_MAP_PTR(%rbp)
    # %si - uint16_t x
    movw %si, LOCAL_X(%rbp)
    # %dx - uint16_t y
    movw %dx, LOCAL_Y(%rbp)

    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    call pix_get_colour_data
    # %rax - Colour *colour_data
    movq %rax, LOCAL_COLOUR_DATA_PTR(%rbp)

    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call pix_get_colour_data_offset
    # %rax - uint64_t offset
    movq %rax, LOCAL_OFFSET(%rbp)

    movq LOCAL_COLOUR_DATA_PTR(%rbp), %rdi
    # %rdi - Colour *colour_data
    movq LOCAL_OFFSET(%rbp), %rsi
    # %rsi - uint64_t offset
    call pix_get_colour_data_memory_offset
    # %rax - Colour **colour = colour_data + offset

    leave
    ret

# Colour **pix_get_colour_data_memory_offset(Colour *colour_data, uint64_t offset);
.type pix_get_colour_data_memory_offset, @function

# Colour *colour_data
.equ LOCAL_COLOUR_DATA_PTR, -8
# uint64_t offset
.equ LOCAL_OFFSET, -16

# %rdi - Colour *colour_data
# %rsi - uint64_t offset
pix_get_colour_data_memory_offset:

    # Reserve space for 2 variables (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - Colour *colour_data
    movq %rdi, LOCAL_COLOUR_DATA_PTR(%rbp)
    # %rsi - uint64_t offset
    movq %rsi, LOCAL_OFFSET(%rbp)

    movq LOCAL_OFFSET(%rbp), %rax
    # %rax - uint64_t offset
    movq $SIZE_OF_POINTER, %rcx
    mulq %rcx
    # %rax - uint64_t memory_offset = offset * size_of(Colour *)
    movq LOCAL_COLOUR_DATA_PTR(%rbp), %rdi
    # %rdi - Colour *colour_data
    addq %rdi, %rax
    # %rax - Colour **colour = colour_data + offset

    leave
    ret

# uint16_t pix_get_width(PixelMap *pixel_map);
.globl pix_get_width
.type pix_get_width, @function

# %rdi - PixelMap *pixel_map
pix_get_width:

    # %rdi - PixelMap *pixel_map
    movw PIXELMAP_WIDTH_OFFSET(%rdi), %ax
    # %ax - uint16_t width

    ret

# uint16_t pix_get_height(PixelMap *pixel_map);
.globl pix_get_height
.type pix_get_height, @function

# %rdi - PixelMap *pixel_map
pix_get_height:

    # %rdi - PixelMap *pixel_map
    movw PIXELMAP_HEIGHT_OFFSET(%rdi), %ax
    # %ax - uint16_t height

    ret

# ColourPalette *pix_get_colour_palette(PixelMap *pixel_map);
.globl pix_get_colour_palette
.type pix_get_colour_palette, @function

# %rdi - PixelMap *pixel_map
pix_get_colour_palette:

    # %rdi - PixelMap *pixel_map
    movb PIXELMAP_COLOUR_PALETTE_OFFSET(%rdi), %dil
    # %dil - enum colour_palette palette
    call get_colour_palette
    # %rax - ColourPalette *colour_palette

    ret

# Get length of Colour data stored in the PixelMap object:
# uint64_t pix_get_colour_data_length(PixelMap *pixel_map);
.type pix_get_colour_data_length, @function

# PixelMap *pixel_map
.equ LOCAL_PIXEL_MAP_PTR, -8
# uint16_t width
.equ LOCAL_WIDTH, -10
# uint16_t height
.equ LOCAL_HEIGHT, -12

# %rdi - PixelMap *pixel_map
pix_get_colour_data_length:

    # Reserve space for 3 variables (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - PixelMap *pixel_map
    movq %rdi, LOCAL_PIXEL_MAP_PTR(%rbp)

    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    call pix_get_width
    # %ax - uint16_t width
    movw %ax, LOCAL_WIDTH(%rbp)

    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    call pix_get_height
    # %ax - uint16_t height
    movw %ax, LOCAL_HEIGHT(%rbp)

    movzwq LOCAL_WIDTH(%rbp), %rax
    movzwq LOCAL_HEIGHT(%rbp), %rcx
    mulq %rcx
    # %rax - uint64_t colour_data_length = width * height

    leave
    ret

# Get memory size in bytes of Colour data stored in the PixelMap object:
# uint64_t pix_get_colour_data_size(PixelMap *pixel_map);
.type pix_get_colour_data_size, @function

# PixelMap *pixel_map
.equ LOCAL_PIXEL_MAP_PTR, -8
# uint64_t colour_data_length
.equ LOCAL_COLOUR_DATA_LENGTH, -16

# %rdi - PixelMap *pixel_map
pix_get_colour_data_size:

    # Reserve space for 2 variables (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - PixelMap *pixel_map
    movq %rdi, LOCAL_PIXEL_MAP_PTR(%rbp)

    # Compute length of Colour data to store in the PixelMap object:
    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    call pix_get_colour_data_length
    # %rax - uint64_t colour_data_length = width * height
    movq %rax, LOCAL_COLOUR_DATA_LENGTH(%rbp)

    # Compute size of Colour data to store in the PixelMap object:
    movq LOCAL_COLOUR_DATA_LENGTH(%rbp), %rax
    movq $SIZE_OF_POINTER, %rcx
    mulq %rcx
    # %rax - uint64_t colour_data_size = (width * height) * size_of(Colour *)

    leave
    ret

# uint16_t pix_get_colour_data(PixelMap *pixel_map);
.type pix_get_colour_data, @function

# %rdi - PixelMap *pixel_map
pix_get_colour_data:

    # %rdi - PixelMap *pixel_map
    movq PIXELMAP_COLOUR_DATA_PTR_OFFSET(%rdi), %rax
    # %rax - Colour *colour_data

    ret

# Colour *pix_get_colour_at_xy(PixelMap *pixel_map, uint16_t x, uint16_t y);
.type pix_get_colour_at_xy, @function

# PixelMap *pixel_map
.equ LOCAL_PIXEL_MAP_PTR, -8
# Colour *colour
.equ LOCAL_COLOUR_PTR, -16
# uint64_t x
.equ LOCAL_X, -18
# uint64_t y
.equ LOCAL_Y, -20

# %rdi - PixelMap *pixel_map
# %si - uint16_t x
# %dx - uint16_t y
pix_get_colour_at_xy:

    # Reserve space for 4 variables (aligned to 16 bytes):
    enter $0x20, $0
    # %rdi - PixelMap *pixel_map
    movq %rdi, LOCAL_PIXEL_MAP_PTR(%rbp)
    # %si - uint16_t x
    movw %si, LOCAL_X(%rbp)
    # %dx - uint16_t y
    movw %dx, LOCAL_Y(%rbp)

    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call pix_get_colour_data_at_xy
    # %rax - Colour *source_colour = colour_data + y * width + x;
    movq %rax, LOCAL_COLOUR_PTR(%rbp)

    # Dereference pointer to Colour * to get the actual Colour object:
    movq LOCAL_COLOUR_PTR(%rbp), %rsi
    # %rsi - Colour *colour
    movq (%rsi), %rax
    # %rax - Colour colour

    leave
    ret

# Byte pix_get_cbm_colour_at(PixelMap *pixel_map, uint16_t x, uint16_t y);
.globl pix_get_cbm_colour_at
.type pix_get_cbm_colour_at, @function

# %rdi - PixelMap *pixel_map
# %si - uint16_t x
# %dx - uint16_t y
pix_get_cbm_colour_at:

    call pix_get_colour_at_xy
    # %rax - Colour *colour
    movq %rax, %rdi
    # %rdi - Colour *colour
    call col_get_cbm_value
    # %al - Byte cbm_value

    ret

# uint32_t pix_get_rgb_colour_at(PixelMap *pixel_map, uint16_t x, uint16_t y);
.globl pix_get_rgb_colour_at
.type pix_get_rgb_colour_at, @function

# %rdi - PixelMap *pixel_map
# %si - uint16_t x
# %dx - uint16_t y
pix_get_rgb_colour_at:

    call pix_get_colour_at_xy
    # %rax - Colour *colour
    movq %rax, %rdi
    # %rdi - Colour *colour
    call col_get_rgb_value
    # %eax - uint32_t rgb_value

    ret

# png_color pix_get_original_rgb_colour_at(PixelMap *pixel_map, uint16_t x, uint16_t y);
.globl pix_get_original_rgb_colour_at
.type pix_get_original_rgb_colour_at, @function

# %rdi - PixelMap *pixel_map
# %si - uint16_t x
# %dx - uint16_t y
pix_get_original_rgb_colour_at:

    call pix_get_colour_at_xy
    # %rax - Colour *colour
    movq %rax, %rdi
    # %rdi - Colour *colour
    call col_get_original_rgb_value
    # %eax - png_color original_rgb_value

    ret
