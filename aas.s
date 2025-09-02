.include "const.s"

.section .data

# MulticolourConfig advanced_art_studio = {
#   "aas",  // format_description[4]
#   $2000,  // load_address
#   $2722,  // data_length
#   $0002,  // bitmap_offset
#   $1f42,  // screen_offset
#   $233a,  // colours_offset
#   $272b,  // background_colour_offset
#   -1,     // border_colour_offset
# };
.size advanced_art_studio_config, MULTICOLOUR_CONFIG_TOTAL_SIZE
.type advanced_art_studio_config, @object
advanced_art_studio_config:
    .ascii "aas\0"
    .2byte ADVANCED_ART_STUDIO_LOAD_ADDRESS
    .2byte ADVANCED_ART_STUDIO_DATA_LENGTH
    .2byte ADVANCED_ART_STUDIO_BITMAP_OFFSET
    .2byte ADVANCED_ART_STUDIO_SCREEN_OFFSET
    .2byte ADVANCED_ART_STUDIO_COLOURS_OFFSET
    .2byte ADVANCED_ART_STUDIO_BACKGROUND_COLOUR_OFFSET
    .2byte ADVANCED_ART_STUDIO_BORDER_COLOUR_OFFSET

.section .text

# Multicolour *load_aas(Byte *data, uint64_t data_size);
.globl load_aas
.type load_aas, @function

# %rdi - Byte *data
# %rsi - uint64_t data_size
load_aas:

    call aas_config
    # %rax - MulticolourConfig *advanced_art_studio_config
    movq %rax, %rdx
    # %rdx - MulticolourConfig *advanced_art_studio_config
    jmp load_mcp
    # %rax - Multicolour *multicolour

# Byte *export_aas(Multicolour *multicolour);
.globl export_aas
.type export_aas, @function

# %rdi - Multicolour *multicolour
export_aas:

    call aas_config
    # %rax - MulticolourConfig *advanced_art_studio_config
    movq %rax, %rsi
    # %rsi - MulticolourConfig *advanced_art_studio_config
    jmp export_mcp
    # %rax - Byte *aas_data

# void delete_aas(Byte *aas_data);
.globl delete_aas
.type delete_aas, @function

# %rdi - Byte *aas_data
delete_aas:

    # Deallocate the AdvancedArtStudio data here, because of the fixed size of the exported AdvancedArtStudio "aas_data" array:
    # %rdi - Byte *aas_data
    call aas_config
    # %rax - MulticolourConfig *advanced_art_studio_config
    movzwq MULTICOLOUR_CONFIG_DATA_LENGTH_OFFSET(%rax), %rsi
    # %rsi - uint64_t length
    jmp free_with_zero_fill

# MulticolourConfig *aas_config();
.globl aas_config
.type aas_config, @function

aas_config:

    leaq advanced_art_studio_config(%rip), %rax
    # %rax - MulticolourConfig *advanced_art_studio_config

    ret
