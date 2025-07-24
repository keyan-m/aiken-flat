//// @hidden

use aiken/builtin
use aiken/primitive/bytearray

/// Left shift with byte count extension as much as needed.
pub fn shift_left(arr: ByteArray, shift: Int) -> ByteArray {
  let available_bits = leading_zeroes(arr)
  if available_bits >= shift {
    arr |> builtin.shift_bytearray(shift)
  } else {
    let extra_bytes = ( shift - available_bits ) / 8 + 1
    let padded = repeat(#"00", extra_bytes) |> bytearray.concat(arr)
    padded |> builtin.shift_bytearray(shift)
  }
}

pub fn repeat(bytes: ByteArray, n_times: Int) -> ByteArray {
  do_repeat(bytes, n_times, #"")
}

fn do_repeat(bytes: ByteArray, n_times: Int, so_far: ByteArray) {
  if n_times <= 0 {
    so_far
  } else {
    do_repeat(bytes, n_times - 1, so_far |> bytearray.concat(bytes))
  }
}

/// Returns the number of leading zero _bits_ in a given `ByteArray`.
pub fn leading_zeroes(arr: ByteArray) -> Int {
  do_leading_zeros(arr, 0)
}

fn do_leading_zeros(arr: ByteArray, count_so_far: Int) -> Int {
  let leading_byte = arr |> bytearray.take(1)
  if bytearray.is_empty(arr) {
    count_so_far
  } else if bytearray.compare(leading_byte, #"7f") == Greater {
    // `arr` is "1xxx xxxx"
    count_so_far
  } else if bytearray.compare(leading_byte, #"3f") == Greater {
    // `arr` is "01xx xxxx"
    count_so_far + 1
  } else if bytearray.compare(leading_byte, #"1f") == Greater {
    // `arr` is "001x xxxx"
    count_so_far + 2
  } else if bytearray.compare(leading_byte, #"0f") == Greater {
    // `arr` is "0001 xxxx"
    count_so_far + 3
  } else if bytearray.compare(leading_byte, #"07") == Greater {
    // `arr` is "0000 1xxx"
    count_so_far + 4
  } else if bytearray.compare(leading_byte, #"03") == Greater {
    // `arr` is "0000 01xx"
    count_so_far + 5
  } else if bytearray.compare(leading_byte, #"01") == Greater {
    // `arr` is "0000 001x"
    count_so_far + 6
  } else if bytearray.compare(leading_byte, #"00") == Greater {
    // `arr` is "0000 0001"
    count_so_far + 7
  } else {
    do_leading_zeros(arr |> bytearray.drop(1), count_so_far + 8)
  }
}

/// Left zero-pads the shorter `ByteArray` to match the longer one.
pub fn match_lengths(
  left: ByteArray,
  right: ByteArray,
) -> (ByteArray, ByteArray) {
  let left_length = bytearray.length(left)
  let right_length = bytearray.length(right)
  if left_length < right_length {
    let padding_length = right_length - left_length
    (left |> left_zero_pad_by(padding_length), right)
  } else {
    let padding_length = left_length - right_length
    (left, right |> left_zero_pad_by(padding_length))
  }
}

/// Pads the given `ByteArray` on the left with `padding_length` number of
/// `#"00"`s.
pub fn left_zero_pad_by(self: ByteArray, padding_length: Int) -> ByteArray {
  bytearray.concat(repeat(#"00", padding_length), self)
}

/// Drops all `#"00"` most significant bytes. Assumes big endian.
pub fn drop_left_zero_pads(self: ByteArray) -> ByteArray {
  self
    |> builtin.bytearray_to_integer(True, _)
    |> builtin.integer_to_bytearray(True, 0, _)
}
