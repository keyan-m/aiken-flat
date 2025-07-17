/// Datatype from the specs.
pub type Direction {
  North
  South
  Center
  East
  West
}

pub type Color {
  Abyss
  BlackAndWhite { white: Int }
  Colored { red: Int, green: Int, blue: Int }
}
