.include "const.s"

.section .data

# HiresConfig art_studio = {
#   "art",  // format_description[4]
#   $2000,  // load_address
#   $232a,  // data_length
#   $0002,  // bitmap_offset
#   $1f42,  // screen_offset
# };
.size art_studio_config, HIRES_CONFIG_TOTAL_SIZE
.type art_studio_config, @object
art_studio_config:
    .ascii "art\0"
    .2byte ART_STUDIO_LOAD_ADDRESS
    .2byte ART_STUDIO_DATA_LENGTH
    .2byte ART_STUDIO_BITMAP_OFFSET
    .2byte ART_STUDIO_SCREEN_OFFSET

.section .text

# Hires *load_art(Byte *data, uint64_t data_size);
.globl load_art
.type load_art, @function

# %rdi - Byte *data
# %rsi - uint64_t data_size
load_art:

    call art_config
    # %rax - HiresConfig *art_studio_config
    movq %rax, %rdx
    # %rdx - HiresConfig *art_studio_config
    jmp load_hpi
    # %rax - Hires *hires

# Byte *export_art(Hires *hires);
.globl export_art
.type export_art, @function

# %rdi - Hires *hires
export_art:

    call art_config
    # %rax - HiresConfig *art_studio_config
    movq %rax, %rsi
    # %rsi - HiresConfig *art_studio_config
    jmp export_hpi
    # %rax - Byte *art_data

# void delete_art(Byte *art_data);
.globl delete_art
.type delete_art, @function

# %rdi - Byte *art_data
delete_art:

    # Deallocate the ArtStudio data here, because of the fixed size of the exported ArtStudio "art_data" array:
    # %rdi - Byte *art_data
    call art_config
    # %rax - HiresConfig *art_studio_config
    movzwq HIRES_CONFIG_DATA_LENGTH_OFFSET(%rax), %rsi
    # %rsi - uint64_t length
    jmp free_with_zero_fill

# HiresConfig *art_config();
.globl art_config
.type art_config, @function

art_config:

    leaq art_studio_config(%rip), %rax
    # %rax - HiresConfig *art_studio_config

    ret
