use aiken_flat/primitive/integer

test success__roundtrip_from_integer(x via integer.fuzzer()) {
  let int = integer.to_int(x)
  let roundtrip = integer.from_int(int)
  integer.equals(x, roundtrip)
}
