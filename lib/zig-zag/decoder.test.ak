use aiken/collection/list
use zig_zag/decoder.{zag_zig}

test success() {
  let bytes: List<ByteArray> = [#"00", #"01", #"02", #"03", #"04", #"05", #"06"]
  let expected: List<Int> = [0, -1, 1, -2, 2, -3, 3]
  let actual: List<Int> = bytes |> list.map(zag_zig)
  actual == expected
}
