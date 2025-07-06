use aiken/collection/list
use aiken/primitive/bytearray

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
