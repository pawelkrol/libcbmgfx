.include "const.s"

.section .text

# Array<Screen> new_screen_array(
#   std::size_t length,
#   std::size_t screen_size,
#   Byte *data,
# );
.globl new_screen_array
.type new_screen_array, @function

# std::size_t length
.equ LOCAL_LENGTH, -8
# std::size_t screen_size
.equ LOCAL_SCREEN_SIZE, -16
# Byte *data
.equ LOCAL_DATA_PTR, -24
# std::size_t size
.equ LOCAL_SIZE, -32
# std::size_t data_offsets[length]
.equ LOCAL_DATA_OFFSETS_PTR, -40
# uint64_t i
.equ LOCAL_I, -48
# Array<Screen> screen_array
.equ LOCAL_SCREEN_ARRAY_PTR, -56

# %rdi - std::size_t length
# %rsi - std::size_t screen_size
# %rdx - Byte *data
new_screen_array:

    # Reserve space for 7 variables (aligned to 16 bytes):
    enter $0x40, $0
    # %rdi - std::size_t length
    movq %rdi, LOCAL_LENGTH(%rbp)
    # %rsi - std::size_t screen_size
    movq %rsi, LOCAL_SCREEN_SIZE(%rbp)
    # %rdx - Byte *data
    movq %rdx, LOCAL_DATA_PTR(%rbp)

    # std::size_t data_offsets[length] = {};
    #
    # for (uint64_t i = 0; i < length; ++i) {
    #   data_offsets[i] = screen_size * i;
    # }
    #
    # Array<Screen> screen_array = new_screen_array_from_data(
    #   length,
    #   data_offsets,
    #   data,
    # );

    # Compute memory size of data_offsets[length] array:
    movq LOCAL_LENGTH(%rbp), %rax
    # %rax - std::size_t length
    movq $SIZE_OF_UINT64_T, %rcx
    # %rcx - SIZE_OF_UINT64_T
    mulq %rcx
    # %rax - std::size_t size = length * SIZE_OF_UINT64_T
    movq %rax, LOCAL_SIZE(%rbp)

    # Allocate memory to store the data offsets:
    movq LOCAL_SIZE(%rbp), %rdi
    # %rdi - std::size_t size
    call malloc@plt
    # %rax - std::size_t data_offsets[length]
    movq %rax, LOCAL_DATA_OFFSETS_PTR(%rbp)

    movq $0, LOCAL_I(%rbp)
    # uint64_t i = 0

__new_screen_array_1:

    # Compute data offset at index i:
    movq LOCAL_SCREEN_SIZE(%rbp), %rax
    # %rax - std::size_t screen_size
    mulq LOCAL_I(%rbp)
    # %rax - std::size_t data_offset = screen_size * i
    movq LOCAL_I(%rbp), %rcx
    # %rcx - uint64_t i
    movq LOCAL_DATA_OFFSETS_PTR(%rbp), %rdi
    # %rdi - std::size_t data_offsets[length]
    movq %rax, (%rdi, %rcx, SIZE_OF_UINT64_T)
    # data_offsets[i] = screen_size * i

    # while i < length
    incq LOCAL_I(%rbp)
    movq LOCAL_I(%rbp), %rax
    cmpq LOCAL_LENGTH(%rbp), %rax
    jb __new_screen_array_1

    movq LOCAL_LENGTH(%rbp), %rdi
    # %rdi - std::size_t length
    movq LOCAL_DATA_OFFSETS_PTR(%rbp), %rsi
    # %rsi - std::size_t data_offsets[length]
    movq LOCAL_DATA_PTR(%rbp), %rdx
    # %rdx - Byte *data
    call new_screen_array_from_data
    # %rax - Array<Screen> screen_array
    movq %rax, LOCAL_SCREEN_ARRAY_PTR(%rbp)

    # Deallocate an array holding the data offsets:
    movq LOCAL_DATA_OFFSETS_PTR(%rbp), %rdi
    # %rdi - std::size_t data_offsets[length]
    movq LOCAL_SIZE(%rbp), %rsi
    # %rsi - std::size_t size
    call free_with_zero_fill

    movq LOCAL_SCREEN_ARRAY_PTR(%rbp), %rax
    # %rax - Array<Screen> screen_array

    leave
    ret

# Array<Screen> new_screen_array_from_data(
#   std::size_t length,
#   std::size_t data_offsets[length],
#   Byte *data,
# );
.type new_screen_array_from_data, @function

# std::size_t length
.equ LOCAL_LENGTH, -8
# std::size_t data_offsets[length]
.equ LOCAL_DATA_OFFSETS_PTR, -16
# Byte *data
.equ LOCAL_DATA_PTR, -24
# std::size_t size
.equ LOCAL_SIZE, -32
# Screen *screens[length]
.equ LOCAL_SCREENS_PTR, -40
# std::size_t data_offset
.equ LOCAL_DATA_OFFSET, -48
# Array<Screen> screen_array
.equ LOCAL_SCREEN_ARRAY_PTR, -56
# uint64_t i
.equ LOCAL_I, -64

# %rdi - std::size_t length
# %rsi - std::size_t data_offsets[length]
# %rdx - Byte *data
new_screen_array_from_data:

    # Reserve space for 8 variables (aligned to 16 bytes):
    enter $0x40, $0
    # %rdi - std::size_t length
    movq %rdi, LOCAL_LENGTH(%rbp)
    # %rsi - std::size_t data_offsets[length]
    movq %rsi, LOCAL_DATA_OFFSETS_PTR(%rbp)
    # %rdx - Byte *data
    movq %rdx, LOCAL_DATA_PTR(%rbp)

    # Screen *screens[length] = {};
    #
    # for (uint64_t i = 0; i < length; ++i) {
    #   std::size_t data_offset = data_offsets[i];
    #   Byte *screen_data = data + data_offset;
    #   screens[i] = new_screen(screen_data);
    # }
    #
    # Array<Screen> screen_array = new_screen_array_from_screens(
    #   length,
    #   screens,
    # );

    # Compute memory size of screens[length] array:
    movq LOCAL_LENGTH(%rbp), %rax
    # %rax - std::size_t length
    movq $SIZE_OF_POINTER, %rcx
    # %rcx - SIZE_OF_POINTER
    mulq %rcx
    # %rax - std::size_t size = length * SIZE_OF_POINTER
    movq %rax, LOCAL_SIZE(%rbp)

    # Allocate memory to store screen data offsets:
    movq LOCAL_SIZE(%rbp), %rdi
    # %rdi - std::size_t size
    call malloc@plt
    # %rax - Screen *screens[length]
    movq %rax, LOCAL_SCREENS_PTR(%rbp)

    movq $0, LOCAL_I(%rbp)
    # uint64_t i = 0

__new_screen_array_from_data_1:

    # Retrieve screen data offset at index i:
    movq LOCAL_DATA_OFFSETS_PTR(%rbp), %rdi
    # %rdi - std::size_t data_offsets[length]
    movq LOCAL_I(%rbp), %rcx
    # %rcx - uint64_t i
    movq (%rdi, %rcx, SIZE_OF_UINT64_T), %rax
    # %rax - std::size_t data_offset = data_offsets[i]
    movq %rax, LOCAL_DATA_OFFSET(%rbp)

    # Create new screen with ith screen data:
    movq LOCAL_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *data
    addq LOCAL_DATA_OFFSET(%rbp), %rdi
    # %rdi - Byte *screen_data = data + data_offset
    call new_screen
    # %rax - Screen *screen = new_screen(screen_data)
    movq LOCAL_I(%rbp), %rcx
    # %rcx - uint64_t i
    movq LOCAL_SCREENS_PTR(%rbp), %rdi
    # %rdi - Screen *screens[length]
    movq %rax, (%rdi, %rcx, SIZE_OF_POINTER)
    # screens[i] = screen

    # while i < length
    incq LOCAL_I(%rbp)
    movq LOCAL_I(%rbp), %rax
    cmpq LOCAL_LENGTH(%rbp), %rax
    jb __new_screen_array_from_data_1

    movq LOCAL_LENGTH(%rbp), %rdi
    # %rdi - std::size_t length
    movq LOCAL_SCREENS_PTR(%rbp), %rsi
    # %rsi - Screen *screens[length]
    call new_screen_array_from_screens
    # %rax - Array<Screen> screen_array
    movq %rax, LOCAL_SCREEN_ARRAY_PTR(%rbp)

    # Deallocate an array holding screen data offsets:
    movq LOCAL_SCREENS_PTR(%rbp), %rdi
    # %rdi - Screen *screens[length]
    movq LOCAL_SIZE(%rbp), %rsi
    # %rsi - std::size_t size
    call free_with_zero_fill

    movq LOCAL_SCREEN_ARRAY_PTR(%rbp), %rax
    # %rax - Array<Screen> screen_array

    leave
    ret

# Array<Screen> *new_screen_array_from_screens(
#   std::size_t length,
#   Screen *screens[length],
# );
.type new_screen_array_from_screens, @function

# std::size_t length
.equ LOCAL_LENGTH, -8
# Screen *screens[length]
.equ LOCAL_SCREENS_PTR, -16

# %rdi - std::size_t length
# %rsi - Screen *screens[length]
new_screen_array_from_screens:

    # Reserve space for 2 variables (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - std::size_t length
    movq %rdi, LOCAL_LENGTH(%rbp)
    # %rsi - Screen *screens[length]
    movq %rsi, LOCAL_SCREENS_PTR(%rbp)

    # Array<Screen> *screen_array = new_array(
    #   length,
    #   &move_screen,
    #   &delete_screen,
    #   screens,
    # );

    movq LOCAL_LENGTH(%rbp), %rdi
    # %rdi - std::size_t length
    leaq move_screen(%rip), %rsi
    # %rsi - Screen *(*move_screen)(Screen *)
    call get_delete_screen@plt
    # %rax - void(*delete_screen)(Screen *)
    movq %rax, %rdx
    # %rdx - void(*delete_screen)(Screen *)
    movq LOCAL_SCREENS_PTR(%rbp), %rcx
    # %rcx - Screen *screens[length]
    call new_array
    # %rax - Array<Screen> screen_array

    leave
    ret

# Screen *move_screen(Screen *);
.type move_screen, @function

# %rdi - Screen *screen
move_screen:

    movq %rdi, %rax
    # %rax - Screen *screen

    ret
