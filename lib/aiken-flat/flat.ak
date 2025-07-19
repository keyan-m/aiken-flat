use aiken_flat/decoder as de
use aiken_flat/encoder as en

// ## Encoders

pub fn encode_bool(self: Bool) -> ByteArray {
  en.new |> en.bool(self) |> en.filler |> en.unwrap
}

pub fn unsafe_encode_u8(self: ByteArray) -> ByteArray {
  en.new |> en.unsafe_u8(self) |> en.filler |> en.unwrap
}

pub fn encode_integer(self: Int) -> ByteArray {
  en.new |> en.integer(self) |> en.filler |> en.unwrap
}

pub fn encode_word(self: Int) -> ByteArray {
  en.new |> en.word(self) |> en.filler |> en.unwrap
}

pub fn encode_bytes(self: ByteArray) -> ByteArray {
  en.new |> en.bytes(self) |> en.filler |> en.unwrap
}

// ## Decoders

pub fn decode_bool(bytes: ByteArray) -> Bool {
  de.new(bytes) |> de.bool |> de.unwrap
}

pub fn decode_u8(bytes: ByteArray) -> ByteArray {
  de.new(bytes) |> de.u8 |> de.unwrap
}

pub fn decode_integer(bytes: ByteArray) -> Int {
  de.new(bytes) |> de.integer |> de.unwrap
}

pub fn decode_bytes(bytes: ByteArray) -> ByteArray {
  de.new(bytes) |> de.bytes |> de.unwrap
}
