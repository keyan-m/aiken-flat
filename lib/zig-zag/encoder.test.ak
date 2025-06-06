use aiken/collection/list
use zig_zag/encoder.{zig_zag_8}

test success() {
  let ints: List<Int> = [0, -1, 1, -2, 2, -3, 3]
  let expected: List<ByteArray> =
    [#"00", #"01", #"02", #"03", #"04", #"05", #"06"]
  let actual: List<ByteArray> = ints |> list.map(zig_zag_8)
  actual == expected
}
