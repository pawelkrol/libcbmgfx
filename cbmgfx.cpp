#include "cbmgfx.h"

#include "png.h"

#include <cstdlib>
#include <fstream>
#include <memory>
#include <sstream>
#include <stdexcept>
#include <string>

namespace {

void assert_file_does_not_exist(
    const char *path) {
  std::fstream fs(path, std::fstream::in);
  if (fs.good()) {
    fs.close();
    std::ostringstream error_message;
    error_message << "file already exists: '" << path << "'";
    throw std::invalid_argument(error_message.str());
  }
  fs.close();
}

void assert_file_exists(
    const char *path) {
  std::fstream fs(path, std::fstream::in);
  if (!fs.good()) {
    fs.close();
    std::ostringstream error_message;
    error_message << "file does not exist: '" << path << "'";
    throw std::invalid_argument(error_message.str());
  }
  fs.close();
}

void pix2png(
    PixelMap *pix,
    const char *png,
    enum colour_palette palette) {
  assert_file_does_not_exist(png);

  FILE *fp = fopen(png, "wb");
  png_structp png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, nullptr, nullptr, nullptr);
  png_infop info_ptr = png_create_info_struct(png_ptr);
  setjmp(png_jmpbuf(png_ptr));
  png_init_io(png_ptr, fp);
  png_set_IHDR(png_ptr, info_ptr, cbm_bitmap_width, cbm_bitmap_height, 8, PNG_COLOR_TYPE_RGB, PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);

  std::string software_key{"Software"};
  std::string software_text{"libcbmgfx-1.1.0"};

  png_text text[1];
  int num_text = 0;
  text[num_text].compression = PNG_TEXT_COMPRESSION_NONE;
  text[num_text].key = software_key.data();
  text[num_text].text = software_text.data();
  ++num_text;
  png_set_text(png_ptr, info_ptr, text, num_text);
  png_write_info(png_ptr, info_ptr);
  png_set_filler(png_ptr, 0, PNG_FILLER_AFTER);

  png_byte *row_pointer = static_cast<png_byte *>(malloc(sizeof(png_byte) * cbm_bitmap_width * 4));

  for (uint16_t y = 0; y < cbm_bitmap_height; ++y) {
    for(uint16_t x = 0; x < cbm_bitmap_width; ++x) {
      uint32_t rgb_colour = pix_get_rgb_colour_at(pix, x, y);
      row_pointer[x * 4 + 0] = static_cast<png_byte>((rgb_colour & 0xff0000) >> 16);  // red
      row_pointer[x * 4 + 1] = static_cast<png_byte>((rgb_colour & 0x00ff00) >> 8);  // green
      row_pointer[x * 4 + 2] = static_cast<png_byte>(rgb_colour & 0x0000ff);  // blue
    }
    png_write_row(png_ptr, row_pointer);
  }

  free(row_pointer);

  png_write_end(png_ptr, info_ptr);
  fclose(fp);
  png_destroy_write_struct(&png_ptr, &info_ptr);
}

PixelMap *png2pix(
    const char *png,
    enum colour_palette palette,
    uint8_t background_colour) {
  assert_file_exists(png);

  FILE *fp = fopen(png, "rb");
  png_structp png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  png_infop info_ptr = png_create_info_struct(png_ptr);
  setjmp(png_jmpbuf(png_ptr));
  png_init_io(png_ptr, fp);
  png_read_info(png_ptr, info_ptr);

  png_uint_32 width = png_get_image_width(png_ptr, info_ptr);
  png_uint_32 height = png_get_image_height(png_ptr, info_ptr);
  png_byte color_type = png_get_color_type(png_ptr, info_ptr);
  png_byte bit_depth = png_get_bit_depth(png_ptr, info_ptr);

  if (bit_depth == 16) {
    png_set_strip_16(png_ptr);
  }
  if (color_type == PNG_COLOR_TYPE_PALETTE) {
    png_set_palette_to_rgb(png_ptr);
  }
  if (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8) {
    png_set_expand_gray_1_2_4_to_8(png_ptr);
  }
  if (png_get_valid(png_ptr, info_ptr, PNG_INFO_tRNS)) {
    png_set_tRNS_to_alpha(png_ptr);
  }
  if (color_type == PNG_COLOR_TYPE_RGB || color_type == PNG_COLOR_TYPE_GRAY || color_type == PNG_COLOR_TYPE_PALETTE) {
    png_set_filler(png_ptr, 0xff, PNG_FILLER_AFTER);
  }
  if (color_type == PNG_COLOR_TYPE_GRAY || color_type == PNG_COLOR_TYPE_GRAY_ALPHA) {
    png_set_gray_to_rgb(png_ptr);
  }
  png_read_update_info(png_ptr, info_ptr);

  png_bytep *row_pointers = (png_bytep *)malloc(sizeof(png_bytep) * height);
  for (uint16_t y = 0; y < height; ++y) {
    row_pointers[y] = (png_byte *)malloc(png_get_rowbytes(png_ptr, info_ptr));
  }
  png_read_image(png_ptr, row_pointers);

  fclose(fp);
  png_destroy_read_struct(&png_ptr, &info_ptr, NULL);

  PixelMap *pix = import_png(row_pointers, palette, width, height, background_colour);

  for (uint16_t y = 0; y < height; y++) {
    free(row_pointers[y]);
  }
  free(row_pointers);

  return pix;
}

}  // anonymous namespace

void PixelMapDeleter::operator()(PixelMap *pix) {
  delete_pixel_map(pix);
}

void hpi2png(
    Hires *hpi,
    const char *png,
    enum colour_palette palette) {
  PixelMapPtr pix = PixelMapPtr(hpi_get_pixels(hpi, palette));

  pix2png(pix.get(), png, palette);
}

void mcp2png(
    Multicolour *mcp,
    const char *png,
    enum colour_palette palette) {
  PixelMapPtr pix = PixelMapPtr(mcp_get_pixels(mcp, palette));

  pix2png(pix.get(), png, palette);
}

void fli2png(
    FLI *fli,
    const char *png,
    enum colour_palette palette) {
  PixelMapPtr pix = PixelMapPtr(fli_get_pixels(fli, palette));

  pix2png(pix.get(), png, palette);
}

void ifli2png(
    IFLI *ifli,
    const char *png,
    enum colour_palette palette) {
  PixelMapPtr pix = PixelMapPtr(ifli_get_pixels(ifli, palette));

  pix2png(pix.get(), png, palette);
}

Hires *png2hpi(
    const char *png,
    bool interpolate,
    enum colour_palette palette) {
  PixelMapPtr pix = PixelMapPtr(png2pix(png, palette, -1));

  Hires *hpi = pix2hpi(pix.get(), interpolate);

  return hpi;
}

Multicolour *png2mcp(
    const char *png,
    uint8_t background_colour,
    bool interpolate,
    enum colour_palette palette) {
  PixelMapPtr pix = PixelMapPtr(png2pix(png, palette, background_colour));

  Multicolour *mcp = pix2mcp(pix.get(), background_colour, interpolate);

  return mcp;
}
