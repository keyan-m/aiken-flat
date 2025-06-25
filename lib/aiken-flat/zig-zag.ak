pub fn zig_zag(x: Int) -> Int {
  if x < 0 {
    x * -2 - 1
  } else {
    x * 2
  }
}

pub fn zag_zig(x: Int) -> Int {
  if x % 2 == 0 {
    x / 2
  } else {
    ( x + 1 ) / -2
  }
}
