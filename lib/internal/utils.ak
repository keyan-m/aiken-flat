use aiken/collection/list
use aiken/primitive/bytearray

pub const i8_min_bound: Int = -128

pub const i8_max_bound: Int = 127

pub const i16_min_bound: Int = -32768

pub const i16_max_bound: Int = 32767

pub const i32_min_bound: Int = -2147483648

pub const i32_max_bound: Int = 2147483647

pub const i64_min_bound: Int = -9223372036854775808

pub const i64_max_bound: Int = 9223372036854775807

pub const i128_min_bound: Int = -170141183460469231731687303715884105728

pub const i128_max_bound: Int = 170141183460469231731687303715884105727

pub const u128_max_bound: Int = 340282366920938463463374607431768211455

pub fn zip_foldr(
  self: List<a>,
  bs: List<b>,
  acc: c,
  with: fn(a, b, c) -> c,
) -> c {
  when self is {
    [] -> acc
    [x, ..xs] ->
      when bs is {
        [] -> acc
        [y, ..ys] -> {
          let c = zip_foldr(xs, ys, acc, with)
          with(x, y, c)
        }
      }
  }
}

pub fn zip_foldl(
  self: List<a>,
  bs: List<b>,
  acc: c,
  with: fn(a, b, c) -> c,
) -> c {
  when self is {
    [] -> acc
    [x, ..xs] ->
      when bs is {
        [] -> acc
        [y, ..ys] -> {
          let c = with(x, y, acc)
          zip_foldl(xs, ys, c, with)
        }
      }
  }
}

fn do_chunks(
  bytes: ByteArray,
  chunk_length: Int,
  acc: List<ByteArray>,
) -> List<ByteArray> {
  if bytes == #"" {
    acc
  } else {
    let left = bytes |> bytearray.take(chunk_length)
    do_chunks(
      bytes |> bytearray.drop(chunk_length),
      chunk_length,
      list.concat(acc, [left]),
    )
  }
}

pub fn bytearray_chunks(bytes: ByteArray, chunk_length: Int) -> List<ByteArray> {
  if bytes == #"" {
    []
  } else {
    do_chunks(bytes, chunk_length, [])
  }
}
