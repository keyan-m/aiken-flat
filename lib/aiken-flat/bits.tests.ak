use aiken/fuzz
use aiken/math.{max}
use aiken_flat/bits.{
  Bits, and_with_padding, and_with_truncation, or_with_padding,
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

test success__to_bytearray() {
  let bits = [True, True, True, True, True, True, True, True, True, True]
  let expected = #"03ff"
  let result = to_bytearray(bits)
  result == expected
}

fn bits_fuzzer(size: Int) -> Fuzzer<Bits> {
  fuzz.list_at_most(fuzz.bool(), max(1, size))
}
