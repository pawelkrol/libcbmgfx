.include "const.s"

.section .data

# IFLIConfig fun_painter = {
#   "fun",              // format_description[4]
#   $3ff0,              // load_address
#   $839e,              // data_length
#   $2012,              // bitmap_1_offset
#   $0012,              // screens_1_offset
#   $63fa,              // bitmap_2_offset
#   $43fa,              // screens_2_offset
#   $4012,              // colours_offset
#   &get_d021_colours,  // get_d021_colours_fun_ptr
#   -1,                 // border_colour_offset
#   $0400,              // uint16_t screen_size
# };
.size fun_painter_config, IFLI_CONFIG_TOTAL_SIZE
.type fun_painter_config, @object
fun_painter_config:
    .ascii "fun\0"
    .2byte FUN_PAINTER_LOAD_ADDRESS
    .2byte FUN_PAINTER_DATA_LENGTH
    .2byte FUN_PAINTER_BITMAP_1_OFFSET
    .2byte FUN_PAINTER_SCREENS_1_OFFSET
    .2byte FUN_PAINTER_BITMAP_2_OFFSET
    .2byte FUN_PAINTER_SCREENS_2_OFFSET
    .2byte FUN_PAINTER_COLOURS_OFFSET
    .8byte get_d021_colours
    .2byte FUN_PAINTER_BORDER_COLOUR_OFFSET
    .2byte FUN_PAINTER_SCREEN_SIZE

.section .text

# IFLI *load_fun(Byte *data, uint64_t data_size);
.globl load_fun
.type load_fun, @function

# %rdi - Byte *data
# %rsi - uint64_t data_size
load_fun:

    call fun_config
    # %rax - IFLIConfig *fun_painter_config
    movq %rax, %rdx
    # %rdx - IFLIConfig *fun_painter_config
    jmp load_ifli
    # %rax - IFLI *ifli

# IFLIConfig *fun_config();
.globl fun_config
.type fun_config, @function

fun_config:

    leaq fun_painter_config(%rip), %rax
    # %rax - IFLIConfig *fun_painter_config

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

    # Copy 100x $d021 colours from $7f48-$7fab:
    movq LOCAL_D021_VALUES_PTR(%rbp), %rdi
    # %rdi - Byte d021_values[BITMAP_HEIGHT]
    addq $0x00, %rdi
    # %rdi = Byte d021_values[BITMAP_HEIGHT] = d021_values + 0
    movq LOCAL_DATA_PTR(%rbp), %rsi
    # %rsi - Byte *data
    addq $FUN_PAINTER_D021_COLOURS_1_OFFSET, %rsi
    # %rsi - Byte *data = data + 0x3f5a
    movq $0x64, %rcx
    # %rcx - uint64_t length = 100
    cld
    rep movsb

    # Copy 100x $d021 colours from $c328-$c38b:
    movq LOCAL_D021_VALUES_PTR(%rbp), %rdi
    # %rdi - Byte d021_values[BITMAP_HEIGHT]
    addq $0x64, %rdi
    # %rdi = Byte d021_values[BITMAP_HEIGHT] = d021_values + 100
    movq LOCAL_DATA_PTR(%rbp), %rsi
    # %rsi - Byte *data
    addq $FUN_PAINTER_D021_COLOURS_2_OFFSET, %rsi
    # %rsi - Byte *data = data + 0x833a
    movq $0x64, %rcx
    # %rcx - uint64_t length = 100
    cld
    rep movsb

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
