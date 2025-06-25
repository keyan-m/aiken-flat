use aiken/collection/list
use aiken/math
use aiken/primitive/string
use aiken_scott_utils/list as scott_list
use internal/utils.{zip_foldr}

pub type Bit {
  Zero
  One
}

pub type Bits =
  List<Bit>

pub fn bit_and(left: Bit, right: Bit) -> Bit {
  when left is {
    Zero -> Zero
    One ->
      when right is {
        Zero -> Zero
        One -> One
      }
  }
}

pub fn bit_or(left: Bit, right: Bit) -> Bit {
  when left is {
    Zero ->
      when right is {
        Zero -> Zero
        One -> One
      }
    One -> One
  }
}

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
  bits
    |> list.map(
        fn(bit) {
          when bit is {
            Zero -> False
            One -> True
          }
        },
      )
}

pub fn from_bools(bools: List<Bool>) -> Bits {
  bools
    |> list.map(
        fn(b) {
          if b {
            One
          } else {
            Zero
          }
        },
      )
}

pub fn to_string(bit: Bit) -> String {
  when bit is {
    Zero -> @"0"
    One -> @"1"
  }
}

pub fn pretty_print(bits: Bits) -> String {
  bits |> list.foldr(@"", fn(bit, acc) { string.concat(to_string(bit), acc) })
}

fn op_with_padding(left: Bits, right: Bits, op: fn(Bit, Bit) -> Bit) -> Bits {
  let left_len = list.length(left)
  let right_len = list.length(right)
  let max_len = math.max(left_len, right_len)
  let padded_left = list.repeat(Zero, max_len - left_len) |> list.concat(left)
  let padded_right =
    list.repeat(Zero, max_len - right_len) |> list.concat(right)
  zip_foldr(
    padded_left,
    padded_right,
    [],
    fn(l, r, acc) { acc |> list.push(op(l, r)) },
  )
}

pub fn op_with_truncation(
  left: Bits,
  right: Bits,
  op: fn(Bit, Bit) -> Bit,
) -> Bits {
  let left_len = list.length(left)
  let right_len = list.length(right)
  let min_len = math.min(left_len, right_len)
  let truncated_left = left |> list.drop(left_len - min_len)
  let truncated_right = right |> list.drop(right_len - min_len)
  zip_foldr(
    truncated_left,
    truncated_right,
    [],
    fn(l, r, acc) { acc |> list.push(op(l, r)) },
  )
}

pub fn and_with_padding(left: Bits, right: Bits) -> Bits {
  op_with_padding(left, right, bit_and)
}

pub fn and_with_truncation(left: Bits, right: Bits) -> Bits {
  op_with_truncation(left, right, bit_and)
}

pub fn or_with_padding(left: Bits, right: Bits) -> Bits {
  op_with_padding(left, right, bit_or)
}

pub fn or_with_truncation(left: Bits, right: Bits) -> Bits {
  op_with_truncation(left, right, bit_or)
}

pub fn pad_to_byte(bits: Bits) -> Bits {
  let len = list.length(bits)
  let padding = 8 - len % 8
  if padding == 0 {
    bits
  } else {
    list.repeat(Zero, padding) |> list.concat(bits)
  }
}

pub fn to_bytearray(bits: Bits) -> ByteArray {
  let
    len_before_padding,
    bools_before_padding,
  <-
    scott_list.foldr2(
      bits,
      0,
      [],
      fn(bit, len_so_far, bools_acc, return) {
        return(len_so_far + 1, list.push(bools_acc, to_bool(bit)))
      },
    )
  let padding = 8 - len_before_padding % 8
  let padded_bools =
    if padding == 0 {
      bools_before_padding
    } else {
      list.repeat(False, padding) |> list.concat(bools_before_padding)
    }
  let one_byte_to_bytearray = fn(bools: List<Bool>) -> ByteArray {
    let res, _ <-
    list.foldr(bools, #"00", 0, fn(bit, i, acc, return) {
      return(builtin.write_bits(acc, [i], bit), i + 1)
    })
  }
  let go = fn(bits, acc) {
    when bits is {
      [] -> acc
      _ -> {
        let (byte, rest) = list.span(bits, 8)
        go(rest, bytearray.concat(one_byte_to_bytearray(byte), acc))
      }
    }
  }
  go(padded_bools, #"")
}
