use aiken/fuzz
use aiken_flat/zig_zag.{zag_zig, zig_zag}
use internal/utils.{i128_max_bound, i128_min_bound, u128_max_bound}

fn validate_roundtrip_zig_zag_zig(x: Int) -> Bool {
  let zig = zig_zag(x)
  let back_to_x = zag_zig(zig)
  x == back_to_x
}

fn validate_roundtrip_zag_zig_zag(x: Int) -> Bool {
  let zag = zag_zig(x)
  let back_to_x = zig_zag(zag)
  x == back_to_x
}

/// Tests for zig-zag encoding and decoding functions, with i128 numbers.
test success__roundtrip_zig_zag_zig(
  x via fuzz.int_between(i128_min_bound, i128_max_bound),
) {
  validate_roundtrip_zig_zag_zig(x)
}

/// Tests for zig-zag encoding and decoding functions, with u128 numbers.
test success__roundtrip_zag_zig_zag(x via fuzz.int_between(0, u128_max_bound)) {
  validate_roundtrip_zag_zig_zag(x)
}
