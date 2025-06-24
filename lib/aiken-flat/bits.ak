use aiken/collection/list
use internal/utils.{zip_foldr}

pub type Bit {
  Zero
  One
}

pub type Bits = List<Bit>

pub fn to_bool(bit: Bit) -> Bool {
  when bit is {
    Zero -> False
    One -> True
  }
}

pub fn from_bool(bool: Bool) -> Bit {
  if bool {
    One
  } else {
    Zero
  }
}

pub fn to_bools(bits: Bits) -> List<Bool> {
  bits |> list.map(fn (bit) {
    when bit is {
      Zero -> False
      One -> True
    }
  })
}

pub fn from_bools(bools: List<Bool>) -> Bits {
  bools |> list.map(fn (b) {
    if b {
      One
    } else {
      Zero
    }
  })
}

/// Folds both bits from right, and preserves remaining bits of the longer bits.
fn do_or_bits(left: Bits, right: Bits, acc: Bits) -> Bits {
  when left is {
    [] -> list.concat(right, acc)
    [l, ..ls] -> {
      when right is {
        [] -> list.concat(left, acc)
        [r, ..rs] -> {
          let lsbs = do_or_bits(ls, rs, acc)
          let msb = or { to_bool(l), to_bool(r), } |> from_bool
          lsbs |> list.push(msb)
        }
      }
    }
  }
}

pub fn or_bits(left: Bits, right: Bits) -> Bits {
  do_or_bits(left, right, [])
}
