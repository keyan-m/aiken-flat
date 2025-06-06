use aiken/collection/list
use zig_zag/decoder.{zag_zig}
use zig_zag/encoder.{zig_zag_8}

const test_bytes: List<ByteArray> =
  [#"00", #"01", #"02", #"03", #"04", #"05", #"06"]

const test_ints: List<Int> = [0, -1, 1, -2, 2, -3, 3]

test success__zig_zag_8() {
  let actual: List<ByteArray> = test_ints |> list.map(zig_zag_8)
  actual == test_bytes
}

test success__zag_zig() {
  let actual: List<Int> = test_bytes |> list.map(zag_zig)
  actual == test_ints
}
