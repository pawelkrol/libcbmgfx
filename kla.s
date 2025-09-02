.include "const.s"

.section .data

# MulticolourConfig koalapainter = {
#   "kla",  // format_description[4]
#   $6000,  // load_address
#   $2713,  // data_length
#   $0002,  // bitmap_offset
#   $1f42,  // screen_offset
#   $232a,  // colours_offset
#   $2712,  // background_colour_offset
#   -1,     // border_colour_offset
# };
.size koalapainter_config, MULTICOLOUR_CONFIG_TOTAL_SIZE
.type koalapainter_config, @object
koalapainter_config:
    .ascii "kla\0"
    .2byte KOALAPAINTER_LOAD_ADDRESS
    .2byte KOALAPAINTER_DATA_LENGTH
    .2byte KOALAPAINTER_BITMAP_OFFSET
    .2byte KOALAPAINTER_SCREEN_OFFSET
    .2byte KOALAPAINTER_COLOURS_OFFSET
    .2byte KOALAPAINTER_BACKGROUND_COLOUR_OFFSET
    .2byte KOALAPAINTER_BORDER_COLOUR_OFFSET

.section .text

# Multicolour *load_kla(Byte *data, uint64_t data_size);
.globl load_kla
.type load_kla, @function

# %rdi - Byte *data
# %rsi - uint64_t data_size
load_kla:

    call kla_config
    # %rax - MulticolourConfig *koalapainter_config
    movq %rax, %rdx
    # %rdx - MulticolourConfig *koalapainter_config
    jmp load_mcp
    # %rax - Multicolour *multicolour

# Byte *export_kla(Multicolour *multicolour);
.globl export_kla
.type export_kla, @function

# %rdi - Multicolour *multicolour
export_kla:

    call kla_config
    # %rax - MulticolourConfig *koalapainter_config
    movq %rax, %rsi
    # %rsi - MulticolourConfig *koalapainter_config
    jmp export_mcp
    # %rax - Byte *kla_data

# void delete_kla(Byte *kla_data);
.globl delete_kla
.type delete_kla, @function

# %rdi - Byte *kla_data
delete_kla:

    # Deallocate the KoalaPainter data here, because of the fixed size of the exported KoalaPainter "kla_data" array:
    # %rdi - Byte *kla_data
    call kla_config
    # %rax - MulticolourConfig *koalapainter_config
    movzwq MULTICOLOUR_CONFIG_DATA_LENGTH_OFFSET(%rax), %rsi
    # %rsi - uint64_t length
    jmp free_with_zero_fill

# MulticolourConfig *kla_config();
.globl kla_config
.type kla_config, @function

kla_config:

    leaq koalapainter_config(%rip), %rax
    # %rax - MulticolourConfig *koalapainter_config

    ret
