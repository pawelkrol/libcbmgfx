.include "const.s"

.section .data

# FLIConfig fli_designer = {
#   "fd2",  // format_description[4]
#   $3c00,  // load_address
#   $4401,  // data_length
#   $2402,  // bitmap_offset
#   $0402,  // screens_offset
#   $0002,  // colours_offset
#   -1,     // background_colour_offset
#   -1,     // border_colour_offset
#   $0400,  // uint16_t screen_size
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
    .2byte FLI_DESIGNER_BACKGROUND_COLOUR_OFFSET
    .2byte FLI_DESIGNER_BORDER_COLOUR_OFFSET
    .2byte FLI_DESIGNER_SCREEN_SIZE

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
