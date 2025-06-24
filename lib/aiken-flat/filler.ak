use aiken/collection/list
use aiken_flat/bits.{Bits, One, Zero}

pub type Filler {
  Bit { filler: Filler }
  End
}

pub fn length(filler: Filler) -> Int {
  when filler is {
    Bit { filler } -> 1 + length(filler)
    End -> 0
  }
}

pub fn to_bits(filler: Filler) -> Bits {
  when filler is {
    Bit { filler } -> to_bits(filler) |> list.push(Zero)
    End -> [One]
  }
}
