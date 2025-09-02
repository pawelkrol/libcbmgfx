# HOWTO

## High-Level C/C++ API

### Supported colour palettes

```
enum colour_palette {
  colour_palette_default  = 0,
  colour_palette_pepto    = 1,
  colour_palette_colodore = 2,
  colour_palette_vice     = 3,
};
```

`colour_palette` enumeration defines the list of available
colour palettes, which is required as an optional argument
to various function calls. The default palette is `pepto`.

### Convert `Hires` image to `PNG` file

```
void hpi2png(
    Hires *hpi,
    const char *png,
    enum colour_palette palette = colour_palette_default);
```

`hpi` is a pointer to a `Hires` image data structure to be
converted.

`png` is a file path to the target `PNG` file. Target file
must not exist (function will not overwrite existing files).

`palette` determines RGB colours used when rendering image
pixels of the target `PNG` picture.

### Convert `Multicolour` image to `PNG` file

```
void mcp2png(
    Multicolour *mcp,
    const char *png,
    enum colour_palette palette = colour_palette_default);
```

`mcp` is a pointer to a `Multicolour` image data structure
to be converted.

`png` is a file path to the target `PNG` file. Target file
must not exist (function will not overwrite existing files).

`palette` determines RGB colours used when rendering image
pixels of the target `PNG` picture.

### Convert `PNG` file to `Hires` image

```
Hires *png2hpi(
    const char *png,
    bool interpolate = false,
    enum colour_palette palette = colour_palette_default);
```

`png` is a file path to the source `PNG` file. It goes
without saying that the source file must exist.

When `interpolate` is set to `false`, any extraneous pixel
colours in the source `PNG` picture that do not conform to
the limitations enforced by the `Hires` format will trigger
an irrecoverable program error. When `interpolate` is set
to `true`, all extraneous pixel colours will be interpolated
to the nearest colour of the other 2 most frequent colours
in every 8x8 pixel block.

`palette` determines accepted RGB colours used when reading
image pixels from a `PNG` picture. CBM image format enforces
limiting the total number of available colours down to 16.
Each pixel colour in a `PNG` picture that finds no matching
colour in the selected palette will be interpolated into the
nearest matching available colour. Depending on the colour
palette of the source `PNG` picture, this may result in an
imperfect replication of the pixel colours, especially when
a mismatched colour palette is applied during the conversion
process.

Returned value is a pointer to a newly allocated `Hires`
image data structure. Allocated data must be freed when it
is no longer needed in order to prevent memory leaks.

### Convert `PNG` file to `Multicolour` image

```
Multicolour *png2mcp(
    const char *png,
    uint8_t background_colour = -1,
    bool interpolate = false,
    enum colour_palette palette = colour_palette_default);
```

`png` is a file path to the source `PNG` file. It goes
without saying that the source file must exist.

Due to image resolution differences, i.e. `Multicolour`
image pixels having double width, the conversion process
will skip every second pixel of the input `PNG` picture.

`background_colour` is a CBM colour used as a `$d021` value
shared by all pixels of the entire colour map. When set to
`-1`, it will default to identify the most frequent colour
in the picture as a background colour.

When `interpolate` is set to `false`, any extraneous pixel
colours in the source `PNG` picture that do not conform to
the limitations enforced by the `Multicolour` format will
trigger an irrecoverable program error. When `interpolate`
is set to `true`, all extraneous pixel colours will be
interpolated to the nearest colour of the other 4 most
frequent colours in every 8x8 pixel block.

`palette` determines accepted RGB colours used when reading
image pixels from a `PNG` picture. CBM image format enforces
limiting the total number of available colours down to 16.
Each pixel colour in a `PNG` picture that finds no matching
colour in the selected palette will be interpolated into the
nearest matching available colour. Depending on the colour
palette of the source `PNG` picture, this may result in an
imperfect replication of the pixel colours, especially when
a mismatched colour palette is applied during the conversion
process.

Returned value is a pointer to a newly allocated
`Multicolour` image data structure. Allocated data must
be freed when it is no longer needed in order to prevent
memory leaks.

## Low-level ASM/C API

### Load `Art Studio` picture

```
extern "C" Hires *load_art(
    std::byte *data,
    std::size_t data_size);
```

`data` is a pointer to a contiguous sequence of bytes read
from the raw `Art Studio` file (loading address included).

`data_size` determines the total length of `data` and it
must equal to `9002` for an image to be loaded successfully.

Returned value is a pointer to a newly allocated `Hires`
image data structure. Allocated data must be freed when it
is no longer needed in order to prevent memory leaks.

### Load `Advanced Art Studio` picture

```
extern "C" Multicolour *load_aas(
    std::byte *data,
    std::size_t data_size);
```

`data` is a pointer to a contiguous sequence of bytes read
from the raw `Advanced Art Studio` file (loading address
included).

`data_size` determines the total length of `data` and it
must equal to `10018` for an image to be loaded successfully.

Returned value is a pointer to a newly allocated
`Multicolour` image data structure. Allocated data must
be freed when it is no longer needed in order to prevent
memory leaks.

### Load `FacePainter` picture

```
extern "C" Multicolour *load_fcp(
    std::byte *data,
    std::size_t data_size);
```

`data` is a pointer to a contiguous sequence of bytes read
from the raw `FacePainter` file (loading address included).

`data_size` determines the total length of `data` and it
must equal to `10004` for an image to be loaded successfully.

Returned value is a pointer to a newly allocated
`Multicolour` image data structure. Allocated data must
be freed when it is no longer needed in order to prevent
memory leaks.

### Load `KoalaPainter` picture

```
extern "C" Multicolour *load_kla(
    std::byte *data,
    std::size_t data_size);
```

`data` is a pointer to a contiguous sequence of bytes read
from the raw `KoalaPainter` file (loading address included).

`data_size` determines the total length of `data` and it
must equal to `10003` for an image to be loaded successfully.

Returned value is a pointer to a newly allocated
`Multicolour` image data structure. Allocated data must
be freed when it is no longer needed in order to prevent
memory leaks.

### Delete `Hires` object

```
extern "C" void delete_hpi(
    Hires *hpi);
```

`hpi` is a pointer to a `Hires` image data structure to be
deallocated.

### Delete `Multicolour` object

```
extern "C" void delete_mcp(
    Multicolour *mcp);
```

`mcp` is a pointer to a `Multicolour` image data structure
to be deallocated.

### Export `Art Studio` data

```
extern "C" std::byte *export_art(
    Hires *hpi);
```

`hpi` is a pointer to a `Hires` image data structure to be
exported.

Returned value is a pointer to a newly allocated contiguous
sequence of `9002` bytes with the raw `Art Studio` file data
(loading address included). Allocated data must be freed
when it is no longer needed in order to prevent memory leaks.

### Export `Advanced Art Studio` data

```
extern "C" std::byte *export_aas(
    Multicolour *mcp);
```

`mcp` is a pointer to a `Multicolour` image data structure
to be exported.

Returned value is a pointer to a newly allocated contiguous
sequence of `10018` bytes with the raw `Advanced Art Studio`
file data (loading address included). Allocated data must be
freed when it is no longer needed in order to prevent memory
leaks.

### Export `FacePainter` data

```
extern "C" std::byte *export_fcp(
    Multicolour *mcp);
```

`mcp` is a pointer to a `Multicolour` image data structure
to be exported.

Returned value is a pointer to a newly allocated contiguous
sequence of `10004` bytes with the raw `FacePainter` file
data (loading address included). Allocated data must be freed
when it is no longer needed in order to prevent memory leaks.

### Export `KoalaPainter` data

```
extern "C" std::byte *export_kla(
    Multicolour *mcp);
```

`mcp` is a pointer to a `Multicolour` image data structure
to be exported.

Returned value is a pointer to a newly allocated contiguous
sequence of `10003` bytes with the raw `KoalaPainter` file
data (loading address included). Allocated data must be freed
when it is no longer needed in order to prevent memory leaks.

### Delete `Art Studio` data

```
extern "C" void delete_art(
    std::byte *art_data);
```

`art_data` is a pointer to a sequence of `9002` bytes to be
deallocated.

### Delete `Advanced Art Studio` data

```
extern "C" void delete_aas(
    std::byte *aas_data);
```

`aas_data` is a pointer to a sequence of `10018` bytes to be
deallocated.

### Delete `FacePainter` data

```
extern "C" void delete_fcp(
    std::byte *fcp_data);
```

`fcp_data` is a pointer to a sequence of `10004` bytes to be
deallocated.

### Delete `KoalaPainter` data

```
extern "C" void delete_kla(
    std::byte *kla_data);
```

`kla_data` is a pointer to a sequence of `10003` bytes to be
deallocated.

### Get `Hires` pixel colours

```
extern "C" PixelMap *hpi_get_pixels(
    Hires *hpi,
    enum colour_palette palette = colour_palette_default);
```

`hpi` is a pointer to a `Hires` image data structure to be
accessed.

`palette` determines RGB colours used when rendering image
pixels onto the canvas.

Returned value provides direct access to individual pixels
of a `PNG` picture. Allocated data structure must be freed
when it is no longer needed in order to prevent memory leaks.

### Get `Multicolour` pixel colours

```
extern "C" PixelMap *mcp_get_pixels(
    Multicolour *mcp,
    enum colour_palette palette = colour_palette_default);
```

`mcp` is a pointer to a `Multicolour` image data structure
to be accessed.

`palette` determines RGB colours used when rendering image
pixels onto the canvas.

Returned value provides direct access to individual pixels
of a `PNG` picture. Allocated data structure must be freed
when it is no longer needed in order to prevent memory leaks.

### Import `PNG` picture

```
extern "C" PixelMap *import_png(
    png_bytep *row_pointers,
    enum colour_palette palette,
    png_uint_32 width,
    png_uint_32 height,
    uint8_t background_colour = -1);
```

`row_pointers` is an array of pointers to the pixel data
for each row. Please check [libpng-manual.txt] for more
details.

`palette` determines RGB colours used when rendering image
pixels onto the canvas. CBM image format enforces limiting
the total number of available colours down to 16. Each pixel
colour in the original picture that finds no matching colour
in the current palette will be interpolated into the nearest
matching available colour.

`width` declares the width of the imported `PNG` image. It
will be cropped if greater than `320`, it will be extended
when less than `320`, so that the pixel map has always the
same width of `320`.

`height` declares the height of the imported `PNG` image. It
will be cropped if greater than `200`, it will be extended
when less than `200`, so that the pixel map has always the
same height of `200`.

`background_colour` is a CBM colour used for backfilling
all out-of-bound pixels, that is all non-existing pixels
beyond the declared `PNG` image dimensions. If set to `-1`,
it will default to the black background colour.

Returned value provides direct access to individual pixels
of a `PNG` picture reduced to selected CBM colour palette.
Allocated data structure must be freed when it is no longer
needed in order to prevent memory leaks.

### Get RGB pixel colour

```
extern "C" uint32_t pix_get_rgb_colour_at(
    PixelMap *pix,
    uint16_t x,
    uint16_t y);
```

`pix` is a pointer to a `PixelMap` data structure to be
read from.

`x` is the X coordinate of the target pixel in the range
of `0` and `319`.

`y` is the Y coordinate of the target pixel in the range
of `0` and `199`.

Returned value is a packed sequence of 3 colour bytes in
the form of `0x00RRGGBB`, where `RR` is the red colour
value, `GG` is the green colour value, `BB` is the blue
colour value.

### Delete `PixelMap` object

```
extern "C" void delete_pixel_map(
    PixelMap *pix);
```

`pix` is a pointer to a `PixelMap` data structure to be
deallocated.

### Convert picture to `Hires` format

```
extern "C" Hires *pix2hpi(
    PixelMap *pix,
    bool interpolate = false);
```

`pix` is a pointer to a `PixelMap` data structure to be
converted.

When `interpolate` is set to `false`, any extraneous pixel
colours that do not conform to the limitations enforced by
the `Hires` format will trigger an irrecoverable program
error. When `interpolate` is set to `true`, all extraneous
pixel colours will be interpolated to the nearest colour
of the other 2 most frequent colours in every 8x8 pixel
block.

Returned value is a pointer to a newly allocated `Hires`
image data structure. Allocated data must be freed when it
is no longer needed in order to prevent memory leaks.

### Convert picture to `Multicolour` format

```
extern "C" Multicolour *pix2mcp(
    PixelMap *pix,
    uint8_t background_colour = -1,
    bool interpolate = false);
```

`pix` is a pointer to a `PixelMap` data structure to be
converted.

`background_colour` is a CBM colour used as a `$d021` value
shared by all pixels of the entire colour map. When set to
`-1`, it will default to identify the most frequent colour
in the picture as a background colour.

When `interpolate` is set to `false`, any extraneous pixel
colours that do not conform to the limitations enforced by
the `Multicolour` format will trigger an irrecoverable
program error. When `interpolate` is set to `true`, all
extraneous pixel colours will be interpolated to the
nearest colour of the other 4 most frequent colours in
every 8x8 pixel block.

Returned value is a pointer to a newly allocated
`Multicolour` image data structure. Allocated data must
be freed when it is no longer needed in order to prevent
memory leaks.

## Examples

### CBM/CBM format conversion workflow

```
#include "cbmgfx.h"

// Define KoalaPainter file size:
constexpr std::size_t kla_size = 10003;

// Read KoalaPainter file data:
std::byte kla_data[kla_size] = { 0x00, 0x60, ... };

// Build Multicolour image from KoalaPainter file:
Multicolour *mcp = load_kla(kla_data, kla_size);

// Export Multicolour image to FacePainter format:
std::byte *fcp_data = export_fcp(mcp);

// Save the sequence of 10004 data bytes into a file.

// Free all previously allocated memory:
delete_fcp(fcp_data);
delete_mcp(mcp);
```

### CBM/PNG format conversion workflow

```
#include "cbmgfx.h"

// Define KoalaPainter file size:
constexpr std::size_t kla_size = 10003;

// Read KoalaPainter file data:
std::byte kla_data[kla_size] = { 0x00, 0x60, ... };

// Build Multicolour image from KoalaPainter file:
Multicolour *mcp = load_kla(kla_data, kla_size);

// Convert Multicolour image to PNG format:
mcp2png(mcp, "image.png");

// Free all previously allocated memory:
delete_mcp(mcp);
```

### PNG/CBM format conversion workflow

```
#include "cbmgfx.h"

// Convert PNG file to Multicolour image:
Multicolour *mcp = png2mcp("image.png");

// Export Multicolour image to FacePainter format:
std::byte *fcp_data = export_fcp(mcp);

// Save the sequence of 10004 data bytes into a file.

// Free all previously allocated memory:
delete_fcp(fcp_data);
delete_mcp(mcp);
```


[libpng-manual.txt]: https://www.libpng.org/pub/png/libpng-manual.txt
