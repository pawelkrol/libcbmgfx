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

# Byte *data
.equ LOCAL_DATA_PTR, -8
# uint64_t data_size
.equ LOCAL_DATA_SIZE, -16
# Byte *unpacked_data
.equ LOCAL_UNPACKED_DATA_PTR, -24
# IFLI *ifli
.equ LOCAL_IFLI_PTR, -32
# uint64_t unpacked_data_size
.equ LOCAL_UNPACKED_DATA_SIZE, -40

# %rdi - Byte *data
# %rsi - uint64_t data_size
load_fun:

    # Reserve space for 5 variables (aligned to 16 bytes):
    enter $0x30, $0
    # %rdi - Byte *data
    movq %rdi, LOCAL_DATA_PTR(%rbp)
    # %rsi - uint64_t data_size
    movq %rsi, LOCAL_DATA_SIZE(%rbp)

    # Check if we are dealing with the packed data:
    movq LOCAL_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *data
    cmpb $0, FUN_PAINTER_PACKED_FLAG_OFFSET(%rdi)
    # Byte packed_flag > 0
    ja __load_fun_1
    # Byte packed_flag == 0

    movq LOCAL_DATA_PTR(%rbp), %rax
    # %rax - Byte *data
    movq %rax, LOCAL_UNPACKED_DATA_PTR(%rbp)
    # Byte *unpacked_data = data
    movq LOCAL_DATA_SIZE(%rbp), %rax
    # %rax - uint64_t data_size
    movq %rax, LOCAL_UNPACKED_DATA_SIZE(%rbp)
    # uint64_t unpacked_data_size = data_size
    jmp __load_fun_2

__load_fun_1:

    movq LOCAL_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *data
    movq LOCAL_DATA_SIZE(%rbp), %rsi
    # %rsi - uint64_t data_size
    leaq LOCAL_UNPACKED_DATA_SIZE(%rbp), %rdx
    # %rdx - uint64_t *unpacked_data_size
    call unpack_fun
    # %rax - Byte *unpacked_data
    movq %rax, LOCAL_UNPACKED_DATA_PTR(%rbp)

__load_fun_2:

    movq LOCAL_UNPACKED_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *unpacked_data
    movq LOCAL_UNPACKED_DATA_SIZE(%rbp), %rsi
    # %rsi - uint64_t unpacked_data_size
    call fun_config
    # %rax - IFLIConfig *fun_painter_config
    movq %rax, %rdx
    # %rdx - IFLIConfig *fun_painter_config
    call load_ifli
    # %rax - IFLI *ifli
    movq %rax, LOCAL_IFLI_PTR(%rbp)

    # Check if the memory allocated to the unpacked data needs to be released:
    movq LOCAL_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *data
    cmpb $0, FUN_PAINTER_PACKED_FLAG_OFFSET(%rdi)
    # Byte packed_flag == 0
    jz __load_fun_3
    # Byte packed_flag > 0

    # Deallocate the temporarily unpacked FunPainter data:
    movq LOCAL_UNPACKED_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *unpacked_data
    movq LOCAL_UNPACKED_DATA_SIZE(%rbp), %rsi
    # %rsi - uint64_t unpacked_data_size
    call free_with_zero_fill

__load_fun_3:

    movq LOCAL_IFLI_PTR(%rbp), %rax
    # %rax - IFLI *ifli

    leave
    ret

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

# Byte *unpack_fun(Byte *data, uint64_t data_size, uint64_t *unpacked_data_size);
.type unpack_fun, @function

# Byte *data
.equ LOCAL_DATA_PTR, -8
# uint64_t data_size
.equ LOCAL_DATA_SIZE, -16
# uint64_t *unpacked_data_size
.equ LOCAL_UNPACKED_DATA_SIZE_PTR, -24
# Byte *unpacked_data
.equ LOCAL_UNPACKED_DATA_PTR, -32
# uint64_t data_offset
.equ LOCAL_DATA_OFFSET, -40
# uint64_t unpacked_data_offset
.equ LOCAL_UNPACKED_DATA_OFFSET, -48
# Byte escape
.equ LOCAL_ESCAPE, -49
# Byte next
.equ LOCAL_NEXT, -50
# Byte count
.equ LOCAL_COUNT, -51

# %rdi - Byte *data
# %rsi - uint64_t data_size
# %rdx - uint64_t *unpacked_data_size
unpack_fun:

    # Reserve space for 9 variables (aligned to 16 bytes):
    enter $0x40, $0
    # %rdi - Byte *data
    movq %rdi, LOCAL_DATA_PTR(%rbp)
    # %rsi - uint64_t data_size
    movq %rsi, LOCAL_DATA_SIZE(%rbp)
    # %rdx - uint64_t *unpacked_data_size
    movq %rdx, LOCAL_UNPACKED_DATA_SIZE_PTR(%rbp)

    # Byte *unpacked_data = malloc(FUN_PAINTER_DATA_LENGTH);
    # Byte escape = *(data + FUN_PAINTER_ESCAPE_BYTE_OFFSET);
    # strncpy(unpacked_data, data, 0x0010);
    # *(unpacked_data + 0x0011) = 0x00;
    # *(unpacked_data + 0x0012) = 0x00;
    # uint64_t data_offset = 0x0012;
    # uint64_t unpacked_data_offset = 0x0000;
    # while (data_offset < data_size) {
    #   Byte next = *(data + data_offset++);
    #   Byte count;
    #   if (next == escape) {
    #     count = *(data + data_offset++);
    #     next = *(data + data_offset++);
    #   }
    #   else {
    #     count = 1;
    #   }
    #   while (count--) {
    #     *(unpacked_data + unpacked_data_offset++) = next;
    #   }
    # }

    # Allocate memory to store the unpacked FunPainter data:
    movq $FUN_PAINTER_DATA_LENGTH, %rdi
    call malloc@plt
    # %rax - Byte *unpacked_data
    movq %rax, LOCAL_UNPACKED_DATA_PTR(%rbp)

    # Get escape byte for unpacking:
    movq LOCAL_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *data
    movb FUN_PAINTER_ESCAPE_BYTE_OFFSET(%rdi), %al
    # %al - Byte escape
    movb %al, LOCAL_ESCAPE(%rbp)

    # Copy header info:
    movq LOCAL_UNPACKED_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *unpacked_data
    movq LOCAL_DATA_PTR(%rbp), %rsi
    # %rsi - Byte *data
    movq $0x0010, %rcx
    # %rcx - uint64_t count
    cld
    rep movsb

    # Set packed flag:
    movq LOCAL_UNPACKED_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *unpacked_data
    movb $0x00, FUN_PAINTER_PACKED_FLAG_OFFSET(%rdi)
    # *(unpacked_data + 0x0011) = 0x00
    movb $0x00, FUN_PAINTER_ESCAPE_BYTE_OFFSET(%rdi)
    # *(unpacked_data + 0x0012) = 0x00

    movq $0x0012, LOCAL_DATA_OFFSET(%rbp)
    # uint64_t data_offset = 0x0012
    movq $0x0012, LOCAL_UNPACKED_DATA_OFFSET(%rbp)
    # uint64_t unpacked_data_offset = 0x0012

__unpack_fun_1:

    # Get next byte:
    movq LOCAL_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *data
    movq LOCAL_DATA_OFFSET(%rbp), %rcx
    # %rcx - uint64_t data_offset
    incq LOCAL_DATA_OFFSET(%rbp)
    # uint64_t data_offset += 1
    movb (%rdi, %rcx), %al
    # %al - Byte next
    movb %al, LOCAL_NEXT(%rbp)

    # Compare next byte with an escape byte:
    movb LOCAL_NEXT(%rbp), %al
    cmpb LOCAL_ESCAPE(%rbp), %al
    # next != escape
    jne __unpack_fun_2
    # next == escape

    # Get count byte:
    movq LOCAL_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *data
    movq LOCAL_DATA_OFFSET(%rbp), %rcx
    # %rcx - uint64_t data_offset
    incq LOCAL_DATA_OFFSET(%rbp)
    # uint64_t data_offset += 1
    movb (%rdi, %rcx), %al
    # %al - Byte count
    movb %al, LOCAL_COUNT(%rbp)

    # Get next byte:
    movq LOCAL_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *data
    movq LOCAL_DATA_OFFSET(%rbp), %rcx
    # %rcx - uint64_t data_offset
    incq LOCAL_DATA_OFFSET(%rbp)
    # uint64_t data_offset += 1
    movb (%rdi, %rcx), %al
    # %al - Byte next
    movb %al, LOCAL_NEXT(%rbp)

    jmp __unpack_fun_3

__unpack_fun_2:

    # Set count byte to 1:
    movb $1, LOCAL_COUNT(%rbp)
    # %al - Byte count = 1

__unpack_fun_3:

    # while (count--)
    cmpb $0, LOCAL_COUNT(%rbp)
    jz __unpack_fun_4
    decb LOCAL_COUNT(%rbp)

    # Copy count of next bytes into unpacked data:
    movq LOCAL_UNPACKED_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *unpacked_data
    movq LOCAL_UNPACKED_DATA_OFFSET(%rbp), %rcx
    # %rcx - uint64_t unpacked_data_offset
    movb LOCAL_NEXT(%rbp), %al
    # %al - Byte next
    movb %al, (%rdi, %rcx)

    incq LOCAL_UNPACKED_DATA_OFFSET(%rbp)
    # uint64_t unpacked_data_offset += 1

    jmp __unpack_fun_3

__unpack_fun_4:

    # while (data_offset < data_size)
    movq LOCAL_DATA_SIZE(%rbp), %rax
    cmpq %rax, LOCAL_DATA_OFFSET(%rbp)
    jb __unpack_fun_1

    movq LOCAL_UNPACKED_DATA_SIZE_PTR(%rbp), %rdi
    # %rdi - uint64_t *unpacked_data_size
    movq LOCAL_UNPACKED_DATA_OFFSET(%rbp), %rax
    # %rax - uint64_t unpacked_data_offset
    movq %rax, (%rdi)
    # *unpacked_data_size = unpacked_data_offset

    movq LOCAL_UNPACKED_DATA_PTR(%rbp), %rax
    # %rax - Byte *unpacked_data

    leave
    ret
