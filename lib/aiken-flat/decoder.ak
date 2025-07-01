use aiken/builtin
use aiken/collection/list
use aiken/primitive/bytearray
use aiken_flat/primitive/integer.{Integer}
use aiken_flat/zig_zag.{zag_zig}

pub opaque type Decoder {
  buffer: ByteArray,
  used_bits: Int,
  pos: Int,
}

pub fn integer(self: Decoder) -> (Int, Decoder) {
  let (w, new_decoder) = self |> word
  (zag_zig(w), new_decoder)
}

pub fn bool(self: Decoder) -> (Bool, Decoder) {
  self |> bit
}

pub fn u8(self: Decoder) -> (ByteArray, Decoder) {
  self |> bits8(8)
}

pub fn bytes(self: Decoder) -> (ByteArray, Decoder) {
  self |> filler |> byte_array
}

pub fn filler(self: Decoder) -> Decoder {
  let (current_bit_is_zero, new_decoder) = self |> zero
  if current_bit_is_zero {
    filler(new_decoder)
  } else {
    new_decoder
  }
}

pub fn word(self: Decoder) -> (Int, Decoder) {
  let leading_bit = #"01"
  let final_word = #"00"
  let shl = integer.zero
  do_word(self, leading_bit, final_word, shl)
}

fn do_word(
  self: Decoder,
  leading_bit: ByteArray,
  final_word: ByteArray,
  shl: Integer,
) -> (Int, Decoder) {
  if leading_bit == #"01" {
    let (word8, new_decoder) = self |> bits8(8)
    let word7 = builtin.and_bytearray(False, word8, #"7f")
    let new_final_word =
      builtin.or_bytearray(
        False,
        final_word,
        builtin.shift_bytearray(word7, shl |> integer.to_int),
      )
    let new_shl = shl |> integer.add_int(7)
    let new_leading_bit = builtin.and_bytearray(False, word8, #"80")
    do_word(new_decoder, new_leading_bit, new_final_word, new_shl)
  } else {
    (builtin.bytearray_to_integer(True, final_word), self)
  }
}

pub fn decode_list_with(
  self: Decoder,
  decoder_func: fn(Decoder) -> (a, Decoder),
) -> List<a> {
  do_decode_list_with(self, decoder_func, [])
}

fn do_decode_list_with(
  self: Decoder,
  decoder_func: fn(Decoder) -> (a, Decoder),
  acc: List<a>,
) -> List<a> {
  let (current_bit, _) = self |> bit()
  if current_bit {
    let (decoded, new_decoder) = self |> decoder_func
    do_decode_list_with(new_decoder, decoder_func, list.concat(acc, [decoded]))
  } else {
    acc
  }
}

fn zero(self: Decoder) -> (Bool, Decoder) {
  let (current_bit, new_decoder) = self |> bit()
  (!current_bit, new_decoder)
}

fn bit(self: Decoder) -> (Bool, Decoder) {
  let Decoder { buffer, used_bits, pos } = self
  let b =
    (
      builtin.and_bytearray(
        False,
        buffer |> get_byte_at(pos),
        builtin.shift_bytearray(#"80", -used_bits),
      )
        |> bytearray.compare(#"00")
    ) == Greater

  (b, self |> increment_buffer_by_bit)
}

fn do_byte_array(
  self: Decoder,
  decoded_array_so_far: ByteArray,
) -> (ByteArray, Decoder) {
  let Decoder { buffer, used_bits, pos } = self

  expect used_bits != 0

  // `bytearray.at` fails if `pos` is out of bounds, so no need for
  // `ensure_bytes` here.
  let chunk_len = buffer |> bytearray.at(pos)

  let new_pos = pos + 1

  if chunk_len != 0 {
    expect self |> ensure_bytes(chunk_len + 1)

    let decoded_chunk = buffer |> bytearray.slice(pos, pos + chunk_len)

    let updated_decoded_array =
      bytearray.concat(decoded_array_so_far, decoded_chunk)

    do_byte_array(
      Decoder { ..self, pos: new_pos + chunk_len },
      updated_decoded_array,
    )
  } else {
    (decoded_array_so_far, Decoder { ..self, pos: new_pos })
  }
}

fn byte_array(self: Decoder) -> (ByteArray, Decoder) {
  do_byte_array(self, #"")
}

/// Second output is a single byte.
pub fn bits8(self: Decoder, n: Int) -> (ByteArray, Decoder) {
  expect n <= 8

  expect ensure_bits(self, n)

  let Decoder { buffer, used_bits, pos } = self
  let unused_bits = 8 - used_bits
  let leading_zeroes = 8 - n
  let current_byte = buffer |> get_byte_at(pos)
  let r =
    current_byte
      |> builtin.shift_bytearray(used_bits)
      |> builtin.shift_bytearray(-leading_zeroes)

  let x =
    if n > unused_bits {
      let next_byte = buffer |> get_byte_at(pos + 1)
      let next_byte_shifted =
        next_byte |> builtin.shift_bytearray(-unused_bits - leading_zeroes)
      builtin.or_bytearray(False, r, next_byte_shifted)
    } else {
      r
    }

  (x, self |> drop_bits(n))
}

fn ensure_bytes(self: Decoder, required_bytes: Int) -> Bool {
  let Decoder { buffer, pos, .. } = self
  if required_bytes > bytearray.length(buffer) - pos {
    fail @"Not enough bytes"
  } else {
    True
  }
}

fn ensure_bits(self: Decoder, required_bits: Int) -> Bool {
  let Decoder { buffer, used_bits, pos } = self
  if required_bits > ( bytearray.length(buffer) - pos ) * 8 - used_bits {
    fail @"Not enought bits"
  } else {
    True
  }
}

fn drop_bits(self: Decoder, n: Int) -> Decoder {
  let Decoder { used_bits, pos, .. } = self
  let all_used_bits = n + used_bits
  Decoder { ..self, used_bits: all_used_bits % 8, pos: pos + all_used_bits / 8 }
}

fn increment_buffer_by_bit(self: Decoder) -> Decoder {
  let Decoder { used_bits, pos, .. } = self
  if used_bits == 7 {
    Decoder { ..self, pos: pos + 1, used_bits: 0 }
  } else {
    Decoder { ..self, used_bits: used_bits + 1 }
  }
}

fn get_byte_at(self: ByteArray, i: Int) -> ByteArray {
  self |> bytearray.at(i) |> builtin.integer_to_bytearray(True, 1, _)
}
