use aiken/fuzz
use aiken/math.{max}
use aiken_flat/bits.{
  Bits, and_with_padding, and_with_truncation, from_bytearray, or_with_padding,
  or_with_truncation, pad_to_byte, pretty_print, tag_to_bits, to_bytearray,
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

test success__roundtrip_from_bits(bits via bits_fuzzer(32)) {
  validate_roundtrip_from_bits(bits)
}

test success__roundtrip_from_bytes(bytes via fuzz.bytearray_between(0, 32)) {
  validate_roundtrip_from_bytes(bytes)
}

bench bench__roundtrip_from_bits(bits via bits_fuzzer) {
  validate_roundtrip_from_bits(bits)
}

bench bench__roundtrip_from_bytes(bytes via fuzz.bytearray_between(0, _)) {
  validate_roundtrip_from_bytes(bytes)
}

test success_tag_to_bits_C20() {
  let result = tag_to_bits(2, 0)
  result == [False]
}

test success_tag_to_bits_C21() {
  let result = tag_to_bits(2, 1)
  result == [True]
}

test success_tag_to_bits_C30() {
  let result = tag_to_bits(3, 0)
  result == [False]
}

test success_tag_to_bits_C31() {
  let result = tag_to_bits(3, 1)
  result == [True, False]
}

test success_tag_to_bits_C32() {
  let result = tag_to_bits(3, 2)
  result == [True, True]
}

test success_tag_to_bits_C40() {
  let result = tag_to_bits(4, 0)
  result == [False, False]
}

test success_tag_to_bits_C41() {
  let result = tag_to_bits(4, 1)
  result == [False, True]
}

test success_tag_to_bits_C42() {
  let result = tag_to_bits(4, 2)
  result == [True, False]
}

test success_tag_to_bits_C43() {
  let result = tag_to_bits(4, 3)
  result == [True, True]
}

test success_tag_to_bits_C50() {
  let result = tag_to_bits(5, 0)
  result == [False, False]
}

test success_tag_to_bits_C51() {
  let result = tag_to_bits(5, 1)
  result == [False, True]
}

test success_tag_to_bits_C52() {
  let result = tag_to_bits(5, 2)
  result == [True, False]
}

test success_tag_to_bits_C53() {
  let result = tag_to_bits(5, 3)
  result == [True, True, False]
}

test success_tag_to_bits_C54() {
  let result = tag_to_bits(5, 4)
  result == [True, True, True]
}

test success_tag_to_bits_C60() {
  let result = tag_to_bits(6, 0)
  result == [False, False]
}

test success_tag_to_bits_C61() {
  let result = tag_to_bits(6, 1)
  result == [False, True, False]
}

test success_tag_to_bits_C62() {
  let result = tag_to_bits(6, 2)
  result == [False, True, True]
}

test success_tag_to_bits_C63() {
  let result = tag_to_bits(6, 3)
  result == [True, False]
}

test success_tag_to_bits_C64() {
  let result = tag_to_bits(6, 4)
  result == [True, True, False]
}

test success_tag_to_bits_C65() {
  let result = tag_to_bits(6, 5)
  result == [True, True, True]
}

test success_tag_to_bits_C70() {
  let result = tag_to_bits(7, 0)
  result == [False, False]
}

test success_tag_to_bits_C71() {
  let result = tag_to_bits(7, 1)
  result == [False, True, False]
}

test success_tag_to_bits_C72() {
  let result = tag_to_bits(7, 2)
  result == [False, True, True]
}

test success_tag_to_bits_C73() {
  let result = tag_to_bits(7, 3)
  result == [True, False, False]
}

test success_tag_to_bits_C74() {
  let result = tag_to_bits(7, 4)
  result == [True, False, True]
}

test success_tag_to_bits_C75() {
  let result = tag_to_bits(7, 5)
  result == [True, True, False]
}

test success_tag_to_bits_C76() {
  let result = tag_to_bits(7, 6)
  result == [True, True, True]
}

test success_tag_to_bits_C80() {
  let result = tag_to_bits(8, 0)
  result == [False, False, False]
}

test success_tag_to_bits_C81() {
  let result = tag_to_bits(8, 1)
  result == [False, False, True]
}

test success_tag_to_bits_C82() {
  let result = tag_to_bits(8, 2)
  result == [False, True, False]
}

test success_tag_to_bits_C83() {
  let result = tag_to_bits(8, 3)
  result == [False, True, True]
}

test success_tag_to_bits_C84() {
  let result = tag_to_bits(8, 4)
  result == [True, False, False]
}

test success_tag_to_bits_C85() {
  let result = tag_to_bits(8, 5)
  result == [True, False, True]
}

test success_tag_to_bits_C86() {
  let result = tag_to_bits(8, 6)
  result == [True, True, False]
}

test success_tag_to_bits_C87() {
  let result = tag_to_bits(8, 7)
  result == [True, True, True]
}

test success_tag_to_bits_C90() {
  let result = tag_to_bits(9, 0)
  result == [False, False, False]
}

test success_tag_to_bits_C91() {
  let result = tag_to_bits(9, 1)
  result == [False, False, True]
}

test success_tag_to_bits_C92() {
  let result = tag_to_bits(9, 2)
  result == [False, True, False]
}

test success_tag_to_bits_C93() {
  let result = tag_to_bits(9, 3)
  result == [False, True, True]
}

test success_tag_to_bits_C94() {
  let result = tag_to_bits(9, 4)
  result == [True, False, False]
}

test success_tag_to_bits_C95() {
  let result = tag_to_bits(9, 5)
  result == [True, False, True]
}

test success_tag_to_bits_C96() {
  let result = tag_to_bits(9, 6)
  result == [True, True, False]
}

test success_tag_to_bits_C97() {
  let result = tag_to_bits(9, 7)
  result == [True, True, True, False]
}

test success_tag_to_bits_C98() {
  let result = tag_to_bits(9, 8)
  result == [True, True, True, True]
}
