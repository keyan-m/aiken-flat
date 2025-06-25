use aiken/fuzz
use aiken/math.{max}
use aiken_flat/bits.{
  Bits, and_with_padding, and_with_truncation, from_bytearray, or_with_padding,
  or_with_truncation, pad_to_byte, pretty_print, to_bytearray,
}

test success__and_with_padding() {
  let bits1 = [True, False, True, True, True, False, True, True]
  let bits2 = [False, True, False, True, False, True]
  let expected = [False, False, False, True, False, False, False, True]

  let result = and_with_padding(bits1, bits2)
  result == expected
}

test success__and_with_truncation() {
  let bits1 = [True, False, True, True, True, False, True, True]
  let bits2 = [False, True, False, True, False, True]
  let expected = [False, True, False, False, False, True]

  let result = and_with_truncation(bits1, bits2)
  result == expected
}

test success__or_with_padding() {
  let bits1 = [True, False, True, False, True, False, True, False]
  let bits2 = [False, True, False, True, False, True]
  let expected = [True, False, True, True, True, True, True, True]

  let result = or_with_padding(bits1, bits2)
  result == expected
}

test success__or_with_truncation() {
  let bits1 = [True, False, True, False, True, False, True, False]
  let bits2 = [False, True, False, True, False, True]
  let expected = [True, True, True, True, True, True]

  let result = or_with_truncation(bits1, bits2)
  result == expected
}

test success__pad_to_byte() {
  let bits =
    [True, False, True, True, False, True, False, True, False, True, False]
  let expected =
    [
      False, False, False, False, False, True, False, True, True, False, True,
      False, True, False, True, False,
    ]

  let result = pad_to_byte(bits)
  result == expected
}

test success__pad_to_byte__edge() {
  let bits = [True, False, True, False, True, False, True, False]

  let result = pad_to_byte(bits)
  result == bits
}

test success__pretty_print() {
  let bits =
    [
      False, False, False, False, False, True, False, True, True, False, True,
      False, True, False, True, False,
    ]

  let result = pretty_print(bits)
  result == @"0000010110101010"
}

fn bits_fuzzer(size: Int) -> Fuzzer<Bits> {
  fuzz.list_at_most(fuzz.bool(), max(1, size))
}

fn validate_roundtrip_from_bits(bits: Bits) -> Bool {
  let bytes = to_bytearray(bits)
  let reencoded = from_bytearray(bytes)
  pad_to_byte(bits) == reencoded
}

fn validate_roundtrip_from_bytes(bytes: ByteArray) -> Bool {
  let bits = from_bytearray(bytes)
  let reencoded = to_bytearray(bits)
  bytes == reencoded
}

test success__roundtrip_from_bits(bits via bits_fuzzer(100)) {
  validate_roundtrip_from_bits(bits)
}

test success__roundtrip_from_bytes(bytes via fuzz.bytearray_between(0, 100)) {
  validate_roundtrip_from_bytes(bytes)
}

bench bench__roundtrip_from_bits(bits via bits_fuzzer) {
  validate_roundtrip_from_bits(bits)
}

bench bench__roundtrip_from_bytes(bytes via fuzz.bytearray_between(0, _)) {
  validate_roundtrip_from_bytes(bytes)
}
