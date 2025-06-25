use aiken_flat/bits.{
  One, Zero, and_with_padding, and_with_truncation, or_with_padding,
  or_with_truncation, pad_to_byte, pretty_print,
}

test success__and_with_padding() {
  let bits1 = [One, Zero, One, One, One, Zero, One, One]
  let bits2 = [Zero, One, Zero, One, Zero, One]
  let expected = [Zero, Zero, Zero, One, Zero, Zero, Zero, One]

  let result = and_with_padding(bits1, bits2)
  result == expected
}

test success__and_with_truncation() {
  let bits1 = [One, Zero, One, One, One, Zero, One, One]
  let bits2 = [Zero, One, Zero, One, Zero, One]
  let expected = [Zero, One, Zero, Zero, Zero, One]

  let result = and_with_truncation(bits1, bits2)
  result == expected
}

test success__or_with_padding() {
  let bits1 = [One, Zero, One, Zero, One, Zero, One, Zero]
  let bits2 = [Zero, One, Zero, One, Zero, One]
  let expected = [One, Zero, One, One, One, One, One, One]

  let result = or_with_padding(bits1, bits2)
  result == expected
}

test success__or_with_truncation() {
  let bits1 = [One, Zero, One, Zero, One, Zero, One, Zero]
  let bits2 = [Zero, One, Zero, One, Zero, One]
  let expected = [One, One, One, One, One, One]

  let result = or_with_truncation(bits1, bits2)
  result == expected
}

test success__pad_to_byte() {
  let bits = [One, Zero, One, One, Zero, One, Zero, One, Zero, One, Zero]
  let expected =
    [
      Zero, Zero, Zero, Zero, Zero, One, Zero, One, One, Zero, One, Zero, One,
      Zero, One, Zero,
    ]

  let result = pad_to_byte(bits)
  result == expected
}

test success__pretty_print() {
  let bits =
    [
      Zero, Zero, Zero, Zero, Zero, One, Zero, One, One, Zero, One, Zero, One,
      Zero, One, Zero,
    ]

  let result = pretty_print(bits)
  result == @"0000010110101010"
}
