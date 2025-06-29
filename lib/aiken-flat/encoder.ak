use aiken/builtin
use aiken/primitive/bytearray
use aiken_flat/bits.{Bits}

pub opaque type Encoder {
  buffer: ByteArray,
  used_bits: Int,
  current_byte: ByteArray,
}

pub fn bool(encoder: Encoder, b: Bool) -> Encoder {
  if b {
    one(encoder)
  } else {
    zero(encoder)
  }
}

/// Assumes given ByteArray is a single byte.
fn unsafe_u8(encoder: Encoder, u8: ByteArray) -> Encoder {
  if encoder.used_bits == 0 {
    next_word(Encoder { ..encoder, current_byte: u8 })
  } else {
    byte_unaligned(encoder, u8)
  }
}

fn bits(encoder: Encoder, bits: Bits)

fn filler(encoder: Encoder) -> Encoder {
  Encoder {
    ..encoder,
    current_byte: encoder.current_byte |> builtin.or_bytearray(False, _, #"01")
  } |> next_word
}

fn zero(encoder: Encoder) -> Encoder {
  let Encoder { used_bits, .. } = encoder
  if used_bits == 7 {
    next_word(encoder)
  } else {
    Encoder { ..encoder, used_bits: used_bits + 1 }
  }
}

fn one(encoder: Encoder) -> Encoder {
  let Encoder { buffer, current_byte, used_bits } = encoder
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

fn next_word(encoder: Encoder) -> Encoder {
  let Encoder { buffer, current_byte, .. } = encoder
  Encoder {
    buffer: bytearray.concat(buffer, current_byte),
    used_bits: 0,
    current_byte: #"00",
  }
}

fn byte_unaligned(encoder: Encoder, byte: ByteArray) -> Encoder {
  let Encoder { buffer, current_byte, used_bits } = encoder
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
