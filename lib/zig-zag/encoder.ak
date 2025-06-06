use aiken/primitive/bytearray

/// Attempts to encode the given integer in 8 bits (1 byte).
pub fn zig_zag_8(num: Int) -> ByteArray {
  let zig_zag =
    if num < 0 {
      num * -2 - 1
    } else {
      num * 2
    }
  bytearray.from_int_big_endian(zig_zag, 1)
}
