use aiken/builtin
use aiken/fuzz
use aiken_flat/flat
use internal/extra/bytearray as ba_extra

test success__bool_roundtrip(b via fuzz.bool()) {
  let encoded = flat.encode_bool(b)
  let decoded = flat.decode_bool(encoded)
  trace encoded
  trace decoded
  decoded == b
}

test success__u8_roundtrip(byte via fuzz.bytearray_fixed(1)) {
  let encoded = flat.unsafe_encode_u8(byte)
  let decoded = flat.decode_u8(encoded)
  trace encoded
  trace decoded
  decoded == byte
}

test success__bytes_roundtrip(bytes via fuzz.bytearray_fixed(2550)) {
  let encoded = flat.encode_bytes(bytes)
  let decoded = flat.decode_bytes(encoded)
  trace encoded
  trace decoded
  decoded == bytes
}

test success__integer_roundtrip() {
  let integer = 128
  let encoded = flat.encode_integer(integer)
  let decoded = flat.decode_integer(encoded)
  trace encoded
  trace decoded
  decoded == integer
}

test success__and() {
  let (left, right) = ba_extra.left_zero_pad_to_match(#"0100", #"7f")
  builtin.and_bytearray(True, left, right) == #"0000"
}
