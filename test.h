#pragma once

#include <cstddef>
#include <cstdint>

constexpr std::size_t bitmap_data_length = 0x1f40;
constexpr std::size_t screen_data_length = 0x03e8;

extern "C" Array *new_array(
    std::size_t length,
    void *(*copy_item)(void *),  // (T *)(*copy_item)(T *)
    void(*delete_item)(void *),  // (void)(*delete_item)(T *)
    void **data);                // T *data[length]

extern "C" void delete_array(
    Array *array);  // Array<T> *array

extern "C" std::size_t array_get_length(
    Array *array);  // Array<T> *array

extern "C" void *array_get_item_at(
    Array *array,  // Array<T> *array,
    std::size_t offset);

extern "C" ByteArray *new_byte_array(
    uint64_t length,
    const uint8_t *data);

extern "C" void delete_byte_array(
    ByteArray *array);

extern "C" uint8_t *byte_array_get_data(
    ByteArray *array);

extern "C" uint64_t byte_array_get_length(
    ByteArray *array);

extern "C" uint8_t byte_array_get_value_at(
    ByteArray *array,
    uint64_t offset);

extern "C" ScreenArray *new_screen_array(
    std::size_t length,
    std::size_t screen_size,
    std::byte *data);

extern "C" Bitmap *new_bitmap(
    const uint8_t data[bitmap_data_length]);

extern "C" void delete_bitmap(
    Bitmap *bitmap);

extern "C" uint8_t *bmp_get_data(
    Bitmap *bitmap);

extern "C" uint8_t bmp_get_value_at_offset(
    Bitmap *bitmap,
    uint64_t offset);

extern "C" Screen *new_screen(
    const uint8_t data[screen_data_length]);

extern "C" void delete_screen(
    Screen *screen);

extern "C" uint8_t *scr_get_data(
    Screen *screen);

extern "C" uint8_t scr_get_value_at(
    Screen *screen,
    uint64_t offset);

extern "C" Bitmap *hpi_get_bitmap(
    Hires *hires);

extern "C" Screen *hpi_get_screen(
    Hires *hires);

extern "C" uint8_t hpi_get_cbm_value_at_xy(
    Hires *hires,
    uint16_t x,
    uint16_t y);

extern "C" Bitmap *mcp_get_bitmap(
    Multicolour *multicolour);

extern "C" Screen *mcp_get_screen(
    Multicolour *multicolour);

extern "C" Screen *mcp_get_colours(
    Multicolour *multicolour);

extern "C" uint8_t mcp_get_background_colour(
    Multicolour *multicolour);

extern "C" uint8_t mcp_get_border_colour(
    Multicolour *multicolour);

extern "C" uint8_t mcp_get_cbm_value_at_xy(
    Multicolour *multicolour,
    uint16_t x,
    uint16_t y,
    Screen *(*get_screen)(Multicolour *, uint16_t));

extern "C" Bitmap *fli_get_bitmap(
    FLI *fli);

extern "C" Screen *fli_get_screen(
    FLI *fli,
    std::size_t screen_index);

extern "C" Screen *fli_get_colours(
    FLI *fli);

extern "C" uint8_t fli_get_background_colour(
    FLI *fli);

extern "C" uint8_t fli_get_border_colour(
    FLI *fli);

extern "C" uint8_t fli_get_cbm_value_at_xy(
    FLI *fli,
    uint16_t x,
    uint16_t y,
    Screen *(*get_screen)(FLI *, uint16_t));

extern "C" ColourPalette *get_colour_palette(
    enum colour_palette palette);

extern "C" Colour *new_colour(
    uint8_t cbm_value,
    png_bytep original_rgb_value,
    const ColourPalette *colour_palette);

extern "C" void delete_colour(
    Colour *colour);

extern "C" uint8_t col_get_cbm_value(
    Colour *colour);

extern "C" uint32_t col_get_rgb_value(
    Colour *colour);

extern "C" uint8_t get_nearest_cbm_value(
    const ColourPalette *colour_palette,
    uint32_t rgba_value);

extern "C" uint8_t pix_get_cbm_colour_at(
    PixelMap *pixel_map,
    uint16_t x,
    uint16_t y);

extern "C" uint32_t pix_get_original_rgb_colour_at(
    PixelMap *pixel_map,
    uint16_t x,
    uint16_t y);

extern "C" void collect_mcp_block_colour_data(
    PixelMap *pixel_map,
    uint16_t offset_x,
    uint16_t offset_y,
    uint8_t *target_bitmap_data,
    uint8_t *target_screen_data,
    uint8_t *target_colours_data,
    uint8_t background_colour,
    bool interpolate);

extern "C" uint8_t identify_most_common_colour(
    PixelMap *pixel_map);

extern "C" void collect_most_frequent_colours(
    PixelMap *pixel_map,
    uint16_t offset_x,
    uint16_t offset_y,
    uint16_t length_x,
    uint16_t length_y,
    uint8_t *most_frequent_colours,  // Byte most_frequent_colours[max_count]
    uint8_t max_count,
    uint8_t background_colour,
    uint16_t increment_x);

extern "C" void sort_colour_count_frequencies(
  uint16_t indexed_colour_counts[16],
  uint8_t sorted_colour_indexes[16],
  uint64_t low,
  uint64_t high);

extern "C" void swap_array_items(
    void *array,
    uint64_t index_1,
    uint64_t index_2,
    uint64_t item_size);
