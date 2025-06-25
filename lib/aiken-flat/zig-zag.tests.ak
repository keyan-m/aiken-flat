use aiken/fuzz
use aiken_flat/zig_zag.{zag_zig, zig_zag}

fn validate_roundtrip_zig_then_zag(x: Int) -> Bool {
  let zig = zig_zag(x)
  let back_to_x = zag_zig(zig)
  x == back_to_x
}

fn validate_roundtrip_zag_then_zig(x: Int) -> Bool {
  let zag = zag_zig(x)
  let back_to_x = zig_zag(zag)
  x == back_to_x
}

/// Tests for zig-zag encoding and decoding functions, with i128 numbers.
test success__roundtrip_zig_then_zag(
  x via fuzz.int_between(-170141183460469231731687303715884105728, 170141183460469231731687303715884105727),
) {
  validate_roundtrip_zig_then_zag(x)
}

/// Tests for zig-zag encoding and decoding functions, with u128 numbers.
test success__roundtrip_zag_then_zig(
  x via fuzz.int_between(0, 340282366920938463463374607431768211455),
) {
  validate_roundtrip_zag_then_zig(x)
}
