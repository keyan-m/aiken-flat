use aiken/builtin
use aiken/primitive/bytearray

pub fn shift_left(arr: ByteArray, shift: Int) -> ByteArray {
  let available_bits = leading_zeroes(arr)
  if available_bits >= shift {
    arr |> builtin.shift_bytearray(shift)
  } else {
    let extra_bytes = ( shift - available_bits ) / 8 + 1
    let padded = repeat(#"00", shift - available_bits) |> bytearray.concat(arr)
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

pub fn leading_zeroes(arr: ByteArray) -> Int {
  do_leading_zeros(arr, 0)
}

fn do_leading_zeros(arr: ByteArray, count_so_far: Int) -> Int {
  let leading_byte = arr |> bytearray.take(1)
  if bytearray.compare(leading_byte, #"7f") == Greater {
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
