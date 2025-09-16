.include "const.s"

.section .data

# FLIConfig fli_designer = {
#   "fd2",              // format_description[4]
#   $3c00,              // load_address
#   $4401,              // data_length
#   $2402,              // bitmap_offset
#   $0402,              // screens_offset
#   $0002,              // colours_offset
#   -1,                 // border_colour_offset
#   $0400,              // uint16_t screen_size
#   &get_d021_colours,  // get_d021_colours_fun_ptr
# };
.size fli_designer_config, FLI_CONFIG_TOTAL_SIZE
.type fli_designer_config, @object
fli_designer_config:
    .ascii "fd2\0"
    .2byte FLI_DESIGNER_LOAD_ADDRESS
    .2byte FLI_DESIGNER_DATA_LENGTH
    .2byte FLI_DESIGNER_BITMAP_OFFSET
    .2byte FLI_DESIGNER_SCREENS_OFFSET
    .2byte FLI_DESIGNER_COLOURS_OFFSET
    .2byte FLI_DESIGNER_BORDER_COLOUR_OFFSET
    .2byte FLI_DESIGNER_SCREEN_SIZE
    .8byte get_d021_colours

.section .text

# FLI *load_fd2(Byte *data, uint64_t data_size);
.globl load_fd2
.type load_fd2, @function

# %rdi - Byte *data
# %rsi - uint64_t data_size
load_fd2:

    call fd2_config
    # %rax - FLIConfig *fli_designer_config
    movq %rax, %rdx
    # %rdx - FLIConfig *fli_designer_config
    jmp load_fli
    # %rax - FLI *fli

# FLIConfig *fd2_config();
.globl fd2_config
.type fd2_config, @function

fd2_config:

    leaq fli_designer_config(%rip), %rax
    # %rax - FLIConfig *fli_designer_config

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

    # Set 200x default background $d021 colours:
    movq LOCAL_D021_VALUES_PTR(%rbp), %rdi
    # %rdi - Byte d021_values[BITMAP_HEIGHT]
    movq $BITMAP_HEIGHT, %rcx
    # %rcx - uint64_t length = 200
    movb $DEFAULT_BACKGROUND_COLOUR, %al
    # %al - DEFAULT_BACKGROUND_COLOUR
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
