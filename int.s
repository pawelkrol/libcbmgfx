.include "const.s"

.section .data

longest_vector_length:
    .8byte 0x00000000ffffffff

zero:
    .double 0.0

.section .text

# Byte interpolate_rgb_colour(
#   PixelMap *pixel_map,
#   uint16_t x,
#   uint16_t y,
#   Byte accepted_interpolate_colours[max_count],
#   uint8_t max_count,
# );
.globl interpolate_rgb_colour
.type interpolate_rgb_colour, @function

# PixelMap *pixel_map
.equ LOCAL_PIXEL_MAP_PTR, -8
# Byte accepted_interpolate_colours[max_count]
.equ LOCAL_ACCEPTED_INTERPOLATE_COLOURS_PTR, -16
# ColourPalette *colour_palette
.equ LOCAL_COLOUR_PALETTE_PTR, -24
# double shortest_vector_length
.equ LOCAL_SHORTEST_VECTOR_LENGTH, -32
# double vector_length
.equ LOCAL_VECTOR_LENGTH, -40
# png_color original_rgb_value
.equ LOCAL_ORIGINAL_RGB_VALUE, -44
# uint32_t rgb_value
.equ LOCAL_RGB_VALUE, -48
# uint16_t x
.equ LOCAL_X, -50
# uint16_t y
.equ LOCAL_Y, -52
# uint8_t max_count
.equ LOCAL_MAX_COUNT, -53
# Byte interpolated_cbm_value
.equ LOCAL_INTERPOLATED_CBM_VALUE, -54
# uint8_t i
.equ LOCAL_I, -55
# Byte cbm_value
.equ LOCAL_CBM_VALUE, -56

# %rdi - PixelMap *pixel_map
# %si - uint16_t x
# %dx - uint16_t y
# %rcx - Byte accepted_interpolate_colours[max_count]
# %r8b - uint8_t max_count
interpolate_rgb_colour:

    # Reserve space for 13 variables (aligned to 16 bytes):
    enter $0x40, $0
    # %rdi - PixelMap *pixel_map
    movq %rdi, LOCAL_PIXEL_MAP_PTR(%rbp)
    # %si - uint16_t x
    movw %si, LOCAL_X(%rbp)
    # %dx - uint16_t y
    movw %dx, LOCAL_Y(%rbp)
    # %rcx - Byte accepted_interpolate_colours[max_count]
    movq %rcx, LOCAL_ACCEPTED_INTERPOLATE_COLOURS_PTR(%rbp)
    # %r8b - uint8_t max_count
    movb %r8b, LOCAL_MAX_COUNT(%rbp)

    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    movw LOCAL_X(%rbp), %si
    # %si - uint16_t x
    movw LOCAL_Y(%rbp), %dx
    # %dx - uint16_t y
    call pix_get_original_rgb_colour_at
    # %eax - png_color original_rgb_value
    movl %eax, LOCAL_ORIGINAL_RGB_VALUE(%rbp)

    movq LOCAL_PIXEL_MAP_PTR(%rbp), %rdi
    # %rdi - PixelMap *pixel_map
    call pix_get_colour_palette
    # %rax - ColourPalette *colour_palette
    movq %rax, LOCAL_COLOUR_PALETTE_PTR(%rbp)

    # double shortest_vector_length = (double)0xffffffff;
    # Byte interpolated_cbm_value;
    #
    # for (uint8_t i = 0; i < max_count; ++i) {
    #   Byte cbm_value = accepted_interpolate_colours[i];
    #   uint32_t rgb_value = get_rgb_colour(cbm_value, colour_palette);
    #   double vector_length = get_colour_distance(original_rgb_value, rgb_value);
    #
    #   if (vector_length < shortest_vector_length) {
    #     shortest_vector_length = vector_length;
    #     interpolated_cbm_value = cbm_value;
    #   }
    # }

    movq longest_vector_length(%rip), %rax
    # %rax - uint64_t shortest_vector_length = 0xffffffff
    cvtsi2sd %rax, %xmm0
    # %xmm0 - double shortest_vector_length = (double)0xffffffff
    movq %xmm0, LOCAL_SHORTEST_VECTOR_LENGTH(%rbp)

    movb $0, LOCAL_I(%rbp) # uint8_t i = 0

__interpolate_rgb_colour_1:

    movq LOCAL_ACCEPTED_INTERPOLATE_COLOURS_PTR(%rbp), %rdi
    # %rdi - Byte accepted_interpolate_colours[max_count]
    movzbq LOCAL_I(%rbp), %rcx
    # %rcx - uint8_t i
    movb (%rdi, %rcx), %al
    # %al - Byte cbm_value = accepted_interpolate_colours[i]
    movb %al, LOCAL_CBM_VALUE(%rbp)

    movb LOCAL_CBM_VALUE(%rbp), %dil
    # %dil - Byte cbm_value
    movq LOCAL_COLOUR_PALETTE_PTR(%rbp), %rsi
    # %rsi - ColourPalette *colour_palette
    call get_rgb_colour
    # %eax - uint32_t rgb_value
    movl %eax, LOCAL_RGB_VALUE(%rbp)

    movl LOCAL_ORIGINAL_RGB_VALUE(%rbp), %edi
    # %edi - png_color original_rgb_value
    movl LOCAL_RGB_VALUE(%rbp), %esi
    # %esi - uint32_t rgb_value
    call get_colour_distance
    # %xmm0 - double vector_length
    movq %xmm0, LOCAL_VECTOR_LENGTH(%rbp)

    movq LOCAL_VECTOR_LENGTH(%rbp), %xmm0
    # %xmm0 - double vector_length
    movq LOCAL_SHORTEST_VECTOR_LENGTH(%rbp), %xmm1
    # %xmm1 - double shortest_vector_length
    cmpltsd %xmm1, %xmm0 # %xmm0 < %xmm1
    # if true %xmm0 = -1 else %xmm0 = 0
    movq %xmm0, %rax
    cmpq $0, %rax
    jz __interpolate_rgb_colour_2

    movq LOCAL_VECTOR_LENGTH(%rbp), %xmm0
    # %xmm0 - double vector_length
    movq %xmm0, LOCAL_SHORTEST_VECTOR_LENGTH(%rbp)
    # shortest_vector_length = vector_length

    movb LOCAL_CBM_VALUE(%rbp), %al
    # %al - Byte cbm_value
    movb %al, LOCAL_INTERPOLATED_CBM_VALUE(%rbp)
    # interpolated_cbm_value = cbm_value

    # If distance == 0, end comparison immediately, as we already have got a perfect match:
    movq zero(%rip), %xmm0
    # %xmm0 = (double)0.0
    movq LOCAL_VECTOR_LENGTH(%rbp), %xmm1
    # %xmm1 = vector_length
    cmpeqsd %xmm1, %xmm0 # %xmm0 == %xmm1
    # if true %xmm0 = -1 else %xmm0 = 0
    movq %xmm0, %rax
    cmpq $0, %rax
    jnz __interpolate_rgb_colour_3

__interpolate_rgb_colour_2:

    incb LOCAL_I(%rbp) # ++i
    movb LOCAL_MAX_COUNT(%rbp), %al
    cmpb %al, LOCAL_I(%rbp) # i < max_count
    jb __interpolate_rgb_colour_1

__interpolate_rgb_colour_3:

    movb LOCAL_INTERPOLATED_CBM_VALUE(%rbp), %al
    # %al - Byte interpolated_cbm_value

    leave
    ret
