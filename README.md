# RGB <-> YUV (YCbCr 601, PC-range)

**prototypes**:

```c
void RGB2YUV(const uint8_t *in, uint8_t *restrict out, size_t width, size_t height, ptrdiff_t in_stride, ptrdiff_t out_stride);

void YUV2RGB(const uint8_t *in, uint8_t *restrict out, size_t width, size_t height, ptrdiff_t in_stride, ptrdiff_t out_stride);
```

`_stride` is the distance (in bytes, signed) between the first point of one line and the first point of the next line.

RGB data is stored in memory in the order: *R G B R G B...*

YUV data is stored in memory in the order: *Y U V X Y U V X...*, where X is an arbitrary value (0 when writing, not considered when reading).
