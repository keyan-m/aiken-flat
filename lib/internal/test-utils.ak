//// @hidden

use aiken/fuzz

/// Datatype from the specs.
pub type Direction {
  North
  South
  Center
  East
  West
}

pub fn direction_fuzzer() -> Fuzzer<Direction> {
  fuzz.one_of([North, South, Center, East, West])
}

pub type Color {
  Abyss
  BlackAndWhite { white: Int }
  Colored { red: Int, green: Int, blue: Int }
}

pub fn color_fuzzer() -> Fuzzer<Color> {
  let tag <- fuzz.and_then(fuzz.int_between(0, 2))
  if tag == 0 {
    fuzz.constant(Abyss)
  } else if tag == 1 {
    let white <- fuzz.and_then(fuzz.int_between(0, 255))
    fuzz.constant(BlackAndWhite { white })
  } else {
    let red <- fuzz.and_then(fuzz.int_between(0, 255))
    let green <- fuzz.and_then(fuzz.int_between(0, 255))
    let blue <- fuzz.and_then(fuzz.int_between(0, 255))
    fuzz.constant(Colored { red, green, blue })
  }
}
