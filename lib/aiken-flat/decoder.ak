use aiken/builtin
use aiken/primitive/bytearray

pub opaque type Decoder {
  buffer: ByteArray,
  used_bits: Int,
  pos: Int,
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

  expect self |> ensure_bytes(1)

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
