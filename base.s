.include "const.s"

.section .text

# BaseImage *new_base_image(
#   Byte *bitmap_data,
#   Byte *screen_data,
#   std::size_t screen_count,
#   std::size_t screen_size,
#   std::size_t screen_data_length,
# );
.globl new_base_image
.type new_base_image, @function

# Byte bitmap_data[$BITMAP_DATA_LENGTH]
.equ LOCAL_BITMAP_DATA_PTR, -8
# Byte screen_data[screen_size * screen_count]
.equ LOCAL_SCREEN_DATA_PTR, -16
# BaseImage *base_image
.equ LOCAL_BASE_IMAGE_PTR, -24
# std::size_t screen_count
.equ LOCAL_SCREEN_COUNT, -32
# std::size_t screen_size
.equ LOCAL_SCREEN_SIZE, -40
# std::size_t screen_data_length
.equ LOCAL_SCREEN_DATA_LENGTH, -48

# %rdi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
# %rsi - Byte screen_data[screen_size * screen_count]
# %rdx - std::size_t screen_count
# %rcx - std::size_t screen_size
# %r8 - std::size_t screen_data_length
new_base_image:

    # Reserve space for 6 variables (aligned to 16 bytes):
    enter $0x30, $0
    # %rdi - Byte bitmap_data[$BITMAP_DATA_LENGTH]
    movq %rdi, LOCAL_BITMAP_DATA_PTR(%rbp)
    # %rsi - Byte screen_data[screen_size * screen_count]
    movq %rsi, LOCAL_SCREEN_DATA_PTR(%rbp)
    # %rdx - std::size_t screen_count
    movq %rdx, LOCAL_SCREEN_COUNT(%rbp)
    # %rcx - std::size_t screen_size
    movq %rcx, LOCAL_SCREEN_SIZE(%rbp)
    # %r8 - std::size_t screen_data_length
    movq %r8, LOCAL_SCREEN_DATA_LENGTH(%rbp)

    # Allocate memory to store the new BaseImage object:
    movq $BASE_IMAGE_TOTAL_SIZE, %rdi
    call malloc@plt
    # %rax - BaseImage *base_image
    movq %rax, LOCAL_BASE_IMAGE_PTR(%rbp)

    # Allocate and initialise the member variable - std::size_t *base_image->screen_data_length
    movq LOCAL_SCREEN_DATA_LENGTH(%rbp), %rax
    # %rax - std::size_t screen_data_length
    movq LOCAL_BASE_IMAGE_PTR(%rbp), %rdi
    # %rdi - BaseImage *base_image
    movq %rax, BASE_IMAGE_SCREEN_DATA_LENGTH_OFFSET(%rdi)

    # Allocate and initialise the member variable - std::size_t *base_image->screen_count
    movq LOCAL_SCREEN_COUNT(%rbp), %rax
    # %rax - std::size_t screen_count
    movq LOCAL_BASE_IMAGE_PTR(%rbp), %rdi
    # %rdi - BaseImage *base_image
    movq %rax, BASE_IMAGE_SCREEN_COUNT_OFFSET(%rdi)

    # Allocate and initialise the member variable - ByteArray *base_image->original_bitmap_data
    movq $BITMAP_DATA_LENGTH, %rdi
    # %rdi - uint64_t length
    movq LOCAL_BITMAP_DATA_PTR(%rbp), %rsi
    # %rsi - Byte *bitmap_data
    call new_byte_array
    # %rax - ByteArray *original_bitmap_data
    movq LOCAL_BASE_IMAGE_PTR(%rbp), %rdi
    # %rdi - BaseImage *base_image
    movq %rax, BASE_IMAGE_BITMAP_DATA_BYTES_PTR_OFFSET(%rdi)

    # Allocate and initialise the member variable - ByteArray *base_image->original_screen_data
    movq LOCAL_BASE_IMAGE_PTR(%rbp), %rdi
    # %rdi - BaseImage *base_image
    call base_image_get_screen_data_length
    # %rax - std::size_t screen_data_length
    movq %rax, %rdi
    # %rdi - uint64_t length = screen_data_length
    movq LOCAL_SCREEN_DATA_PTR(%rbp), %rsi
    # %rsi - Byte *screen_data
    call new_byte_array
    # %rax - ByteArray *original_screen_data
    movq LOCAL_BASE_IMAGE_PTR(%rbp), %rdi
    # %rdi - BaseImage *base_image
    movq %rax, BASE_IMAGE_SCREEN_DATA_BYTES_PTR_OFFSET(%rdi)

    # Allocate and initialise the member variable - Bitmap *base_image->bitmap
    movq LOCAL_BITMAP_DATA_PTR(%rbp), %rdi
    # %rdi - Byte data[$BITMAP_DATA_LENGTH]
    call new_bitmap
    # %rax - Bitmap *bitmap
    movq LOCAL_BASE_IMAGE_PTR(%rbp), %rdi
    # %rdi - BaseImage base_image
    movq %rax, BASE_IMAGE_BITMAP_PTR_OFFSET(%rdi)

    # Allocate and initialise the member variable - ScreenArray *base_image->screens
    movq LOCAL_BASE_IMAGE_PTR(%rbp), %rdi
    # %rdi - BaseImage *base_image
    call base_image_get_screen_count
    # %rax - std::size_t screen_count
    movq %rax, %rdi
    # %rdi - std::size_t length = screen_count
    movq LOCAL_SCREEN_SIZE(%rbp), %rsi
    # %rsi - std::size_t screen_size
    movq LOCAL_SCREEN_DATA_PTR(%rbp), %rdx
    # %rdx - Byte data[screen_data_length]
    call new_screen_array
    # %rax - ScreenArray *screens
    movq LOCAL_BASE_IMAGE_PTR(%rbp), %rdi
    # %rdi - BaseImage base_image
    movq %rax, BASE_IMAGE_SCREENS_PTR_OFFSET(%rdi)

    movq LOCAL_BASE_IMAGE_PTR(%rbp), %rax
    # %rax - BaseImage *base_image

    leave
    ret

# void delete_base_image(BaseImage *base_image);
.globl delete_base_image
.type delete_base_image, @function

# BaseImage *base_image
.equ LOCAL_BASE_IMAGE_PTR, -8

# %rdi - BaseImage *base_image
delete_base_image:

    # Reserve space for 1 variable (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - BaseImage *base_image
    movq %rdi, LOCAL_BASE_IMAGE_PTR(%rbp)
    # Do not deallocate a null pointer:
    cmpq $0, %rdi
    jz __delete_base_image_1

    # Deallocate the member variable - ByteArray *original_bitmap_data
    movq LOCAL_BASE_IMAGE_PTR(%rbp), %rax
    # %rax - BaseImage *base_image
    movq BASE_IMAGE_BITMAP_DATA_BYTES_PTR_OFFSET(%rax), %rdi
    # %rdi - ByteArray *base_image->original_bitmap_data
    call delete_byte_array

    # Deallocate the member variable - ByteArray *original_screen_data
    movq LOCAL_BASE_IMAGE_PTR(%rbp), %rax
    # %rax - BaseImage *base_image
    movq BASE_IMAGE_SCREEN_DATA_BYTES_PTR_OFFSET(%rax), %rdi
    # %rdi - ByteArray *base_image->original_screen_data
    call delete_byte_array

    # Deallocate the member variable - Bitmap *bitmap
    movq LOCAL_BASE_IMAGE_PTR(%rbp), %rax
    # %rax - BaseImage *base_image
    movq BASE_IMAGE_BITMAP_PTR_OFFSET(%rax), %rdi
    # %rdi - Bitmap *base_image->bitmap
    call delete_bitmap

    # Deallocate the member variable - ScreenArray *screens
    movq LOCAL_BASE_IMAGE_PTR(%rbp), %rax
    # %rax - BaseImage *base_image
    movq BASE_IMAGE_SCREENS_PTR_OFFSET(%rax), %rdi
    # %rdi - ScreenArray *base_image->screens
    call delete_array

    # Deallocate the BaseImage object:
    movq LOCAL_BASE_IMAGE_PTR(%rbp), %rdi
    # %rdi - BaseImage *base_image
    movq $BASE_IMAGE_TOTAL_SIZE, %rsi
    # %rsi - uint64_t length
    call free_with_zero_fill

__delete_base_image_1:

    leave
    ret

# std::size_t base_image_get_screen_data_length(BaseImage *base_image);
.type base_image_get_screen_data_length, @function

# %rdi - BaseImage *base_image
base_image_get_screen_data_length:

    # %rdi - BaseImage *base_image
    movq BASE_IMAGE_SCREEN_DATA_LENGTH_OFFSET(%rdi), %rax
    # %rax - std::size_t screen_data_length

    ret

# std::size_t base_image_get_screen_count(BaseImage *base_image);
.type base_image_get_screen_count, @function

# %rdi - BaseImage *base_image
base_image_get_screen_count:

    # %rdi - BaseImage *base_image
    movq BASE_IMAGE_SCREEN_COUNT_OFFSET(%rdi), %rax
    # %rax - std::size_t screen_count

    ret

# Bitmap *base_image_get_bitmap(BaseImage *base_image);
.globl base_image_get_bitmap
.type base_image_get_bitmap, @function

# %rdi - BaseImage *base_image
base_image_get_bitmap:

    # %rdi - BaseImage *base_image
    movq BASE_IMAGE_BITMAP_PTR_OFFSET(%rdi), %rax
    # %rax - Bitmap *bitmap

    ret

# Screen *base_image_get_screen(BaseImage *base_image, std::size_t screen_index);
.globl base_image_get_screen
.type base_image_get_screen, @function

# %rdi - BaseImage *base_image
# %rsi - std::size_t screen_index
base_image_get_screen:

    # %rdi - BaseImage *base_image
    movq BASE_IMAGE_SCREENS_PTR_OFFSET(%rdi), %rax
    # %rax - ScreenArray *screens
    movq %rax, %rdi
    # %rdi - ScreenArray *screens
    # %rsi - std::size_t offset = screen_index
    call array_get_item_at
    # %rax - Screen *screen

    ret

# Byte *export_base(
#   BaseImage *base_image,
#   uint64_t data_length,
#   uint16_t load_address,
#   uint64_t bitmap_offset,
#   uint64_t screen_offsets[screen_count],
#   uint64_t screen_count,
# );
.globl export_base
.type export_base, @function

# BaseImage *base_image
.equ LOCAL_BASE_IMAGE_PTR, -8
# uint64_t data_length
.equ LOCAL_DATA_LENGTH, -16
# uint64_t bitmap_offset
.equ LOCAL_BITMAP_OFFSET, -24
# uint64_t screen_offset
.equ LOCAL_SCREEN_OFFSET, -32
# Byte *data
.equ LOCAL_DATA_PTR, -40
# uint16_t load_address
.equ LOCAL_LOAD_ADDRESS, -48
# uint64_t screen_offsets[screen_count]
.equ LOCAL_SCREEN_OFFSETS_PTR, -56
# uint64_t screen_count
.equ LOCAL_SCREEN_COUNT, -64
# uint64_t i
.equ LOCAL_I, -72

# %rdi - BaseImage *base_image
# %rsi - uint64_t data_length
# %rdx - uint16_t load_address
# %rcx - uint64_t bitmap_offset
# %r8 - uint64_t screen_offsets[screen_count]
# %r9 - uint64_t screen_count
export_base:

    # Reserve space for 9 variables (aligned to 16 bytes):
    enter $0x50, $0
    # %rdi - BaseImage *base_image
    movq %rdi, LOCAL_BASE_IMAGE_PTR(%rbp)
    # %rsi - uint64_t data_length
    movq %rsi, LOCAL_DATA_LENGTH(%rbp)
    # %dx - uint16_t load_address
    movw %dx, LOCAL_LOAD_ADDRESS(%rbp)
    # %rcx - uint64_t bitmap_offset
    movq %rcx, LOCAL_BITMAP_OFFSET(%rbp)
    # %r8 - uint64_t screen_offsets[screen_count]
    movq %r8, LOCAL_SCREEN_OFFSETS_PTR(%rbp)
    # %r9 - uint64_t screen_count
    movq %r9, LOCAL_SCREEN_COUNT(%rbp)

    # Allocate memory to store the exported BaseImage data:
    movq LOCAL_DATA_LENGTH(%rbp), %rdi
    # uint64_t data_length
    call malloc@plt
    # %rax - Byte *data
    movq %rax, LOCAL_DATA_PTR(%rbp)

    # Fill allocated memory with null bytes:
    movq LOCAL_DATA_PTR(%rbp), %rdi
    movq LOCAL_DATA_LENGTH(%rbp), %rcx
    movq $0, %rax
    rep stosb

    # Store load address into the exported BaseImage data:
    movq LOCAL_DATA_PTR(%rbp), %rdi
    # %rdi - Byte *data
    movw LOCAL_LOAD_ADDRESS(%rbp), %si
    # %si - uint16_t load_address
    movw %si, (%rdi)
    # data[load_address_offset] = load_address

    # Store bitmap data into the exported BaseImage data:
    movq LOCAL_BASE_IMAGE_PTR(%rbp), %rdi
    # %rdi - BaseImage *base_image
    call base_image_get_bitmap
    # %rax - Bitmap *bitmap
    movq %rax, %rdi
    # %rdi - Bitmap *bitmap
    movq LOCAL_DATA_PTR(%rbp), %rsi
    # %rsi - Byte *data
    addq LOCAL_BITMAP_OFFSET(%rbp), %rsi
    # %rsi - Byte *target_data = data + bitmap_offset
    call bmp_copy_data

    movq $0, LOCAL_I(%rbp)
    # uint64_t i = 0

__export_base_1:

    # Get screen offset at index i in target data bytes:
    movq LOCAL_SCREEN_OFFSETS_PTR(%rbp), %rdi
    # %rdi - uint64_t screen_offsets[screen_count]
    movq LOCAL_I(%rbp), %rsi
    # %rsi - std::size_t screen_index = i
    movq (%rdi, %rsi, SIZE_OF_UINT64_T), %rax
    # %rax - uint64_t screen_offset = screen_offsets[screen_index]
    movq %rax, LOCAL_SCREEN_OFFSET(%rbp)

    # Store screen data into the exported BaseImage data:
    movq LOCAL_BASE_IMAGE_PTR(%rbp), %rdi
    # %rdi - BaseImage *base_image
    movq LOCAL_I(%rbp), %rsi
    # %rsi - std::size_t screen_index = i
    call base_image_get_screen
    # %rax - Screen *screen
    movq %rax, %rdi
    # %rdi - Screen *screen
    movq LOCAL_DATA_PTR(%rbp), %rsi
    # %rsi - Byte *data
    addq LOCAL_SCREEN_OFFSET(%rbp), %rsi
    # %rsi - Byte *target_data = data + screen_offset
    call scr_copy_data

    # while (++i < screen_count)
    incq LOCAL_I(%rbp)
    movq LOCAL_I(%rbp), %rax
    cmpq LOCAL_SCREEN_COUNT(%rbp), %rax
    jb __export_base_1

    movq LOCAL_DATA_PTR(%rbp), %rax
    # %rax - Byte *data

    leave
    ret
