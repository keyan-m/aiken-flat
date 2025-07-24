use aiken_flat/decoder as de
use aiken_flat/encoder as en

/// Encodes a given `Bool` in Flat (with post-alignment).
pub const encode_bool = make_encoder(en.bool)

/// Encodes a given `Byte` in Flat (no validations on the input to ensure it's a
/// single byte).
pub const unsafe_encode_u8 = make_encoder(en.unsafe_u8)

/// After applying `zig-zag` to a given `Int`, encodes it using `encoder.word`
/// (with post-alignment).
pub const encode_integer = make_encoder(en.integer)

/// Breaks up a given `ByteArray` into chunks of 255 bytes, prefixes each chunk
/// with its length, and ends the encoding with a `#"00"`.
pub const encode_bytes = make_encoder(en.bytes)

/// Decoder counterpart for [`encode_bool`](#encode_bool).
pub const decode_bool = make_decoder(de.bool)

/// Decoder counterpart for [`unsafe_encode_u8`](#unsafe_encode_u8).
pub const decode_u8 = make_decoder(de.u8)

/// Decoder counterpart for [`encode_integer`](#encode_integer).
pub const decode_integer = make_decoder(de.integer)

/// Decoder counterpart for [`encode_bytes`](#encode_bytes).
pub const decode_bytes = make_decoder(de.bytes)

/// Encoder Maker
pub fn make_encoder(en: en.EncoderFn<a>) -> fn(a) -> ByteArray {
  fn(self: a) -> ByteArray { en.new |> en(self) |> en.filler |> en.unwrap }
}

/// Decoder Maker
pub fn make_decoder(de: de.DecoderFn<a>) -> fn(ByteArray) -> a {
  fn(bytes: ByteArray) -> a { de.new(bytes) |> de |> de.unwrap }
}
