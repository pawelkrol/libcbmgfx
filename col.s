.include "const.s"

.section .data

.size colour_palette_pepto, COLOUR_PALETTE_TOTAL_SIZE
.type colour_palette_pepto, @object
colour_palette_pepto:
    .4byte PEPTO_RGB_COLOUR_BLACK
    .4byte PEPTO_RGB_COLOUR_WHITE
    .4byte PEPTO_RGB_COLOUR_RED
    .4byte PEPTO_RGB_COLOUR_CYAN
    .4byte PEPTO_RGB_COLOUR_PURPLE
    .4byte PEPTO_RGB_COLOUR_GREEN
    .4byte PEPTO_RGB_COLOUR_BLUE
    .4byte PEPTO_RGB_COLOUR_YELLOW
    .4byte PEPTO_RGB_COLOUR_ORANGE
    .4byte PEPTO_RGB_COLOUR_BROWN
    .4byte PEPTO_RGB_COLOUR_LIGHT_RED
    .4byte PEPTO_RGB_COLOUR_DARK_GRAY
    .4byte PEPTO_RGB_COLOUR_GRAY
    .4byte PEPTO_RGB_COLOUR_LIGHT_GREEN
    .4byte PEPTO_RGB_COLOUR_LIGHT_BLUE
    .4byte PEPTO_RGB_COLOUR_LIGHT_GRAY

.size colour_palette_colodore, COLOUR_PALETTE_TOTAL_SIZE
.type colour_palette_colodore, @object
colour_palette_colodore:
    .4byte COLODORE_RGB_COLOUR_BLACK
    .4byte COLODORE_RGB_COLOUR_WHITE
    .4byte COLODORE_RGB_COLOUR_RED
    .4byte COLODORE_RGB_COLOUR_CYAN
    .4byte COLODORE_RGB_COLOUR_PURPLE
    .4byte COLODORE_RGB_COLOUR_GREEN
    .4byte COLODORE_RGB_COLOUR_BLUE
    .4byte COLODORE_RGB_COLOUR_YELLOW
    .4byte COLODORE_RGB_COLOUR_ORANGE
    .4byte COLODORE_RGB_COLOUR_BROWN
    .4byte COLODORE_RGB_COLOUR_LIGHT_RED
    .4byte COLODORE_RGB_COLOUR_DARK_GRAY
    .4byte COLODORE_RGB_COLOUR_GRAY
    .4byte COLODORE_RGB_COLOUR_LIGHT_GREEN
    .4byte COLODORE_RGB_COLOUR_LIGHT_BLUE
    .4byte COLODORE_RGB_COLOUR_LIGHT_GRAY

.size colour_palette_vice, COLOUR_PALETTE_TOTAL_SIZE
.type colour_palette_vice, @object
colour_palette_vice:
    .4byte VICE_RGB_COLOUR_BLACK
    .4byte VICE_RGB_COLOUR_WHITE
    .4byte VICE_RGB_COLOUR_RED
    .4byte VICE_RGB_COLOUR_CYAN
    .4byte VICE_RGB_COLOUR_PURPLE
    .4byte VICE_RGB_COLOUR_GREEN
    .4byte VICE_RGB_COLOUR_BLUE
    .4byte VICE_RGB_COLOUR_YELLOW
    .4byte VICE_RGB_COLOUR_ORANGE
    .4byte VICE_RGB_COLOUR_BROWN
    .4byte VICE_RGB_COLOUR_LIGHT_RED
    .4byte VICE_RGB_COLOUR_DARK_GRAY
    .4byte VICE_RGB_COLOUR_GRAY
    .4byte VICE_RGB_COLOUR_LIGHT_GREEN
    .4byte VICE_RGB_COLOUR_LIGHT_BLUE
    .4byte VICE_RGB_COLOUR_LIGHT_GRAY

.size colour_palettes, COLOUR_PALETTES_TOTAL_SIZE
.type colour_palettes, @object
colour_palettes:
    .8byte colour_palette_pepto
    .8byte colour_palette_colodore
    .8byte colour_palette_vice

.section .text

# ColourPalette *get_colour_palette(enum colour_palette palette)
.globl get_colour_palette
.type get_colour_palette, @function

# %dil - enum colour_palette palette
get_colour_palette:

    # Check if requested the default colour palette:
    cmpb $COLOUR_PALETTE_DEFAULT, %dil
    jne __get_colour_palette_1
    # Select the default colour palette:
    movb $DEFAULT_COLOUR_PALETTE, %dil

__get_colour_palette_1:

    # Fix colour palette index (0 is reserved for resolving the default value):
    subb $1, %dil
    andq $0x00000000000000ff, %rdi
    # %rdi - uint64_t palette_index = static_cast<uint8_t>(palette) - 1

    leaq colour_palettes(%rip), %rsi
    # %rsi - ColourPalette **colour_palettes
    movq (%rsi, %rdi, SIZE_OF_POINTER), %rax
    # %rax - ColourPalette *colour_palette = *(colour_palettes + palette_index)

    ret

# Colour *new_colour(
#   Byte cbm_value,
#   png_bytep original_rgb_value,
#   ColourPalette *colour_palette,
# );
.globl new_colour
.type new_colour, @function

# ColourPalette *colour_palette
.equ LOCAL_COLOUR_PALETTE_PTR, -8
# png_bytep original_rgb_value
.equ LOCAL_ORIGINAL_RGB_VALUE_PTR, -16
# uint32_t rgb_value
.equ LOCAL_RGB_VALUE, -20
# Byte cbm_value
.equ LOCAL_CBM_VALUE, -21

# %dil - Byte cbm_value
# %rsi - png_bytep original_rgb_value
# %rdx - ColourPalette *colour_palette
new_colour:

    # Reserve space for 4 variables (aligned to 16 bytes):
    enter $0x20, $0
    # %dil - Byte cbm_value
    movb %dil, LOCAL_CBM_VALUE(%rbp)
    # %rsi - png_bytep original_rgb_value
    movq %rsi, LOCAL_ORIGINAL_RGB_VALUE_PTR(%rbp)
    # %rdx - ColourPalette *colour_palette
    movq %rdx, LOCAL_COLOUR_PALETTE_PTR(%rbp)

    # Get CBM colour's RGB value from the colour palette:
    movb LOCAL_CBM_VALUE(%rbp), %dil
    # dil - Byte cbm_value
    movq LOCAL_COLOUR_PALETTE_PTR(%rbp), %rsi
    # %rsi - ColourPalette *colour_palette
    call get_rgb_colour
    # %eax - uint32_t rgb_value
    movl %eax, LOCAL_RGB_VALUE(%rbp)

    movb LOCAL_CBM_VALUE(%rbp), %dil
    # %dil - Byte cbm_value
    movq LOCAL_ORIGINAL_RGB_VALUE_PTR(%rbp), %rsi
    # %rsi - png_bytep original_rgb_value
    movl LOCAL_RGB_VALUE(%rbp), %edx
    # %edx - uint32_t rgb_value
    call new_rgb_colour
    # %rax - Colour *colour

    leave
    ret

# Colour *new_rgb_colour(
#   Byte cbm_value,
#   png_bytep original_rgb_value,
#   uint32_t rgb_value,
# );
.globl new_rgb_colour
.type new_rgb_colour, @function

# Colour *colour
.equ LOCAL_COLOUR_PTR, -8
# png_bytep original_rgb_value
.equ LOCAL_ORIGINAL_RGB_VALUE_PTR, -16
# uint32_t rgb_value
.equ LOCAL_RGB_VALUE, -20
# Byte cbm_value
.equ LOCAL_CBM_VALUE, -21

# %dil - Byte cbm_value
# %rsi - png_bytep original_rgb_value
# %edx - uint32_t rgb_value
new_rgb_colour:

    # Reserve space for 4 variables (aligned to 16 bytes):
    enter $0x20, $0
    # %dil - Byte cbm_value
    movb %dil, LOCAL_CBM_VALUE(%rbp)
    # %rsi - png_bytep original_rgb_value
    movq %rsi, LOCAL_ORIGINAL_RGB_VALUE_PTR(%rbp)
    # %edx - uint32_t rgb_value
    movl %edx, LOCAL_RGB_VALUE(%rbp)

    # Allocate memory to store the new Colour object:
    movq $COLOUR_TOTAL_SIZE, %rdi
    call malloc@plt
    # %rax - Colour *colour
    movq %rax, LOCAL_COLOUR_PTR(%rbp)

    # Initialise the member variable - Byte colour->cbm_value
    movb LOCAL_CBM_VALUE(%rbp), %al
    # %al - Byte cbm_value
    movq LOCAL_COLOUR_PTR(%rbp), %rdi
    # %rdi - Colour *colour
    movb %al, COLOUR_CBM_VALUE_OFFSET(%rdi)

    # Initialise the member variable - uint32_t colour->rgb_value
    movl LOCAL_RGB_VALUE(%rbp), %eax
    # %eax - uint32_t rgb_value
    movq LOCAL_COLOUR_PTR(%rbp), %rdi
    # %rdi - Colour *colour
    movl %eax, COLOUR_RGB_VALUE_OFFSET(%rdi)

    # Initialise the member variable - Byte colour->original_rgb_value

    cmpq $0, LOCAL_ORIGINAL_RGB_VALUE_PTR(%rbp)
    # original_rgb_value == nullptr
    jz __new_rgb_colour_1

    # When importing picture fetch orignal RGB value from the PNG image:
    movq LOCAL_ORIGINAL_RGB_VALUE_PTR(%rbp), %rsi
    # %rsi - png_bytep original_rgb_value
    movl (%rsi), %eax
    # %eax - png_color original_rgb_value
    movq LOCAL_COLOUR_PTR(%rbp), %rdi
    # %rdi - Colour *colour
    movl %eax, COLOUR_ORIGINAL_RGB_VALUE_OFFSET(%rdi)
    jmp __new_rgb_colour_2

__new_rgb_colour_1:

    # By default retrieve original RGB value from the colour palette:
    movq LOCAL_COLOUR_PTR(%rbp), %rdi
    # %rdi - Colour *colour
    call col_get_rgb_value
    # %eax - uint32_t rgb_value (ARGB)
    movl %eax, %edx
    bswapl %edx
    shrl $8, %edx
    andl $0x00ffffff, %edx
    andl $0xff000000, %eax
    orl %edx, %eax
    # %eax - png_color rgb_value (ABGR)
    movl %eax, COLOUR_ORIGINAL_RGB_VALUE_OFFSET(%rdi)

__new_rgb_colour_2:

    movq LOCAL_COLOUR_PTR(%rbp), %rax
    # %rax - Colour *colour

    leave
    ret

# void delete_colour(Colour *colour);
.globl delete_colour
.type delete_colour, @function

# Colour *colour
.equ LOCAL_COLOUR_PTR, -8

# %rdi - Colour *colour
delete_colour:

    # Reserve space for 1 variable (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - Colour *colour
    movq %rdi, LOCAL_COLOUR_PTR(%rbp)
    # Do not deallocate a null pointer:
    cmpq $0, %rdi
    jz __delete_colour_1

    # Deallocate the Colour object:
    movq LOCAL_COLOUR_PTR(%rbp), %rdi
    # %rdi - Colour *colour
    movq $COLOUR_TOTAL_SIZE, %rsi
    # %rsi - uint64_t length
    call free_with_zero_fill

__delete_colour_1:

    leave
    ret

# uint32_t get_rgb_colour(Byte cbm_value, ColourPalette *colour_palette);
.globl get_rgb_colour
.type get_rgb_colour, @function

# ColourPalette *colour_palette
.equ LOCAL_COLOUR_PALETTE_PTR, -8
# Byte cbm_value
.equ LOCAL_CBM_VALUE, -9

# %dil - Byte cbm_value
# %rsi - ColourPalette *colour_palette
get_rgb_colour:

    # Reserve space for 1 variable (aligned to 16 bytes):
    enter $0x10, $0
    # %dil - Byte cbm_value
    movb %dil, LOCAL_CBM_VALUE(%rbp)
    # %rsi - ColourPalette *colour_palette
    movq %rsi, LOCAL_COLOUR_PALETTE_PTR(%rbp)

    movq LOCAL_COLOUR_PALETTE_PTR(%rbp), %rdi
    # %rdi - uint32_t colour_palette[16]
    movzbq LOCAL_CBM_VALUE(%rbp), %rcx
    # %rcx - uint32_t colour_offset = (uint32_t)cbm_value
    movl (%rdi, %rcx, SIZE_OF_UINT32_T), %eax
    # %eax - uint32_t rgb_value = *(colour_palette + colour_offset)

    leave
    ret

# Byte col_get_cbm_value(Colour *colour);
.globl col_get_cbm_value
.type col_get_cbm_value, @function

# %rdi - Colour *colour
col_get_cbm_value:

    # %rdi - Colour *colour
    movb COLOUR_CBM_VALUE_OFFSET(%rdi), %al
    # %al - Byte cbm_value

    ret

# uint32_t col_get_rgb_value(Colour *colour);
.globl col_get_rgb_value
.type col_get_rgb_value, @function

# %rdi - Colour *colour
col_get_rgb_value:

    # %rdi - Colour *colour
    movl COLOUR_RGB_VALUE_OFFSET(%rdi), %eax
    # %eax - uint32_t rgb_value

    ret

# uint8_t col_get_red(Colour *colour);
.globl col_get_red
.type col_get_red, @function

# %rdi - Colour *colour
col_get_red:

    # %rdi - Colour *colour
    call col_get_rgb_value
    # %eax - uint32_t rgb_value
    andl $0x00ff0000, %eax
    shrl $16, %eax
    # %al - png_byte red

    ret

# uint8_t col_get_green(Colour *colour);
.globl col_get_green
.type col_get_green, @function

# %rdi - Colour *colour
col_get_green:

    # %rdi - Colour *colour
    call col_get_rgb_value
    # %eax - uint32_t rgb_value
    andl $0x0000ff00, %eax
    shrl $8, %eax
    # %al - png_byte green

    ret

# uint8_t col_get_blue(Colour *colour);
.globl col_get_blue
.type col_get_blue, @function

# %rdi - Colour *colour
col_get_blue:

    # %rdi - Colour *colour
    call col_get_rgb_value
    # %eax - uint32_t rgb_value
    andl $0x000000ff, %eax
    # %al - png_byte blue

    ret

# png_color col_get_original_rgb_value(Colour *colour);
.globl col_get_original_rgb_value
.type col_get_original_rgb_value, @function

# %rdi - Colour *colour
col_get_original_rgb_value:

    # %rdi - Colour *colour
    movl COLOUR_ORIGINAL_RGB_VALUE_OFFSET(%rdi), %eax
    # %eax - png_color rgb_value

    ret

# Get nearest pixel colour in the selected colour palette:
# Byte get_nearest_cbm_value(ColourPalette *palette, png_color rgba_value);
.globl get_nearest_cbm_value
.type get_nearest_cbm_value, @function

# ColourPalette *palette
.equ LOCAL_COLOUR_PALETTE_PTR, -8
# Vector colour_distances[CBM_COLOUR_COUNT]
.equ LOCAL_COLOUR_DISTANCES_PTR, -16
# double vector_length
.equ LOCAL_VECTOR_LENGTH, -24
# uint32_t i_rgb_value
.equ LOCAL_I_RGB_VALUE, -28
# png_color rgba_value
.equ LOCAL_RGBA_VALUE, -32
# uint8_t i
.equ LOCAL_I, -33
# uint8_t shortest_index
.equ LOCAL_SHORTEST_INDEX, -34

# %rdi - ColourPalette *palette
# %esi - uint32_t rgb_value
get_nearest_cbm_value:

    # Reserve space for 7 variables (aligned to 16 bytes):
    enter $0x30, $0
    # %rdi - ColourPalette *palette
    movq %rdi, LOCAL_COLOUR_PALETTE_PTR(%rbp)
    # %esi - png_color rgba_value
    movl %esi, LOCAL_RGBA_VALUE(%rbp)

    # Allocate memory to store colour vector distances:
    movq $COLOUR_VECTOR_DISTANCES_TOTAL_SIZE, %rdi
    call malloc@plt
    # %rax - Vector colour_distances[CBM_COLOUR_COUNT]
    movq %rax, LOCAL_COLOUR_DISTANCES_PTR(%rbp)

    # Calculate a vector distance between all colours:

    # uint8_t i = 0;
    movb $0, LOCAL_I(%rbp)

__get_nearest_cbm_value_1:

    # Calculate a vector distance between two colours:

    # Get RGB colour value of the current colour index:
    movb LOCAL_I(%rbp), %dil
    # dil - Byte cbm_value
    movq LOCAL_COLOUR_PALETTE_PTR(%rbp), %rsi
    # %rsi - ColourPalette *colour_palette
    call get_rgb_colour
    # %eax - uint32_t i_rgb_value
    movl %eax, LOCAL_I_RGB_VALUE(%rbp)

    movl LOCAL_RGBA_VALUE(%rbp), %edi
    # %edi - png_color rgba_value
    movl LOCAL_I_RGB_VALUE(%rbp), %esi
    # %esi - uint32_t i_rgb_value
    call get_colour_distance
    # %xmm0 - double vector_length
    movq %xmm0, LOCAL_VECTOR_LENGTH(%rbp)

    movq LOCAL_COLOUR_DISTANCES_PTR(%rbp), %rdi
    # %rdi - Vector colour_distances[CBM_COLOUR_COUNT]
    movzbq LOCAL_I(%rbp), %rdx
    # %rdx - uint8_t i
    movq LOCAL_VECTOR_LENGTH(%rbp), %xmm0
    # %xmm0 - double vector_length
    movq %xmm0, (%rdi, %rdx, SIZE_OF_VECTOR_DISTANCE)
    # colour_distances[i] = vector_length

    incb LOCAL_I(%rbp)
    movb LOCAL_I(%rbp), %al
    cmpb $CBM_COLOUR_COUNT, %al
    jb __get_nearest_cbm_value_1

    # Select colour index with the shortest distance:

    # uint8_t shortest_index = 0;
    movb $0, LOCAL_SHORTEST_INDEX(%rbp)

    # uint8_t i = 1;
    movb $1, LOCAL_I(%rbp)

__get_nearest_cbm_value_2:

    movq LOCAL_COLOUR_DISTANCES_PTR(%rbp), %rdi
    # %rdi - Vector colour_distances[CBM_COLOUR_COUNT]
    movzbq LOCAL_I(%rbp), %rdx
    # %rdx - uint8_t i
    movq (%rdi, %rdx, SIZE_OF_VECTOR_DISTANCE), %xmm0
    # %xmm0 - double vector_length = colour_distances[i]

    movq LOCAL_COLOUR_DISTANCES_PTR(%rbp), %rdi
    # %rdi - Vector colour_distances[CBM_COLOUR_COUNT]
    movzbq LOCAL_SHORTEST_INDEX(%rbp), %rdx
    # %rdx - uint8_t shortest_index
    movq (%rdi, %rdx, SIZE_OF_VECTOR_DISTANCE), %xmm1
    # %xmm1 - double vector_length = colour_distances[shortest_index]

    cmpltsd %xmm1, %xmm0 # %xmm0 < %xmm1
    # if true %xmm0 = -1 else %xmm0 = 0
    movq %xmm0, %rax
    cmpq $0, %rax
    jz __get_nearest_cbm_value_3

    # uint8_t shortest_index = i;
    movb LOCAL_I(%rbp), %al
    movb %al, LOCAL_SHORTEST_INDEX(%rbp)

__get_nearest_cbm_value_3:

    incb LOCAL_I(%rbp)
    movb LOCAL_I(%rbp), %al
    cmpb $CBM_COLOUR_COUNT, %al
    jb __get_nearest_cbm_value_2

    # Deallocate an array of colour vector distances:
    movq LOCAL_COLOUR_DISTANCES_PTR(%rbp), %rdi
    # %rdi - Vector colour_distances[CBM_COLOUR_COUNT]
    movq $COLOUR_VECTOR_DISTANCES_TOTAL_SIZE, %rsi
    # %rsi - uint64_t length
    call free_with_zero_fill

    movb LOCAL_SHORTEST_INDEX(%rbp), %al
    # %al - Byte cbm_value

    leave
    ret

# double get_colour_distance(png_color a, uint32_t b);
.globl get_colour_distance
.type get_colour_distance, @function

# png_color a
.equ LOCAL_A, -4
# uint32_t b
.equ LOCAL_B, -8
# double diff_red
.equ LOCAL_DIFF_RED, -16
# double diff_green
.equ LOCAL_DIFF_GREEN, -24
# double diff_blue
.equ LOCAL_DIFF_BLUE, -32
# png_byte red
.equ LOCAL_RED, -33
# png_byte green
.equ LOCAL_GREEN, -34
# png_byte blue
.equ LOCAL_BLUE, -35
# png_byte i_red
.equ LOCAL_I_RED, -36
# png_byte i_green
.equ LOCAL_I_GREEN, -37
# png_byte i_blue
.equ LOCAL_I_BLUE, -38

# %edi - png_color a
# %esi - uint32_t b
get_colour_distance:

    # Reserve space for 11 variables (aligned to 16 bytes):
    enter $0x30, $0
    # %edi - png_color a
    movl %edi, LOCAL_A(%rbp)
    # %esi - uint32_t b
    movl %esi, LOCAL_B(%rbp)

    # Extract RGB components of the desired RGBA colour value:
    movb LOCAL_A+0(%rbp), %al
    # %al - png_byte red
    movb %al, LOCAL_RED(%rbp)
    movb LOCAL_A+1(%rbp), %al
    # %al - png_byte green
    movb %al, LOCAL_GREEN(%rbp)
    movb LOCAL_A+2(%rbp), %al
    # %al - png_byte blue
    movb %al, LOCAL_BLUE(%rbp)

    # Extract RGB components of the tested RGB colour value:
    movl LOCAL_B(%rbp), %eax
    # %eax - uint32_t i_rgb_value
    andl $0x00ff0000, %eax
    shrl $16, %eax
    # %al - png_byte i_red
    movb %al, LOCAL_I_RED(%rbp)
    movl LOCAL_B(%rbp), %eax
    # %eax - uint32_t i_rgb_value
    andl $0x0000ff00, %eax
    shrl $8, %eax
    # %al - png_byte i_green
    movb %al, LOCAL_I_GREEN(%rbp)
    movl LOCAL_B(%rbp), %eax
    # %eax - uint32_t i_rgb_value
    andl $0x000000ff, %eax
    # %al - png_byte i_blue
    movb %al, LOCAL_I_BLUE(%rbp)

    # double diff_red = std::fabs(red - i_red);
    movb LOCAL_RED(%rbp), %dil
    movb LOCAL_I_RED(%rbp), %sil
    call abs_diff
    # %xmm0 - double diff_red
    movq %xmm0, LOCAL_DIFF_RED(%rbp)

    # double diff_green = std::fabs(green - i_green);
    movb LOCAL_GREEN(%rbp), %dil
    movb LOCAL_I_GREEN(%rbp), %sil
    call abs_diff
    # %xmm0 - double diff_green
    movq %xmm0, LOCAL_DIFF_GREEN(%rbp)

    # double diff_blue = std::fabs(blue - i_blue);
    movb LOCAL_BLUE(%rbp), %dil
    movb LOCAL_I_BLUE(%rbp), %sil
    call abs_diff
    # %xmm0 - double diff_blue
    movq %xmm0, LOCAL_DIFF_BLUE(%rbp)

    # Compute colour distance vector length:
    movq LOCAL_DIFF_RED(%rbp), %xmm0
    # %xmm0 - double x
    movq LOCAL_DIFF_GREEN(%rbp), %xmm1
    # %xmm1 - double y
    movq LOCAL_DIFF_BLUE(%rbp), %xmm2
    # %xmm2 - double z
    call vector_length
    # %xmm0 - double vector_length

    leave
    ret

# double abs_diff(uint8_t a, uint8_t b);
.type abs_diff, @function

# %dil - uint8_t a
# %sil - uint8_t b
abs_diff:

    andq $0x00000000000000ff, %rdi # %rdi = a
    cvtsi2sd %rdi, %xmm0           # %xmm0 = (double)a

    andq $0x00000000000000ff, %rsi # %rsi = b
    cvtsi2sd %rsi, %xmm1           # %xmm1 = (double)b

    # double diff = std::fabs(a - b);
    subsd %xmm1, %xmm0
    call fabs@plt
    # %xmm0 - double diff

    ret

# double vector_length(double x, double y, double z);
.type vector_length, @function

# %xmm0 - double x
# %xmm1 - double y
# %xmm2 - double z
vector_length:

    # %xmm0 = %xmm0 * %xmm0
    mulsd %xmm0, %xmm0
    # %xmm1 = %xmm1 * %xmm1
    mulsd %xmm1, %xmm1
    # %xmm2 = %xmm2 * %xmm2
    mulsd %xmm2, %xmm2

    # %xmm0 = %xmm0 + %xmm1 + %xmm2
    addsd %xmm1, %xmm0
    addsd %xmm2, %xmm0

    # %xmm0 = sqrt(%xmm0)
    sqrtsd %xmm0, %xmm0

    ret
