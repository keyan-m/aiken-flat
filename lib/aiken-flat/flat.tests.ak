use aiken/fuzz
use aiken_flat/flat

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

test success__integer_roundtrip(integer via fuzz.int_between(0, 127)) {
  let encoded = flat.encode_integer(integer)
  let decoded = flat.decode_integer(encoded)
  trace encoded
  trace decoded
  decoded == integer
}
