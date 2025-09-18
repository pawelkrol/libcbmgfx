// Copyright © 2025 Pawel Krol

#pragma once

#include "png.h"

#include <cstddef>
#include <cstdint>
#include <memory>

constexpr png_uint_32 cbm_bitmap_width  = 0x0140;
constexpr png_uint_32 cbm_bitmap_height = 0x00c8;

enum colour_palette {
  colour_palette_default  = 0,
  colour_palette_pepto    = 1,
  colour_palette_colodore = 2,
  colour_palette_vice     = 3,
};

struct ColourPalette {
  uint32_t colours[16];
};

struct Colour {
  uint32_t rgb_value;
  uint32_t original_rgb_value;
  std::byte cbm_value;
};

struct HiresConfig {
  char format_description[4];
  uint16_t load_address;
  uint16_t data_length;
  uint16_t bitmap_offset;
  uint16_t screen_offset;
};

struct MulticolourConfig : HiresConfig {
  uint16_t colours_offset;
  uint16_t background_colour_offset;
  uint16_t border_colour_offset;
};

struct FLIConfig : HiresConfig {
  uint16_t colours_offset;
  uint16_t border_colour_offset;
  uint16_t screen_size;
  std::byte **(*get_d021_colours_fun)(std::byte *);
};

struct IFLIConfig {
  char format_description[4];
  uint16_t load_address;
  uint16_t data_length;
  uint16_t bitmap_1_offset;
  uint16_t screens_1_offset;
  uint16_t bitmap_2_offset;
  uint16_t screens_2_offset;
  uint16_t colours_offset;
  std::byte **(*get_d021_colours_fun)(std::byte *);
  uint16_t border_colour_offset;
  uint16_t screen_size;
};

extern "C" HiresConfig *art_config();

extern "C" MulticolourConfig *aas_config();
extern "C" MulticolourConfig *fcp_config();
extern "C" MulticolourConfig *kla_config();

extern "C" FLIConfig *fd2_config();

extern "C" IFLIConfig *fun_config();
extern "C" IFLIConfig *gun_config();

struct Array {
  std::size_t length;
  void(*delete_item)(void *);
  void **items;
};

struct ByteArray {
  std::byte *data;
  std::size_t length;
};

struct ScreenArray : Array {};

struct Bitmap {
  std::byte *data;
};

struct Screen {
  std::byte *data;
};

struct BaseImage {
  std::size_t screen_data_length;
  std::size_t screen_count;
  ByteArray *bitmap_data_bytes;
  ByteArray *screen_data_bytes;
  Bitmap *bitmap;
  ScreenArray *screens;
};

struct Hires {
  BaseImage *base_image;
};

struct Multicolour : Hires {
  ByteArray *colours_data_bytes;
  Screen *colours;
  std::byte background_colour;
  std::byte border_colour;
};

struct FLI {
  Multicolour *multicolour;
  ByteArray *d021_colours;
};

struct IFLI {
  FLI *fli_1;
  FLI *fli_2;
};

struct PixelMap {
  Colour **colour_data;
  uint16_t width;
  uint16_t height;
  std::byte colour_palette;
};

extern "C" Hires *load_art(
    std::byte *data,  // std::byte data[data_size]
    std::size_t data_size);

extern "C" Multicolour *load_aas(
    std::byte *data,  // std::byte data[data_size]
    std::size_t data_size);

extern "C" Multicolour *load_fcp(
    std::byte *data,  // std::byte data[data_size]
    std::size_t data_size);

extern "C" Multicolour *load_kla(
    std::byte *data,  // std::byte data[data_size]
    std::size_t data_size);

extern "C" FLI *load_fd2(
    std::byte *data,  // std::byte data[data_size]
    std::size_t data_size);

extern "C" IFLI *load_fun(
    std::byte *data,  // std::byte data[data_size]
    std::size_t data_size);

extern "C" IFLI *load_gun(
    std::byte *data,  // std::byte data[data_size]
    std::size_t data_size);

extern "C" void delete_hpi(
    Hires *hpi);

extern "C" void delete_mcp(
    Multicolour *mcp);

extern "C" void delete_fli(
    FLI *fli);

extern "C" void delete_ifli(
    IFLI *ifli);

extern "C" std::byte *export_art(
    Hires *hpi);

extern "C" std::byte *export_aas(
    Multicolour *mcp);

extern "C" std::byte *export_fcp(
    Multicolour *mcp);

extern "C" std::byte *export_kla(
    Multicolour *mcp);

extern "C" void delete_art(
    std::byte *art_data);

extern "C" void delete_aas(
    std::byte *aas_data);

extern "C" void delete_fcp(
    std::byte *fcp_data);

extern "C" void delete_kla(
    std::byte *kla_data);

extern "C" PixelMap *hpi_get_pixels(
    Hires *hpi,
    enum colour_palette palette = colour_palette_default);

extern "C" PixelMap *mcp_get_pixels(
    Multicolour *mcp,
    enum colour_palette palette = colour_palette_default);

extern "C" PixelMap *fli_get_pixels(
    FLI *fli,
    enum colour_palette palette = colour_palette_default);

extern "C" PixelMap *ifli_get_pixels(
    IFLI *ifli,
    enum colour_palette palette = colour_palette_default);

extern "C" PixelMap *import_png(
    png_bytep *row_pointers,
    enum colour_palette palette,
    png_uint_32 width,
    png_uint_32 height,
    uint8_t background_colour = -1);  // defaults to the black background colour

extern "C" uint32_t pix_get_rgb_colour_at(
    PixelMap *pix,
    uint16_t x,
    uint16_t y);

extern "C" void delete_pixel_map(
    PixelMap *pix);

extern "C" Hires *pix2hpi(
    PixelMap *pix,
    bool interpolate = false);

extern "C" Multicolour *pix2mcp(
    PixelMap *pix,
    uint8_t background_colour = -1,  // identify the most common colour as the image background by default
    bool interpolate = false);

struct PixelMapDeleter {
  void operator()(PixelMap *pix);
};

using PixelMapPtr = std::unique_ptr<PixelMap, PixelMapDeleter>;

void hpi2png(
    Hires *hpi,
    const char *png,
    enum colour_palette palette = colour_palette_default);

void mcp2png(
    Multicolour *mcp,
    const char *png,
    enum colour_palette palette = colour_palette_default);

void fli2png(
    FLI *fli,
    const char *png,
    enum colour_palette palette = colour_palette_default);

void ifli2png(
    IFLI *ifli,
    const char *png,
    enum colour_palette palette = colour_palette_default);

Hires *png2hpi(
    const char *png,
    bool interpolate = false,
    enum colour_palette palette = colour_palette_default);

Multicolour *png2mcp(
    const char *png,
    uint8_t background_colour = -1,  // identify the most common colour as the image background by default
    bool interpolate = false,
    enum colour_palette palette = colour_palette_default);
