.include "const.s"

.section .data

# IFLIConfig gun_painter = {
#   "gun",              // format_description[4]
#   $4000,              // load_address
#   $8343,              // data_length
#   $2002,              // bitmap_1_offset
#   $0002,              // screens_1_offset
#   $6402,              // bitmap_2_offset
#   $4402,              // screens_2_offset
#   $4002,              // colours_offset
#   &get_d021_colours,  // get_d021_colours_gun_ptr
#   -1,                 // border_colour_offset
#   $0400,              // uint16_t screen_size
# };
.size gun_painter_config, IFLI_CONFIG_TOTAL_SIZE
.type gun_painter_config, @object
gun_painter_config:
    .ascii "gun\0"
    .2byte GUN_PAINTER_LOAD_ADDRESS
    .2byte GUN_PAINTER_DATA_LENGTH
    .2byte GUN_PAINTER_BITMAP_1_OFFSET
    .2byte GUN_PAINTER_SCREENS_1_OFFSET
    .2byte GUN_PAINTER_BITMAP_2_OFFSET
    .2byte GUN_PAINTER_SCREENS_2_OFFSET
    .2byte GUN_PAINTER_COLOURS_OFFSET
    .8byte get_d021_colours
    .2byte GUN_PAINTER_BORDER_COLOUR_OFFSET
    .2byte GUN_PAINTER_SCREEN_SIZE

.section .text

# IFLI *load_gun(Byte *data, uint64_t data_size);
.globl load_gun
.type load_gun, @function

# %rdi - Byte *data
# %rsi - uint64_t data_size
load_gun:

    call gun_config
    # %rax - IFLIConfig *gun_painter_config
    movq %rax, %rdx
    # %rdx - IFLIConfig *gun_painter_config
    jmp load_ifli
    # %rax - IFLI *ifli

# IFLIConfig *gun_config();
.globl gun_config
.type gun_config, @function

gun_config:

    leaq gun_painter_config(%rip), %rax
    # %rax - IFLIConfig *gun_painter_config

    ret

# ByteArray *get_d021_colours(Byte *data);
.type get_d021_colours, @function

# Byte *data
.equ LOCAL_DATA_PTR, -8
# Byte d021_values[BITMAP_HEIGHT]
.equ LOCAL_D021_VALUES_PTR, -16
# ByteArray d021_colours[BITMAP_HEIGHT]
.equ LOCAL_D021_COLOURS_PTR, -24

# %rdi - Byte *data
get_d021_colours:

    # Reserve space for 3 variables (aligned to 16 bytes):
    enter $0x20, $0
    # %rdi - Byte *data
    movq %rdi, LOCAL_DATA_PTR(%rbp)

    # Allocate memory to store a temporary sequence of $d021 values:
    movq $BITMAP_HEIGHT, %rdi
    call malloc@plt
    # %rax - Byte d021_values[BITMAP_HEIGHT]
    movq %rax, LOCAL_D021_VALUES_PTR(%rbp)

    # Copy 177x $d021 colours from $7f4f-$7fff:
    movq LOCAL_D021_VALUES_PTR(%rbp), %rdi
    # %rdi - Byte d021_values[BITMAP_HEIGHT]
    addq $0x00, %rdi
    # %rdi = Byte d021_values[BITMAP_HEIGHT] = d021_values + 0
    movq LOCAL_DATA_PTR(%rbp), %rsi
    # %rsi - Byte *data
    addq $GUN_PAINTER_D021_COLOURS_1_OFFSET, %rsi
    # %rsi - Byte *data = data + 0x3f51
    movq $0xb1, %rcx
    # %rcx - uint64_t length = 177
    cld
    rep movsb

    # Copy 20x $d021 colours from $87e8-$87fb:
    movq LOCAL_D021_VALUES_PTR(%rbp), %rdi
    # %rdi - Byte d021_values[BITMAP_HEIGHT]
    addq $0xb1, %rdi
    # %rdi = Byte d021_values[BITMAP_HEIGHT] = d021_values + 177
    movq LOCAL_DATA_PTR(%rbp), %rsi
    # %rsi - Byte *data
    addq $GUN_PAINTER_D021_COLOURS_2_OFFSET, %rsi
    # %rsi - Byte *data = data + 0x47ea
    movq $0x14, %rcx
    # %rcx - uint64_t length = 20
    cld
    rep movsb

    # Copy 3x $d021 colours from $87fb:
    movq LOCAL_D021_VALUES_PTR(%rbp), %rdi
    # %rdi - Byte d021_values[BITMAP_HEIGHT]
    addq $0xc5, %rdi
    # %rdi = Byte d021_values[BITMAP_HEIGHT] = d021_values + 197
    movq LOCAL_DATA_PTR(%rbp), %rsi
    # %rsi - Byte *data
    addq $GUN_PAINTER_D021_COLOURS_3_OFFSET, %rsi
    # %rsi - Byte *data = data + 0x47fd
    movq (%rsi), %rax
    # %rax - Byte d021_value = *data
    movq $0x03, %rcx
    # %rcx - uint64_t length = 3
    cld
    rep stosb

    movq $BITMAP_HEIGHT, %rdi
    # %rdi - std::size_t length = BITMAP_HEIGHT
    movq LOCAL_D021_VALUES_PTR(%rbp), %rsi
    # %rsi - Byte d021_values[BITMAP_HEIGHT]
    call new_byte_array
    # %rax - ByteArray d021_colours[BITMAP_HEIGHT]
    movq %rax, LOCAL_D021_COLOURS_PTR(%rbp)

    # Deallocate a temporary sequence of $d021 values:
    movq LOCAL_D021_VALUES_PTR(%rbp), %rdi
    # %rdi - Byte d021_values[BITMAP_HEIGHT]
    movq $BITMAP_HEIGHT, %rsi
    # %rsi - uint64_t length = BITMAP_HEIGHT
    call free_with_zero_fill

    movq LOCAL_D021_COLOURS_PTR(%rbp), %rax
    # %rax - ByteArray d021_colours[BITMAP_HEIGHT]

    leave
    ret
