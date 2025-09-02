.include "const.s"

.section .data

# MulticolourConfig facepainter_config = {
#   "fcp",  // format_description[4]
#   $4000,  // load_address
#   $2714,  // data_length
#   $0002,  // bitmap_offset
#   $1f42,  // screen_offset
#   $232a,  // colours_offset
#   $2713,  // background_colour_offset
#   $2712,  // border_colour_offset
# };
.size facepainter_config, MULTICOLOUR_CONFIG_TOTAL_SIZE
.type facepainter_config, @object
facepainter_config:
    .ascii "fcp\0"
    .2byte FACEPAINTER_LOAD_ADDRESS
    .2byte FACEPAINTER_DATA_LENGTH
    .2byte FACEPAINTER_BITMAP_OFFSET
    .2byte FACEPAINTER_SCREEN_OFFSET
    .2byte FACEPAINTER_COLOURS_OFFSET
    .2byte FACEPAINTER_BACKGROUND_COLOUR_OFFSET
    .2byte FACEPAINTER_BORDER_COLOUR_OFFSET

.section .text

# Multicolour *load_fcp(Byte *fcp_data, uint64_t data_size);
.globl load_fcp
.type load_fcp, @function

# %rdi - Byte *fcp_data
# %rsi - uint64_t data_size
load_fcp:

    call fcp_config
    # %rax - MulticolourConfig *facepainter_config
    movq %rax, %rdx
    # %rdx - MulticolourConfig *facepainter_config
    jmp load_mcp
    # %rax - Multicolour *multicolour

# Byte *export_fcp(Multicolour *multicolour);
.globl export_fcp
.type export_fcp, @function

# %rdi - Multicolour *multicolour
mcp_get_border_colour:

    # %rdi - Multicolour *multicolour
    movb MULTICOLOUR_BORDER_COLOUR_OFFSET(%rdi), %al
    # %al - Byte border_colour

    ret

# %rdi - Multicolour *multicolour
export_fcp:

    call fcp_config
    # %rax - MulticolourConfig *facepainter_config
    movq %rax, %rsi
    # %rsi - MulticolourConfig *facepainter_config
    jmp export_mcp
    # %rax - Byte *fcp_data

# void delete_fcp(Byte *fcp_data);
.globl delete_fcp
.type delete_fcp, @function

# %rdi - Byte *fcp_data
delete_fcp:

    # Deallocate the FacePainter data here, because of the fixed size of the exported FacePainter "fcp_data" array:
    # %rdi - Byte *fcp_data
    call fcp_config
    # %rax - MulticolourConfig *facepainter_config
    movzwq MULTICOLOUR_CONFIG_DATA_LENGTH_OFFSET(%rax), %rsi
    # %rsi - uint64_t length
    jmp free_with_zero_fill

# MulticolourConfig *fcp_config();
.globl fcp_config
.type fcp_config, @function

fcp_config:

    leaq facepainter_config(%rip), %rax
    # %rax - MulticolourConfig *facepainter_config

    ret
