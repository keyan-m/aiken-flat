use aiken/primitive/bytearray

/// Attempts to encode the given integer in the given number of bytes.
fn zig_zag(num: Int, size: Int) -> ByteArray {
  let zig_zag =
    if num < 0 {
      num * -2 - 1
    } else {
      num * 2
    }
  bytearray.from_int_big_endian(zig_zag, size)
}

/// Attempts to encode the given integer in 8 bits (1 byte).
pub fn zig_zag_8(num: Int) -> ByteArray {
  zig_zag(num, 1)
}

/// Attempts to encode the given integer in 16 bits (2 bytes).
pub fn zig_zag_16(num: Int) -> ByteArray {
  zig_zag(num, 2)
}

/// Attempts to encode the given integer in 32 bits (4 bytes).
pub fn zig_zag_32(num: Int) -> ByteArray {
  zig_zag(num, 4)
}

/// Attempts to encode the given integer in 64 bits (8 bytes).
pub fn zig_zag_64(num: Int) -> ByteArray {
  zig_zag(num, 8)
}
