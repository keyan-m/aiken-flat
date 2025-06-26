use aiken/builtin
use aiken/primitive/bytearray
use aiken_flat/primitive/integer.{Integer}

/// Reimplementation from [Haskell's `flat`](https://hackage.haskell.org/package/flat-0.6/docs/src/Flat.Encoder.Prim.html#w7l).
pub fn w7l(t: Integer) -> ByteArray {
  let l = low7(t)
  let t_p = t |> integer.shift_right(7)
  if integer.is_zero(t_p) {
    l
  } else {
    bytearray.concat(w7l_helper_w7(l), w7l(t_p))
  }
}

fn w7l_helper_w7(w8: ByteArray) -> ByteArray {
  builtin.or_bytearray(False, w8, #"80")
}

/// Returns the low 7 bits of an integer with unknown byte count.
pub fn low7(x: Integer) -> ByteArray {
  integer.to_word8(x)
    |> bytearray.from_int_big_endian(1)
    |> builtin.and_bytearray(False, #"7f", _)
}
