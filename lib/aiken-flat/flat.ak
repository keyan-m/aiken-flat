use aiken_flat/decoder.{Decoder}
use aiken_flat/encoder.{Encoder}

// ## Encoders

pub fn encode_bool(self: Bool, e: Encoder) -> Encoder {
  e |> encoder.bool(self)
}

pub fn unsafe_encode_u8(self: ByteArray, e: Encoder) -> Encoder {
  e |> encoder.unsafe_u8(self)
}

pub fn encode_integer(self: Int, e: Encoder) -> Encoder {
  e |> encoder.integer(self)
}

pub fn encode_word(self: Int, e: Encoder) -> Encoder {
  e |> encoder.word(self)
}

pub fn encode_bytes(self: ByteArray, e: Encoder) -> Encoder {
  e |> encoder.bytes(self)
}

pub fn encode_filler(e: Encoder) -> Encoder {
  e |> encoder.filler
}

// ## Decoders

pub fn decode_bool(d: Decoder) -> (Bool, Decoder) {
  d |> decoder.bool
}

pub fn decode_u8(d: Decoder) -> (ByteArray, Decoder) {
  d |> decoder.u8
}

pub fn decode_integer(d: Decoder) -> (Int, Decoder) {
  d |> decoder.integer
}

pub fn decode_filler(d: Decoder) -> Decoder {
  d |> decoder.filler
}
