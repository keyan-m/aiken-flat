use aiken/builtin
use aiken/collection/list
use aiken/primitive/bytearray
use aiken_flat/bits.{Bits}
use aiken_flat/primitive/integer
use aiken_flat/zig_zag.{zig_zag}
use internal/utils.{bytearray_chunks}

pub opaque type Encoder {
  buffer: ByteArray,
  used_bits: Int,
  current_byte: ByteArray,
}

pub const new: Encoder =
  Encoder { buffer: #"", used_bits: 0, current_byte: #"00" }

pub fn unwrap(self: Encoder) -> ByteArray {
  self.buffer
}

/// Assumes given ByteArray is a single byte.
pub fn unsafe_u8(self: Encoder, u8: ByteArray) -> Encoder {
  if self.used_bits == 0 {
    next_word(Encoder { ..self, current_byte: u8 })
  } else {
    byte_unaligned(self, u8)
  }
}

pub fn bool(self: Encoder, b: Bool) -> Encoder {
  if b {
    one(self)
  } else {
    zero(self)
  }
}

pub fn bytes(self: Encoder, arr: ByteArray) -> Encoder {
  self |> filler |> byte_array(arr)
}

pub fn byte_array(self: Encoder, arr: ByteArray) -> Encoder {
  expect self.used_bits == 0
  self |> unsafe_write_blk(arr)
}

pub fn integer(self: Encoder, x: Int) -> Encoder {
  self |> word(zig_zag(x))
}

fn do_word(self: Encoder, d: ByteArray) -> Encoder {
  let w = builtin.and_bytearray(False, d, #"7f")
  let d = d |> builtin.shift_bytearray(-7)
  if d != #"00" {
    let w = builtin.or_bytearray(False, w, #"80")
    let new_encoder = self |> bits(bits.from_bytearray(w))
    do_word(new_encoder, d)
  } else {
    let new_encoder = self |> bits(bits.from_bytearray(w))
    do_word(new_encoder, d)
  }
}

pub fn word(self: Encoder, x: Int) -> Encoder {
  self |> do_word(x |> integer.from_int |> integer.to_bytearray)
}

pub fn encode_list_with(
  self: Encoder,
  list: List<a>,
  with: fn(Encoder, a) -> Encoder,
) -> Encoder {
  when list is {
    [] -> zero(self)
    _ ->
      list
        |> list.foldl(self, fn(item, acc) { with(one(acc), item) })
        |> zero
  }
}

fn bits(self: Encoder, bits: Bits) -> Encoder {
  bits
    |> list.foldl(
        self,
        fn(bit, acc) {
          if bit {
            one(acc)
          } else {
            zero(acc)
          }
        },
      )
}

pub fn filler(self: Encoder) -> Encoder {
  Encoder {
    ..self,
    current_byte: self.current_byte |> builtin.or_bytearray(False, _, #"01"),
  }
    |> next_word
}

fn zero(self: Encoder) -> Encoder {
  let Encoder { used_bits, .. } = self
  if used_bits == 7 {
    next_word(self)
  } else {
    Encoder { ..self, used_bits: used_bits + 1 }
  }
}

fn one(self: Encoder) -> Encoder {
  let Encoder { buffer, current_byte, used_bits } = self
  if used_bits == 7 {
    let new_byte = current_byte |> builtin.or_bytearray(False, _, #"01")
    Encoder {
      buffer: bytearray.concat(buffer, new_byte),
      used_bits: 0,
      current_byte: #"00",
    }
  } else {
    Encoder {
      buffer,
      used_bits: used_bits + 1,
      current_byte: builtin.or_bytearray(
        False,
        current_byte,
        #"80" |> builtin.shift_bytearray(-used_bits),
      ),
    }
  }
}

fn next_word(self: Encoder) -> Encoder {
  let Encoder { buffer, current_byte, .. } = self
  Encoder {
    buffer: bytearray.concat(buffer, current_byte),
    used_bits: 0,
    current_byte: #"00",
  }
}

fn byte_unaligned(self: Encoder, byte: ByteArray) -> Encoder {
  let Encoder { buffer, current_byte, used_bits } = self
  // Fill the remaining bits of the current byte with first bits of the given
  // byte.
  let shifted_byte =
    byte
      |> builtin.shift_bytearray(-used_bits)
      |> builtin.or_bytearray(False, _, current_byte)
  // Preserve the remaining bits of the given byte in `current_byte`.
  let new_current_byte = byte |> builtin.shift_bytearray(8 - used_bits)
  Encoder {
    buffer: bytearray.concat(buffer, shifted_byte),
    used_bits,
    current_byte: new_current_byte,
  }
}

/// Assumes byte alignment.
fn unsafe_write_blk(self: Encoder, arr: ByteArray) -> Encoder {
  let buffer_before_0 =
    arr
      |> bytearray_chunks(255)
      |> list.foldl(
          self.buffer,
          fn(chunk, acc) {
            let chunk_length_byte =
              builtin.integer_to_bytearray(True, 1, bytearray.length(chunk))
            acc
              |> bytearray.concat(chunk_length_byte)
              |> bytearray.concat(chunk)
          },
        )
  Encoder { ..self, buffer: bytearray.concat(buffer_before_0, #"00") }
}
