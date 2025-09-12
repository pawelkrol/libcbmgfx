.include "const.s"

.section .text

# template<typename T>
# Array<T> *new_array(std::size_t length, T *(*copy_item)(T *), void(*delete_item)(T *), T *data[length]);
.globl new_array
.type new_array, @function

# std::size_t length
.equ LOCAL_LENGTH, -8
# T *(*copy_item)(T *)
.equ LOCAL_COPY_ITEM_FUN_PTR, -16
# void(*delete_item)(T *)
.equ LOCAL_DELETE_ITEM_FUN_PTR, -24
# T *data[length]
.equ LOCAL_DATA_PTR, -32
# std::size_t size
.equ LOCAL_SIZE, -40
# T *items[length]
.equ LOCAL_ITEMS_PTR, -48
# Array<T> *array
.equ LOCAL_ARRAY_PTR, -56
# std::size_t i
.equ LOCAL_I, -64

# %rdi - std::size_t length
# %rsi - T *(*copy_item)(T *)
# %rdx - void(*delete_item)(T *)
# %rcx - T *data[length]
new_array:

    # Reserve space for 8 variables (aligned to 16 bytes):
    enter $0x40, $0
    # %rdi - std::size_t length
    movq %rdi, LOCAL_LENGTH(%rbp)
    # %rsi - T *(*copy_item)(T *)
    movq %rsi, LOCAL_COPY_ITEM_FUN_PTR(%rbp)
    # %rdx - void(*delete_item)(T *)
    movq %rdx, LOCAL_DELETE_ITEM_FUN_PTR(%rbp)
    # %rcx - T *data[length]
    movq %rcx, LOCAL_DATA_PTR(%rbp)

    # T *items[length] = nullptr
    movq $0, LOCAL_ITEMS_PTR(%rbp)

    # Skip empty lists:
    cmpq $0, LOCAL_LENGTH(%rbp)
    jz __new_array_1

    # Compute memory size for the items:
    movq LOCAL_LENGTH(%rbp), %rax
    # %rax - std::size_t length
    movq $SIZE_OF_POINTER, %rcx
    # %rcx - SIZE_OF_POINTER
    mulq %rcx
    # %rax - length * SIZE_OF_POINTER
    movq %rax, LOCAL_SIZE(%rbp)
    # std::size_t size = length * SIZE_OF_POINTER

    # Allocate memory to store the items:
    movq LOCAL_SIZE(%rbp), %rdi
    # %rdi - std::size_t size
    call malloc@plt
    # %rax - T *items[length]
    movq %rax, LOCAL_ITEMS_PTR(%rbp)

__new_array_1:

    # Allocate memory to store the new Array<T> object:
    movq $ARRAY_TOTAL_SIZE, %rdi
    # %rdi - ARRAY_TOTAL_SIZE
    call malloc@plt
    # %rax - Array<T> *array
    movq %rax, LOCAL_ARRAY_PTR(%rbp)

    # Initialise array->length with length:
    movq LOCAL_ARRAY_PTR(%rbp), %rdi
    # %rdi - Array<T> *array
    movq LOCAL_LENGTH(%rbp), %rax
    # %rax - std::size_t length
    movq %rax, ARRAY_LENGTH_OFFSET(%rdi)

    # Initialise array->delete_item with delete_item:
    movq LOCAL_ARRAY_PTR(%rbp), %rdi
    # %rdi - Array<T> *array
    movq LOCAL_DELETE_ITEM_FUN_PTR(%rbp), %rax
    # %rax - void(*delete_item)(T *)
    movq %rax, ARRAY_DELETE_ITEM_FUN_PTR_OFFSET(%rdi)

    # Initialise array->items with items pointer:
    movq LOCAL_ARRAY_PTR(%rbp), %rdi
    # %rdi - Array<T> *array
    movq LOCAL_ITEMS_PTR(%rbp), %rax
    # %rax - T *items[length]
    movq %rax, ARRAY_ITEMS_PTR_OFFSET(%rdi)

    # Copy length of data to array->items:

    # Skip empty lists:
    cmpq $0, LOCAL_LENGTH(%rbp)
    jz __new_array_3

    movq $0, LOCAL_I(%rbp)
    # std::size_t i = 0

__new_array_2:

    # Copy data at index i to items at index i:

    movq LOCAL_DATA_PTR(%rbp), %rax
    # %rax - T *data[length]
    movq LOCAL_I(%rbp), %rcx
    # %rcx - std::size_t i
    movq (%rax, %rcx, SIZE_OF_POINTER), %rdi
    # %rdi - T *source_item = data[i]
    call *LOCAL_COPY_ITEM_FUN_PTR(%rbp)
    # %rax - T *target_item = copy_item(source_item)
    movq LOCAL_ITEMS_PTR(%rbp), %rdi
    # %rdi - T *items[length]
    movq LOCAL_I(%rbp), %rcx
    # %rcx - std::size_t i
    movq %rax, (%rdi, %rcx, SIZE_OF_POINTER)
    # items[i] = copy_item(data[i])

    # while (++i < length)
    incq LOCAL_I(%rbp)
    movq LOCAL_I(%rbp), %rax
    cmpq LOCAL_LENGTH(%rbp), %rax
    jb __new_array_2

__new_array_3:

    movq LOCAL_ARRAY_PTR(%rbp), %rax
    # %rax - Array<T> *array

    leave
    ret

# template<typename T>
# void delete_array(Array<T> *array);
.globl delete_array
.type delete_array, @function

# Array<T> *array
.equ LOCAL_ARRAY_PTR, -8
# std::size_t length
.equ LOCAL_LENGTH, -16
# void(*delete_item)(T *)
.equ LOCAL_DELETE_ITEM_FUN_PTR, -24
# T *items[length]
.equ LOCAL_ITEMS_PTR, -32
# std::size_t size
.equ LOCAL_SIZE, -40
# std::size_t i
.equ LOCAL_I, -48

# %rdi - Array<T> *array
delete_array:

    # Reserve space for 6 variables (aligned to 16 bytes):
    enter $0x30, $0
    # %rdi - Array<T> *array
    movq %rdi, LOCAL_ARRAY_PTR(%rbp)
    # Do not deallocate a null pointer:
    cmpq $0, %rdi
    jz __delete_array_3

    movq LOCAL_ARRAY_PTR(%rbp), %rdi
    # %rdi - Array<T> *array
    call array_get_length
    # %rax - std::size_t length
    movq %rax, LOCAL_LENGTH(%rbp)
    # std::size_t length = array->length

    movq LOCAL_ARRAY_PTR(%rbp), %rdi
    # %rdi - Array<T> *array
    call array_get_delete_item_fun
    # %rax - void(*delete_item)(T *)
    movq %rax, LOCAL_DELETE_ITEM_FUN_PTR(%rbp)
    # void(*delete_item)(T *) = array->delete_item

    movq LOCAL_ARRAY_PTR(%rbp), %rdi
    # %rdi - Array<T> *array
    call array_get_items
    # %rax - T *items[length]
    movq %rax, LOCAL_ITEMS_PTR(%rbp)
    # T *items[length] = array->items

    # Deallocate all data items:

    # Skip empty lists:
    cmpq $0, LOCAL_LENGTH(%rbp)
    jz __delete_array_2

    movq $0, LOCAL_I(%rbp)
    # std::size_t i = 0

__delete_array_1:

    # Delete item at index i:

    movq LOCAL_ITEMS_PTR(%rbp), %rax
    # %rax - T *items[length]
    movq LOCAL_I(%rbp), %rcx
    # %rcx - std::size_t i
    movq (%rax, %rcx, SIZE_OF_POINTER), %rdi
    # %rdi - T *item = items[i]
    call *LOCAL_DELETE_ITEM_FUN_PTR(%rbp)

    # while (++i < length)
    incq LOCAL_I(%rbp)
    movq LOCAL_I(%rbp), %rax
    cmpq LOCAL_LENGTH(%rbp), %rax
    jb __delete_array_1

__delete_array_2:

    # Compute memory size for the items:
    movq LOCAL_LENGTH(%rbp), %rax
    # %rax - std::size_t length
    movq $SIZE_OF_POINTER, %rcx
    # %rcx - SIZE_OF_POINTER
    mulq %rcx
    # %rax - length * SIZE_OF_POINTER
    movq %rax, LOCAL_SIZE(%rbp)
    # std::size_t size = length * SIZE_OF_POINTER

    # Deallocate an array holding all data items:
    movq LOCAL_ITEMS_PTR(%rbp), %rdi
    # %rdi - T *items[length]
    movq LOCAL_SIZE(%rbp), %rsi
    # %rsi - std::size_t size
    call free_with_zero_fill

    # Deallocate the Array<T> object:
    movq LOCAL_ARRAY_PTR(%rbp), %rdi
    # %rdi - Array<T> *array
    movq $ARRAY_TOTAL_SIZE, %rsi
    # %rsi - std::size_t length
    call free_with_zero_fill

__delete_array_3:

    leave
    ret

# template<typename T>
# std::size_t array_get_length(Array<T> *array);
.globl array_get_length
.type array_get_length, @function

# %rdi - Array<T> *array
array_get_length:

    # %rdi - Array<T> *array
    movq ARRAY_LENGTH_OFFSET(%rdi), %rax
    # %rax - std::size_t length

    ret

# template<typename T>
# (void)(*)(T *) array_get_delete_item_fun(Array<T> *array);
.type array_get_delete_item_fun, @function

# %rdi - Array<T> *array
array_get_delete_item_fun:

    # %rdi - Array<T> *array
    movq ARRAY_DELETE_ITEM_FUN_PTR_OFFSET(%rdi), %rax
    # %rax - void(*delete_item)(T *)

    ret

# template<typename T>
# T **array_get_items(Array<T> *array);
.type array_get_items, @function

# %rdi - Array<T> *array
array_get_items:

    # %rdi - Array<T> *array
    movq ARRAY_ITEMS_PTR_OFFSET(%rdi), %rax
    # %rax - T *items[length]

    ret

# template<typename T>
# T *array_get_item_at(Array<T> *array, std::size_t offset);
.globl array_get_item_at
.type array_get_item_at, @function

# Array<T> *array
.equ LOCAL_ARRAY_PTR, -8
# std::size_t offset
.equ LOCAL_OFFSET, -16

# %rdi - Array<T> *array
# %rsi - std::size_t offset
array_get_item_at:

    # Reserve space for 2 variables (aligned to 16 bytes):
    enter $0x10, $0
    # %rdi - Array<T> *array
    movq %rdi, LOCAL_ARRAY_PTR(%rbp)
    # %rsi - std::size_t offset
    movq %rsi, LOCAL_OFFSET(%rbp)

    # %rdi - Array<T> *array
    call array_get_items
    # %rax - T *items[length]
    movq %rax, %rdi
    # %rdi - T *items[length]
    movq LOCAL_OFFSET(%rbp), %rsi
    # %rsi - std::size_t offset
    movq (%rdi, %rsi, SIZE_OF_POINTER), %rax
    # %rax - T *item = items[offset]

    leave
    ret
