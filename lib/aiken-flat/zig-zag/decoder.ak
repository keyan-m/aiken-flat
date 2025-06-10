use aiken/primitive/bytearray

pub fn zag_zig(bytes: ByteArray) -> Int {
  let int = bytearray.to_int_big_endian(bytes)
  if int % 2 == 0 {
    int / 2
  } else {
    ( int + 1 ) / -2
  }
}
