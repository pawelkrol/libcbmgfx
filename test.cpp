#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN

#include "cbmgfx.h"
#include "test.h"

#include "doctest/doctest.h"

#include <array>
#include <boost/filesystem.hpp>
#include <cstddef>
#include <cstdint>
#include <fstream>
#include <ios>
#include <memory>
#include <string>
#include <tuple>
#include <utility>

namespace fs = boost::filesystem;

namespace {

const fs::path fixtures = fs::path("fixtures");

const fs::path image_art = fixtures / "desolate.art";
const fs::path image_aas = fixtures / "frighthof83.aas";
const fs::path image_fcp = fixtures / "frighthof83.fcp";
const fs::path image_kla = fixtures / "frighthof83.kla";

const HiresConfig *test_art_config = art_config();
const MulticolourConfig *test_aas_config = aas_config();
const MulticolourConfig *test_fcp_config = fcp_config();
const MulticolourConfig *test_kla_config = kla_config();

const std::array<uint8_t, 32> desolate_head_bitmap_data{
  0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x41,
  0x50, 0x21, 0x00, 0x00, 0x00, 0x00, 0x88, 0x00,
  0x02, 0x05, 0x42, 0xa5, 0x4a, 0x17, 0x2f, 0x17,
  0xff, 0xfa, 0xf5, 0xe8, 0xc0, 0x80, 0x40, 0x80,
};

const std::array<uint8_t, 32> desolate_head_screen_data{
  0x89, 0x89, 0x89, 0x8c, 0x8c, 0xc8, 0x8c, 0x8c,
  0x7c, 0x7c, 0xac, 0xca, 0xca, 0xfa, 0xfa, 0x0a,
  0xfa, 0xaf, 0xfa, 0xfa, 0xfa, 0xfa, 0xca, 0xca,
  0xca, 0xca, 0x0a, 0x0a, 0xca, 0xca, 0xac, 0xc7,
};

const std::array<uint8_t, 32> frighthof83_head_bitmap_data{
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x11, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
  0x36, 0x3a, 0xc2, 0xf1, 0xcd, 0x3e, 0x0f, 0x03,
  0xd5, 0x75, 0xdd, 0xf5, 0x75, 0x57, 0x5f, 0xd7,
};

const std::array<uint8_t, 32> frighthof83_head_screen_data{
  0xb6, 0x60, 0xa4, 0x4e, 0x4a, 0x4a, 0x4a, 0x4a,
  0x4a, 0x7a, 0xa7, 0x70, 0x17, 0x10, 0x10, 0xd0,
  0xd0, 0xd0, 0xd0, 0xd0, 0xd7, 0xbd, 0xbd, 0x37,
  0x37, 0x3e, 0x3e, 0x3e, 0x6e, 0x6e, 0x6e, 0x6e,
};

const std::array<uint8_t, 32> frighthof83_head_colours_data{
  0x00, 0x00, 0x06, 0x0a, 0x00, 0x00, 0x0f, 0x0f,
  0x07, 0x0b, 0x01, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x01, 0x01, 0x01, 0x00, 0x0b, 0x07, 0x07, 0x00,
  0x0d, 0x0f, 0x00, 0x0f, 0x03, 0x0d, 0x00, 0x0d,
};

uint8_t frighthof83_background_colour = 0x00;
uint8_t frighthof83_border_colour = 0x00;

std::tuple<std::unique_ptr<std::byte>, std::size_t> read_file(fs::path file) {
  std::string path = fs::canonical(file).string();
  std::ifstream ifs(path, std::ios::in | std::ios::binary);
  const std::size_t& size = fs::file_size(path);
  std::byte *data = new std::byte[size];
  ifs.read(reinterpret_cast<char *>(data), size);
  ifs.close();
  return std::make_tuple(std::unique_ptr<std::byte>(std::move(data)), size);
}

struct TestVector {
  uint64_t x;
  uint64_t y;
  uint64_t z;
};

void *new_test_vector(uint64_t x, uint64_t y, uint64_t z) {
  TestVector *object = new TestVector();
  object->x = x;
  object->y = y;
  object->z = z;
  return static_cast<void *>(object);
}

void delete_test_vector(void *object) {
  delete(static_cast<TestVector *>(object));
}

void *copy_test_vector(void *object) {
  TestVector *orig = static_cast<TestVector *>(object);
  TestVector *copy = new TestVector();
  copy->x = orig->x;
  copy->y = orig->y;
  copy->z = orig->z;
  return static_cast<void *>(copy);
}

void *move_test_vector(void *object) {
  return object;
}

Screen *mcp_get_screen_at_y(Multicolour *multicolour, uint16_t) {
  return mcp_get_screen(multicolour);
}

}  // anonymous namesapce

TEST_CASE("array (copied)") {
  void *test_vector_1 = new_test_vector(1, 2, 3);
  void *test_vector_2 = new_test_vector(4, 5, 6);
  void *test_vectors[2] = { test_vector_1, test_vector_2 };

  Array *test_array = new_array(2, copy_test_vector, delete_test_vector, test_vectors);

  CHECK_EQ(array_get_length(test_array), 2);

  TestVector *array_item_1 = static_cast<TestVector *>(array_get_item_at(test_array, 0));

  CHECK_EQ(array_item_1->x, 1);
  CHECK_EQ(array_item_1->y, 2);
  CHECK_EQ(array_item_1->z, 3);

  TestVector *array_item_2 = static_cast<TestVector *>(array_get_item_at(test_array, 1));

  CHECK_EQ(array_item_2->x, 4);
  CHECK_EQ(array_item_2->y, 5);
  CHECK_EQ(array_item_2->z, 6);

  delete_array(test_array);

  delete_test_vector(test_vector_1);
  delete_test_vector(test_vector_2);
}

TEST_CASE("array (moved)") {
  void *test_vector_1 = new_test_vector(1, 2, 3);
  void *test_vector_2 = new_test_vector(4, 5, 6);
  void *test_vectors[2] = { test_vector_1, test_vector_2 };

  Array *test_array = new_array(2, move_test_vector, delete_test_vector, test_vectors);

  CHECK_EQ(array_get_length(test_array), 2);

  TestVector *array_item_1 = static_cast<TestVector *>(array_get_item_at(test_array, 0));

  CHECK_EQ(array_item_1->x, 1);
  CHECK_EQ(array_item_1->y, 2);
  CHECK_EQ(array_item_1->z, 3);

  TestVector *array_item_2 = static_cast<TestVector *>(array_get_item_at(test_array, 1));

  CHECK_EQ(array_item_2->x, 4);
  CHECK_EQ(array_item_2->y, 5);
  CHECK_EQ(array_item_2->z, 6);

  delete_array(test_array);
}

TEST_CASE("byte array") {
  const std::array<uint8_t, 16> bytes{
    0x46, 0x55, 0x4e, 0x50, 0x41, 0x49, 0x4e, 0x54,
    0x20, 0x28, 0x4d, 0x54, 0x29, 0x20, 0x00, 0x00,
  };
  ByteArray *test_array = new_byte_array(16, bytes.data());

  uint64_t length = byte_array_get_length(test_array);
  CHECK(length == 16);

  uint8_t *data = static_cast<uint8_t *>(byte_array_get_data(test_array));
  for (int8_t i = 0; i < 16; ++i) {
    CHECK(*(data + i) == bytes.at(i));
  }

  for (int8_t i = 0; i < 16; ++i) {
    CHECK(byte_array_get_value_at(test_array, i) == bytes.at(i));
  }

  delete_byte_array(test_array);
}

TEST_CASE("screen array") {
  std::byte data[0x0800] = {};
  data[0x0000] = static_cast<std::byte>(0x01);
  data[0x0001] = static_cast<std::byte>(0x02);
  data[0x0002] = static_cast<std::byte>(0x03);
  data[0x0400] = static_cast<std::byte>(0x04);
  data[0x0401] = static_cast<std::byte>(0x05);
  data[0x0402] = static_cast<std::byte>(0x06);

  ScreenArray *test_screen_array = new_screen_array(2, 0x0400, data);

  CHECK_EQ(array_get_length(test_screen_array), 2);

  Screen *test_screen_1 = static_cast<Screen *>(array_get_item_at(test_screen_array, 0));

  CHECK_EQ(scr_get_value_at(test_screen_1, 0x0000), 1);
  CHECK_EQ(scr_get_value_at(test_screen_1, 0x0001), 2);
  CHECK_EQ(scr_get_value_at(test_screen_1, 0x0002), 3);

  Screen *test_screen_2 = static_cast<Screen *>(array_get_item_at(test_screen_array, 1));

  CHECK_EQ(scr_get_value_at(test_screen_2, 0x0000), 4);
  CHECK_EQ(scr_get_value_at(test_screen_2, 0x0001), 5);
  CHECK_EQ(scr_get_value_at(test_screen_2, 0x0002), 6);

  delete_array(test_screen_array);
}

TEST_CASE("bitmap") {
  std::array<uint8_t, bitmap_data_length> bytes{};
  bytes.fill(0xff);
  Bitmap *test_bitmap = new_bitmap(bytes.data());

  uint8_t *data = static_cast<uint8_t *>(bmp_get_data(test_bitmap));
  for (int8_t i = 0; i < 4; ++i) {
    CHECK(*(data + i) == bytes.at(i));
    CHECK(*(data + bitmap_data_length - 1 - i) == bytes.at(bitmap_data_length - 1 - i));
  }

  for (int8_t i = 0; i < 4; ++i) {
    CHECK(bmp_get_value_at_offset(test_bitmap, i) == bytes.at(i));
    CHECK(bmp_get_value_at_offset(test_bitmap, bitmap_data_length - 1 - i) == bytes.at(bitmap_data_length - 1 - i));
  }

  delete_bitmap(test_bitmap);
};

TEST_CASE("screen") {
  std::array<uint8_t, screen_data_length> bytes{};
  bytes.fill(0xff);
  Screen *test_screen = new_screen(bytes.data());

  uint8_t *data = static_cast<uint8_t *>(scr_get_data(test_screen));
  for (int8_t i = 0; i < 4; ++i) {
    CHECK(*(data + i) == bytes.at(i));
    CHECK(*(data + screen_data_length - 1 - i) == bytes.at(screen_data_length - 1 - i));
  }

  for (int8_t i = 0; i < 4; ++i) {
    CHECK(scr_get_value_at(test_screen, i) == bytes.at(i));
    CHECK(scr_get_value_at(test_screen, screen_data_length - 1 - i) == bytes.at(screen_data_length - 1 - i));
  }

  delete_screen(test_screen);
};

TEST_CASE("load art_studio") {
  auto [bytes, size] = read_file(image_art);
  Hires *test_hires = load_art(bytes.get(), size);

  Bitmap *test_bitmap = hpi_get_bitmap(test_hires);
  Screen *test_screen = hpi_get_screen(test_hires);

  uint8_t *head_bitmap_data = static_cast<uint8_t *>(bmp_get_data(test_bitmap));
  uint8_t *head_screen_data = static_cast<uint8_t *>(scr_get_data(test_screen));

  for (int64_t i = 0; i < 32; ++i) {
    CHECK_EQ(*(head_bitmap_data + i), desolate_head_bitmap_data.at(i));
    CHECK_EQ(*(head_screen_data + i), desolate_head_screen_data.at(i));
  }

  delete_hpi(test_hires);
};

TEST_CASE("export art_studio") {
  auto [bytes, size] = read_file(image_art);
  Hires *test_hires = load_art(bytes.get(), size);

  std::byte *test_art_data = export_art(test_hires);

  uint16_t load_address = *(reinterpret_cast<uint16_t *>(test_art_data));
  CHECK_EQ(load_address, test_art_config->load_address);

  uint8_t *head_bitmap_data = reinterpret_cast<uint8_t *>(test_art_data + test_art_config->bitmap_offset);
  uint8_t *head_screen_data = reinterpret_cast<uint8_t *>(test_art_data + test_art_config->screen_offset);

  for (int64_t i = 0; i < 32; ++i) {
    CHECK_EQ(*(head_bitmap_data + i), desolate_head_bitmap_data.at(i));
    CHECK_EQ(*(head_screen_data + i), desolate_head_screen_data.at(i));
  }

  delete_art(test_art_data);
  delete_hpi(test_hires);
}

TEST_CASE("load advanced_art_studio") {
  auto [bytes, size] = read_file(image_aas);
  Multicolour *test_multicolour = load_aas(bytes.get(), size);

  Bitmap *test_bitmap = mcp_get_bitmap(test_multicolour);
  Screen *test_screen = mcp_get_screen(test_multicolour);
  Screen *test_colours = mcp_get_colours(test_multicolour);
  uint8_t background_colour = mcp_get_background_colour(test_multicolour);
  uint8_t border_colour = mcp_get_border_colour(test_multicolour);

  uint8_t *head_bitmap_data = static_cast<uint8_t *>(bmp_get_data(test_bitmap));
  uint8_t *head_screen_data = static_cast<uint8_t *>(scr_get_data(test_screen));
  uint8_t *head_colours_data = static_cast<uint8_t *>(scr_get_data(test_colours));

  for (int64_t i = 0; i < 32; ++i) {
    CHECK_EQ(*(head_bitmap_data + i), frighthof83_head_bitmap_data.at(i));
    CHECK_EQ(*(head_screen_data + i), frighthof83_head_screen_data.at(i));
    CHECK_EQ(*(head_colours_data + i), frighthof83_head_colours_data.at(i));
  }

  CHECK_EQ(background_colour, 0x00);
  CHECK_EQ(border_colour, 0x00);

  delete_mcp(test_multicolour);
};

TEST_CASE("export advanced_art_studio") {
  auto [bytes, size] = read_file(image_aas);
  Multicolour *test_multicolour = load_aas(bytes.get(), size);

  std::byte *test_aas_data = export_aas(test_multicolour);

  uint16_t load_address = *(reinterpret_cast<uint16_t *>(test_aas_data));
  CHECK_EQ(load_address, test_aas_config->load_address);

  uint8_t *head_bitmap_data = reinterpret_cast<uint8_t *>(test_aas_data + test_aas_config->bitmap_offset);
  uint8_t *head_screen_data = reinterpret_cast<uint8_t *>(test_aas_data + test_aas_config->screen_offset);
  uint8_t *head_colours_data = reinterpret_cast<uint8_t *>(test_aas_data + test_aas_config->colours_offset);

  for (int64_t i = 0; i < 32; ++i) {
    CHECK_EQ(*(head_bitmap_data + i), frighthof83_head_bitmap_data.at(i));
    CHECK_EQ(*(head_screen_data + i), frighthof83_head_screen_data.at(i));
    CHECK_EQ(*(head_colours_data + i), frighthof83_head_colours_data.at(i));
  }

  uint8_t background_colour = *(reinterpret_cast<uint8_t *>(test_aas_data) + test_aas_config->background_colour_offset);
  CHECK_EQ(background_colour, frighthof83_background_colour);

  delete_aas(test_aas_data);
  delete_mcp(test_multicolour);
}

TEST_CASE("load facepainter") {
  auto [bytes, size] = read_file(image_fcp);
  Multicolour *test_multicolour = load_fcp(bytes.get(), size);

  Bitmap *test_bitmap = mcp_get_bitmap(test_multicolour);
  Screen *test_screen = mcp_get_screen(test_multicolour);
  Screen *test_colours = mcp_get_colours(test_multicolour);
  uint8_t background_colour = mcp_get_background_colour(test_multicolour);
  uint8_t border_colour = mcp_get_border_colour(test_multicolour);

  uint8_t *head_bitmap_data = static_cast<uint8_t *>(bmp_get_data(test_bitmap));
  uint8_t *head_screen_data = static_cast<uint8_t *>(scr_get_data(test_screen));
  uint8_t *head_colours_data = static_cast<uint8_t *>(scr_get_data(test_colours));

  for (int64_t i = 0; i < 32; ++i) {
    CHECK_EQ(*(head_bitmap_data + i), frighthof83_head_bitmap_data.at(i));
    CHECK_EQ(*(head_screen_data + i), frighthof83_head_screen_data.at(i));
    CHECK_EQ(*(head_colours_data + i), frighthof83_head_colours_data.at(i));
  }

  CHECK_EQ(background_colour, 0x00);
  CHECK_EQ(border_colour, 0x00);

  delete_mcp(test_multicolour);
};

TEST_CASE("export facepainter") {
  auto [bytes, size] = read_file(image_fcp);
  Multicolour *test_multicolour = load_fcp(bytes.get(), size);

  std::byte *test_fcp_data = export_fcp(test_multicolour);

  uint16_t load_address = *(reinterpret_cast<uint16_t *>(test_fcp_data));
  CHECK_EQ(load_address, test_fcp_config->load_address);

  uint8_t *head_bitmap_data = reinterpret_cast<uint8_t *>(test_fcp_data + test_fcp_config->bitmap_offset);
  uint8_t *head_screen_data = reinterpret_cast<uint8_t *>(test_fcp_data + test_fcp_config->screen_offset);
  uint8_t *head_colours_data = reinterpret_cast<uint8_t *>(test_fcp_data + test_fcp_config->colours_offset);

  for (int64_t i = 0; i < 32; ++i) {
    CHECK_EQ(*(head_bitmap_data + i), frighthof83_head_bitmap_data.at(i));
    CHECK_EQ(*(head_screen_data + i), frighthof83_head_screen_data.at(i));
    CHECK_EQ(*(head_colours_data + i), frighthof83_head_colours_data.at(i));
  }

  uint8_t background_colour = *(reinterpret_cast<uint8_t *>(test_fcp_data) + test_fcp_config->background_colour_offset);
  CHECK_EQ(background_colour, frighthof83_background_colour);

  uint8_t border_colour = *(reinterpret_cast<uint8_t *>(test_fcp_data) + test_fcp_config->border_colour_offset);
  CHECK_EQ(border_colour, frighthof83_border_colour);

  delete_fcp(test_fcp_data);
  delete_mcp(test_multicolour);
}

TEST_CASE("load koalapainter") {
  auto [bytes, size] = read_file(image_kla);
  Multicolour *test_multicolour = load_kla(bytes.get(), size);

  Bitmap *test_bitmap = mcp_get_bitmap(test_multicolour);
  Screen *test_screen = mcp_get_screen(test_multicolour);
  Screen *test_colours = mcp_get_colours(test_multicolour);
  uint8_t background_colour = mcp_get_background_colour(test_multicolour);
  uint8_t border_colour = mcp_get_border_colour(test_multicolour);

  uint8_t *head_bitmap_data = static_cast<uint8_t *>(bmp_get_data(test_bitmap));
  uint8_t *head_screen_data = static_cast<uint8_t *>(scr_get_data(test_screen));
  uint8_t *head_colours_data = static_cast<uint8_t *>(scr_get_data(test_colours));

  for (int64_t i = 0; i < 32; ++i) {
    CHECK_EQ(*(head_bitmap_data + i), frighthof83_head_bitmap_data.at(i));
    CHECK_EQ(*(head_screen_data + i), frighthof83_head_screen_data.at(i));
    CHECK_EQ(*(head_colours_data + i), frighthof83_head_colours_data.at(i));
  }

  CHECK_EQ(background_colour, 0x00);
  CHECK_EQ(border_colour, 0x00);

  delete_mcp(test_multicolour);
};

TEST_CASE("export koalapainter") {
  auto [bytes, size] = read_file(image_kla);
  Multicolour *test_multicolour = load_kla(bytes.get(), size);

  std::byte *test_kla_data = export_kla(test_multicolour);

  uint16_t load_address = *(reinterpret_cast<uint16_t *>(test_kla_data));
  CHECK_EQ(load_address, test_kla_config->load_address);

  uint8_t *head_bitmap_data = reinterpret_cast<uint8_t *>(test_kla_data + test_kla_config->bitmap_offset);
  uint8_t *head_screen_data = reinterpret_cast<uint8_t *>(test_kla_data + test_kla_config->screen_offset);
  uint8_t *head_colours_data = reinterpret_cast<uint8_t *>(test_kla_data + test_kla_config->colours_offset);

  for (int64_t i = 0; i < 32; ++i) {
    CHECK_EQ(*(head_bitmap_data + i), frighthof83_head_bitmap_data.at(i));
    CHECK_EQ(*(head_screen_data + i), frighthof83_head_screen_data.at(i));
    CHECK_EQ(*(head_colours_data + i), frighthof83_head_colours_data.at(i));
  }

  uint8_t background_colour = *(reinterpret_cast<uint8_t *>(test_kla_data) + test_kla_config->background_colour_offset);
  CHECK_EQ(background_colour, frighthof83_background_colour);

  delete_kla(test_kla_data);
  delete_mcp(test_multicolour);
}

TEST_CASE("hires") {
  auto [bytes, size] = read_file(image_art);
  Hires *test_hires = load_art(bytes.get(), size);

  CHECK_EQ(hpi_get_cbm_value_at_xy(test_hires, 0, 0), 0x09);  // brown
  CHECK_EQ(hpi_get_cbm_value_at_xy(test_hires, 0, 199), 0x00);  // black
  CHECK_EQ(hpi_get_cbm_value_at_xy(test_hires, 319, 0), 0x00);  // black
  CHECK_EQ(hpi_get_cbm_value_at_xy(test_hires, 319, 199), 0x00);  // black

  delete_hpi(test_hires);
};

TEST_CASE("multicolour") {
  auto [bytes, size] = read_file(image_fcp);
  Multicolour *test_multicolour = load_fcp(bytes.get(), size);

  CHECK_EQ(mcp_get_cbm_value_at_xy(test_multicolour, 0, 0, mcp_get_screen_at_y), 0x00);  // black
  CHECK_EQ(mcp_get_cbm_value_at_xy(test_multicolour, 0, 199, mcp_get_screen_at_y), 0x00);  // black
  CHECK_EQ(mcp_get_cbm_value_at_xy(test_multicolour, 159, 0, mcp_get_screen_at_y), 0x00);  // black
  CHECK_EQ(mcp_get_cbm_value_at_xy(test_multicolour, 159, 199, mcp_get_screen_at_y), 0x04);  // purple

  delete_mcp(test_multicolour);
};

TEST_CASE("colour (colodore)") {
  static const ColourPalette *palette = get_colour_palette(colour_palette_colodore);

  Colour *red = new_colour(0x02, nullptr, palette);
  Colour *green = new_colour(0x05, nullptr, palette);
  Colour *blue = new_colour(0x06, nullptr, palette);

  CHECK(col_get_cbm_value(red) == 0x02);
  CHECK(col_get_cbm_value(green) == 0x05);
  CHECK(col_get_cbm_value(blue) == 0x06);

  CHECK(col_get_rgb_value(red) == 0x00813338);
  CHECK(col_get_rgb_value(green) == 0x0056ac4d);
  CHECK(col_get_rgb_value(blue) == 0x002e2c9b);

  delete_colour(red);
  delete_colour(green);
  delete_colour(blue);
}

TEST_CASE("colour (pepto)") {
  static const ColourPalette *palette = get_colour_palette(colour_palette_pepto);

  Colour *red = new_colour(0x02, nullptr, palette);
  Colour *green = new_colour(0x05, nullptr, palette);
  Colour *blue = new_colour(0x06, nullptr, palette);

  CHECK(col_get_cbm_value(red) == 0x02);
  CHECK(col_get_cbm_value(green) == 0x05);
  CHECK(col_get_cbm_value(blue) == 0x06);

  CHECK(col_get_rgb_value(red) == 0x0068372b);
  CHECK(col_get_rgb_value(green) == 0x00588d43);
  CHECK(col_get_rgb_value(blue) == 0x00352879);

  delete_colour(red);
  delete_colour(green);
  delete_colour(blue);
}

TEST_CASE("get_nearest_cbm_value") {
  static const ColourPalette *palette_colodore = get_colour_palette(colour_palette_colodore);
  static const ColourPalette *palette_pepto = get_colour_palette(colour_palette_pepto);

  uint8_t rgba_yellow_pepto[4] = { 0xb8, 0xc7, 0x6f, 0x00 };
  uint8_t rgba_yellow_colodore[4] = { 0xed, 0xf1, 0x71, 0x00 };

  uint32_t yellow_pepto = *reinterpret_cast<uint32_t *>(rgba_yellow_pepto);
  uint32_t yellow_colodore = *reinterpret_cast<uint32_t *>(rgba_yellow_colodore);

  CHECK_EQ(get_nearest_cbm_value(palette_colodore, yellow_pepto), 0x07);  // yellow
  CHECK_EQ(get_nearest_cbm_value(palette_pepto, yellow_pepto), 0x07);  // yellow

  CHECK_EQ(get_nearest_cbm_value(palette_colodore, yellow_colodore), 0x07);  // yellow
  CHECK_EQ(get_nearest_cbm_value(palette_pepto, yellow_colodore), 0x07);  // yellow
}

TEST_CASE("pixel_map") {
  auto [bytes, size] = read_file(image_fcp);
  Multicolour *test_multicolour = load_fcp(bytes.get(), size);

  PixelMap *test_pixel_map = mcp_get_pixels(test_multicolour, colour_palette_colodore);

  CHECK_EQ(pix_get_cbm_colour_at(test_pixel_map, 0, 0), 0x00);  // black
  CHECK_EQ(pix_get_cbm_colour_at(test_pixel_map, 0, 199), 0x00);  // black
  CHECK_EQ(pix_get_cbm_colour_at(test_pixel_map, 319, 0), 0x00);  // black
  CHECK_EQ(pix_get_cbm_colour_at(test_pixel_map, 319, 199), 0x04);  // purple

  CHECK_EQ(pix_get_rgb_colour_at(test_pixel_map, 0, 0), 0x00000000);  // black
  CHECK_EQ(pix_get_rgb_colour_at(test_pixel_map, 0, 199), 0x00000000);  // black
  CHECK_EQ(pix_get_rgb_colour_at(test_pixel_map, 319, 0), 0x00000000);  // black
  CHECK_EQ(pix_get_rgb_colour_at(test_pixel_map, 319, 199), 0x008e3c97);  // purple

  uint8_t rgba_black_pepto[4] = { 0x00, 0x00, 0x00, 0x00 };
  uint8_t rgba_purple_pepto[4] = { 0x8e, 0x3c, 0x97, 0x00 };

  uint32_t black_pepto = *reinterpret_cast<uint32_t *>(rgba_black_pepto);
  uint32_t purple_pepto = *reinterpret_cast<uint32_t *>(rgba_purple_pepto);

  CHECK_EQ(pix_get_original_rgb_colour_at(test_pixel_map, 0, 0), black_pepto);
  CHECK_EQ(pix_get_original_rgb_colour_at(test_pixel_map, 0, 199), black_pepto);
  CHECK_EQ(pix_get_original_rgb_colour_at(test_pixel_map, 319, 0), black_pepto);
  CHECK_EQ(pix_get_original_rgb_colour_at(test_pixel_map, 319, 199), purple_pepto);

  delete_pixel_map(test_pixel_map);
  delete_mcp(test_multicolour);
};

TEST_CASE("hpi2png") {
  auto [bytes, size] = read_file(image_art);
  Hires *test_hires = load_art(bytes.get(), size);

  const char *image_png = "desolate.png";

  hpi2png(test_hires, image_png);

  fs::remove(image_png);

  delete_hpi(test_hires);
}

TEST_CASE("mcp2png") {
  auto [bytes, size] = read_file(image_fcp);
  Multicolour *test_multicolour = load_fcp(bytes.get(), size);

  const char *image_png = "frighthof83.png";

  mcp2png(test_multicolour, image_png);

  fs::remove(image_png);

  delete_mcp(test_multicolour);
}

TEST_CASE("identify_most_common_colour") {
  auto [bytes, size] = read_file(image_fcp);
  Multicolour *test_multicolour = load_fcp(bytes.get(), size);

  PixelMap *test_pixel_map = mcp_get_pixels(test_multicolour, colour_palette_pepto);

  uint8_t background_colour = identify_most_common_colour(test_pixel_map);

  CHECK_EQ(background_colour, 0x00);  // black

  delete_pixel_map(test_pixel_map);
  delete_mcp(test_multicolour);
}

TEST_CASE("collect_most_frequent_colours (hpi)") {
  auto [bytes, size] = read_file(image_art);
  Hires *test_hires = load_art(bytes.get(), size);

  PixelMap *test_pixel_map = hpi_get_pixels(test_hires, colour_palette_pepto);

  uint8_t *hpi_char_block_colours = static_cast<uint8_t *>(malloc(2));
  collect_most_frequent_colours(test_pixel_map, 8, 0, 8, 8, hpi_char_block_colours, 2, 0xff, 1);
  CHECK_EQ(hpi_char_block_colours[0], 0x09);  // brown
  CHECK_EQ(hpi_char_block_colours[1], 0x08);  // orange
  free(hpi_char_block_colours);

  delete_pixel_map(test_pixel_map);
  delete_hpi(test_hires);
}

TEST_CASE("collect_most_frequent_colours (mcp)") {
  auto [bytes, size] = read_file(image_fcp);
  Multicolour *test_multicolour = load_fcp(bytes.get(), size);

  PixelMap *test_pixel_map = mcp_get_pixels(test_multicolour, colour_palette_pepto);

  uint8_t *mcp_char_block_colours = static_cast<uint8_t *>(malloc(3));

  collect_most_frequent_colours(test_pixel_map, 8, 0, 8, 8, mcp_char_block_colours, 3, 0, 2);
  CHECK_EQ(mcp_char_block_colours[0], 0x06);  // blue
  CHECK_EQ(mcp_char_block_colours[1], 0x00);  // black
  CHECK_EQ(mcp_char_block_colours[2], 0x00);  // black

  collect_most_frequent_colours(test_pixel_map, 16, 0, 8, 8, mcp_char_block_colours, 3, 0, 2);
  CHECK_EQ(mcp_char_block_colours[0], 0x06);  // blue
  CHECK_EQ(mcp_char_block_colours[1], 0x04);  // purple
  CHECK_EQ(mcp_char_block_colours[2], 0x0a);  // light red

  free(mcp_char_block_colours);

  delete_pixel_map(test_pixel_map);
  delete_mcp(test_multicolour);
}

TEST_CASE("sort_colour_count_frequencies") {
  uint16_t test_indexed_colour_counts[16] = { 0, 0, 0, 0, 10, 0, 24, 0, 0, 0, 6, 0, 0, 0, 0, 0 };
  uint8_t test_sorted_colour_indexes[16] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };

  sort_colour_count_frequencies(test_indexed_colour_counts, test_sorted_colour_indexes, 0, 15);

  CHECK_EQ(test_indexed_colour_counts[0], 24);
  CHECK_EQ(test_indexed_colour_counts[1], 10);
  CHECK_EQ(test_indexed_colour_counts[2], 6);

  CHECK_EQ(test_sorted_colour_indexes[0], 6);
  CHECK_EQ(test_sorted_colour_indexes[1], 4);
  CHECK_EQ(test_sorted_colour_indexes[2], 10);
}

TEST_CASE("swap_array_items") {
  uint8_t test_byte_array[3] = { 1, 2, 3 };

  swap_array_items(test_byte_array, 0, 2, 1);

  CHECK_EQ(test_byte_array[0], 3);
  CHECK_EQ(test_byte_array[1], 2);
  CHECK_EQ(test_byte_array[2], 1);

  uint16_t test_word_array[3] = { 1024, 2048, 4096 };

  swap_array_items(test_word_array, 0, 1, 2);

  CHECK_EQ(test_word_array[0], 2048);
  CHECK_EQ(test_word_array[1], 1024);
  CHECK_EQ(test_word_array[2], 4096);

  uint64_t test_quadword_array[3] = { 0, 1, 0xffffffff00000000 };

  swap_array_items(test_quadword_array, 1, 2, 8);

  CHECK_EQ(test_quadword_array[0], 0);
  CHECK_EQ(test_quadword_array[1], 0xffffffff00000000);
  CHECK_EQ(test_quadword_array[2], 1);
}

TEST_CASE("png2mcp (non-interpolated, no background colour)") {
  fs::path image_png = fs::canonical(fixtures / "frighthof83.png").string();
  Multicolour *test_multicolour = png2mcp(image_png.c_str());

  Bitmap *test_bitmap = mcp_get_bitmap(test_multicolour);
  Screen *test_screen = mcp_get_screen(test_multicolour);
  Screen *test_colours = mcp_get_colours(test_multicolour);
  uint8_t background_colour = mcp_get_background_colour(test_multicolour);
  uint8_t border_colour = mcp_get_border_colour(test_multicolour);

  uint8_t *head_bitmap_data = static_cast<uint8_t *>(bmp_get_data(test_bitmap));
  uint8_t *head_screen_data = static_cast<uint8_t *>(scr_get_data(test_screen));
  uint8_t *head_colours_data = static_cast<uint8_t *>(scr_get_data(test_colours));

  const std::array<uint8_t, 32> expected_head_bitmap_data{
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x11, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
    0x1e, 0x1a, 0x42, 0x53, 0x47, 0x16, 0x05, 0x01,
    0x95, 0x65, 0x99, 0xa5, 0x65, 0x56, 0x5a, 0x96,
  };

  const std::array<uint8_t, 32> expected_head_screen_data{
    0x00, 0x60, 0x64, 0x4a, 0x4a, 0x4a, 0x4a, 0x4a,
    0xa7, 0xa7, 0x7a, 0x17, 0x17, 0x10, 0x10, 0x1d,
    0x1d, 0x1d, 0xd1, 0xd0, 0xd7, 0x7d, 0x7d, 0x73,
    0x37, 0x3e, 0xe3, 0xe3, 0xe6, 0x6e, 0x6e, 0x6e,
  };

  const std::array<uint8_t, 32> expected_head_colours_data{
    0x00, 0x00, 0x0a, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x04, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x0d, 0x0f, 0x00, 0x0f, 0x03, 0x00, 0x00, 0x00,
  };

  for (int64_t i = 0; i < 32; ++i) {
    CHECK_EQ(*(head_bitmap_data + i), expected_head_bitmap_data.at(i));
    CHECK_EQ(*(head_screen_data + i), expected_head_screen_data.at(i));
    CHECK_EQ(*(head_colours_data + i), expected_head_colours_data.at(i));
  }

  CHECK_EQ(background_colour, frighthof83_background_colour);
  CHECK_EQ(border_colour, frighthof83_border_colour);

  delete_mcp(test_multicolour);
}

TEST_CASE("collect_mcp_block_colour_data") {
  fs::path image_png = fs::canonical(fixtures / "frighthof83-interpolated.png").string();
  Multicolour *test_multicolour = png2mcp(image_png.c_str(), -1, true);

  PixelMap *test_pixel_map = mcp_get_pixels(test_multicolour, colour_palette_pepto);

  uint8_t target_bitmap_data[8];
  uint8_t target_screen_data;
  uint8_t target_colours_data;

  collect_mcp_block_colour_data(test_pixel_map, 40, 56, target_bitmap_data, &target_screen_data, &target_colours_data, 0, 1);

  const std::array<uint8_t, 32> expected_bitmap_data{
    0x01, 0x44, 0x13, 0x50, 0x48, 0x60, 0x20, 0x40,
  };

  for (int64_t i = 0; i < 8; ++i) {
    CHECK_EQ(*(target_bitmap_data + i), expected_bitmap_data.at(i));
  }

  CHECK_EQ(target_screen_data, 0x6e);
  CHECK_EQ(target_colours_data, 0x04);

  delete_pixel_map(test_pixel_map);
  delete_mcp(test_multicolour);
}

TEST_CASE("png2mcp (interpolated, no background colour)") {
  fs::path image_png = fs::canonical(fixtures / "frighthof83-interpolated.png").string();
  Multicolour *test_multicolour = png2mcp(image_png.c_str(), -1, true);

  PixelMap *test_pixel_map = mcp_get_pixels(test_multicolour, colour_palette_pepto);

  uint8_t rgba_blue_pepto[4] = { 0x6f, 0x3d, 0x86, 0x00 };
  uint32_t blue_pepto = *reinterpret_cast<uint32_t *>(rgba_blue_pepto);

  // An extraneous dark grey pixel interpolated as a blue colour:
  CHECK_EQ(pix_get_original_rgb_colour_at(test_pixel_map, 46, 58), blue_pepto);

  uint8_t rgba_grey_pepto[4] = { 0x6c, 0x6c, 0x6c, 0x00 };
  uint32_t grey_pepto = *reinterpret_cast<uint32_t *>(rgba_grey_pepto);

  // An extraneous dark grey pixel interpolated as a grey colour:
  CHECK_EQ(pix_get_original_rgb_colour_at(test_pixel_map, 170, 149), grey_pepto);

  delete_pixel_map(test_pixel_map);
  delete_mcp(test_multicolour);
}

TEST_CASE("png2hpi (non-interpolated)") {
  fs::path image_png = fs::canonical(fixtures / "desolate.png").string();
  Hires *test_hires = png2hpi(image_png.c_str());

  Bitmap *test_bitmap = hpi_get_bitmap(test_hires);
  Screen *test_screen = hpi_get_screen(test_hires);

  uint8_t *head_bitmap_data = static_cast<uint8_t *>(bmp_get_data(test_bitmap));
  uint8_t *head_screen_data = static_cast<uint8_t *>(scr_get_data(test_screen));

  const std::array<uint8_t, 32> expected_head_bitmap_data{
    0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x41,
    0x50, 0x21, 0x00, 0x00, 0x00, 0x00, 0x88, 0x00,
    0x02, 0x05, 0x42, 0xa5, 0x4a, 0x17, 0x2f, 0x17,
    0xff, 0xfa, 0xf5, 0xe8, 0xc0, 0x80, 0x40, 0x80,
  };

  const std::array<uint8_t, 32> expected_head_screen_data{
    0x89, 0x89, 0x89, 0x8c, 0x8c, 0xc8, 0x8c, 0x8c,
    0x7c, 0x7c, 0xac, 0xca, 0xca, 0xfa, 0xfa, 0xfa,
    0xfa, 0xaf, 0xfa, 0xfa, 0xfa, 0xfa, 0xca, 0xca,
    0xca, 0xca, 0xfa, 0xfa, 0xca, 0xca, 0xac, 0xc7,
  };

  for (int64_t i = 0; i < 32; ++i) {
    CHECK_EQ(*(head_bitmap_data + i), expected_head_bitmap_data.at(i));
    CHECK_EQ(*(head_screen_data + i), expected_head_screen_data.at(i));
  }

  delete_hpi(test_hires);
}

TEST_CASE("png2hpi (interpolated)") {
  fs::path image_png = fs::canonical(fixtures / "desolate-interpolated.png").string();
  Hires *test_hires = png2hpi(image_png.c_str(), true);

  PixelMap *test_pixel_map = hpi_get_pixels(test_hires, colour_palette_pepto);

  uint8_t rgba_black_pepto[4] = { 0x00, 0x00, 0x00, 0x00 };
  uint32_t black_pepto = *reinterpret_cast<uint32_t *>(rgba_black_pepto);

  // An extraneous dark grey pixel interpolated as a black colour:
  CHECK_EQ(pix_get_original_rgb_colour_at(test_pixel_map, 192, 87), black_pepto);

  uint8_t rgba_cyan_pepto[4] = { 0x70, 0xa4, 0xb2, 0x00 };
  uint32_t cyan_pepto = *reinterpret_cast<uint32_t *>(rgba_cyan_pepto);

  // An extraneous light grey pixel interpolated as a cyan colour:
  CHECK_EQ(pix_get_original_rgb_colour_at(test_pixel_map, 212, 198), cyan_pepto);

  delete_pixel_map(test_pixel_map);
  delete_hpi(test_hires);
}
