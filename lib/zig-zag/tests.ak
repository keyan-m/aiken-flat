use aiken/collection/list
use aiken/fuzz
use aiken/math.{max}
use zig_zag/decoder.{zag_zig}
use zig_zag/encoder.{zig_zag_16, zig_zag_32, zig_zag_64, zig_zag_8}

fn bytes_fuzzer_8(size: Int) -> Fuzzer<List<ByteArray>> {
  fuzz.bytearray_fixed(1) |> fuzz.list_at_most(max(1, size))
}

fn bytes_fuzzer_16(size: Int) -> Fuzzer<List<ByteArray>> {
  fuzz.bytearray_fixed(2) |> fuzz.list_at_most(max(1, size))
}

fn bytes_fuzzer_32(size: Int) -> Fuzzer<List<ByteArray>> {
  fuzz.bytearray_fixed(4) |> fuzz.list_at_most(max(1, size))
}

fn bytes_fuzzer_64(size: Int) -> Fuzzer<List<ByteArray>> {
  fuzz.bytearray_fixed(8) |> fuzz.list_at_most(max(1, size))
}

fn ints_fuzzer_8(size: Int) -> Fuzzer<List<Int>> {
  fuzz.int_between(-128, 127) |> fuzz.list_at_most(max(1, size))
}

fn ints_fuzzer_16(size: Int) -> Fuzzer<List<Int>> {
  fuzz.list_at_most(
    fuzz.either(fuzz.int_between(-32768, -129), fuzz.int_between(128, 32767)),
    max(1, size),
  )
}

fn ints_fuzzer_32(size: Int) -> Fuzzer<List<Int>> {
  fuzz.list_at_most(
    fuzz.either(
      fuzz.int_between(-2147483648, -32769),
      fuzz.int_between(32768, 2147483647),
    ),
    max(1, size),
  )
}

fn ints_fuzzer_64(size: Int) -> Fuzzer<List<Int>> {
  fuzz.list_at_most(
    fuzz.either(
      fuzz.int_between(-9223372036854775808, -2147483649),
      fuzz.int_between(2147483648, 9223372036854775807),
    ),
    max(1, size),
  )
}

fn bytes_fuzzer(size: Int) -> Fuzzer<(Int, List<ByteArray>)> {
  let (_, bit_count) <- fuzz.and_then(fuzz.pick([8, 16, 32, 64]))
  let fuzzer =
    if bit_count == 8 {
      bytes_fuzzer_8(size)
    } else if bit_count == 16 {
      bytes_fuzzer_16(size)
    } else if bit_count == 32 {
      bytes_fuzzer_32(size)
    } else {
      bytes_fuzzer_64(size)
    }
  let bytes <- fuzz.and_then(fuzzer)
  fuzz.constant((bit_count, bytes))
}

fn ints_fuzzer(size: Int) -> Fuzzer<(Int, List<Int>)> {
  let (_, bit_count) <- fuzz.and_then(fuzz.pick([8, 16, 32, 64]))
  let fuzzer =
    if bit_count == 8 {
      ints_fuzzer_8(size)
    } else if bit_count == 16 {
      ints_fuzzer_16(size)
    } else if bit_count == 32 {
      ints_fuzzer_32(size)
    } else {
      ints_fuzzer_64(size)
    }
  let ints <- fuzz.and_then(fuzzer)
  fuzz.constant((bit_count, ints))
}

fn validate_roundtrip_from_bytes(bit_count: Int, bytes: List<ByteArray>) -> Bool {
  let decoded: List<Int> = bytes |> list.map(zag_zig)
  let reencoded: List<ByteArray> =
    if bit_count == 8 {
      decoded |> list.map(zig_zag_8)
    } else if bit_count == 16 {
      decoded |> list.map(zig_zag_16)
    } else if bit_count == 32 {
      decoded |> list.map(zig_zag_32)
    } else if bit_count == 64 {
      decoded |> list.map(zig_zag_64)
    } else {
      []
    }
  bytes == reencoded
}

fn validate_roundtrip_from_ints(bit_count: Int, ints: List<Int>) -> Bool {
  let encoded: List<ByteArray> =
    if bit_count == 8 {
      ints |> list.map(zig_zag_8)
    } else if bit_count == 16 {
      ints |> list.map(zig_zag_16)
    } else if bit_count == 32 {
      ints |> list.map(zig_zag_32)
    } else if bit_count == 64 {
      ints |> list.map(zig_zag_64)
    } else {
      []
    }
  let decoded: List<Int> = encoded |> list.map(zag_zig)
  ints == decoded
}

test success__roundtrip_from_bytes((bit_count, bytes) via bytes_fuzzer(100)) {
  validate_roundtrip_from_bytes(bit_count, bytes)
}

test success__roundtrip_from_ints((bit_count, ints) via ints_fuzzer(100)) {
  validate_roundtrip_from_ints(bit_count, ints)
}

bench bench__roundtrip_from_bytes((bit_count, bytes) via bytes_fuzzer) {
  validate_roundtrip_from_bytes(bit_count, bytes)
}

bench bench__roundtrip_from_ints((bit_count, ints) via ints_fuzzer) {
  validate_roundtrip_from_ints(bit_count, ints)
}
