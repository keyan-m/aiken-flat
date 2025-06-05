use aiken/builtin
use aiken/primitive/bytearray

/// map zag_zig [0..6::Word8]
/// [0,-1,1,-2,2,-3,3]
pub fn zag_zig(bytes: ByteArray) -> Int {
  let one = bytearray.from_int_big_endian(1, bytearray.length(bytes))
  let lsb = builtin.and_bytearray(padded: False, left: bytes, right: one)
  todo
}
