use aiken/builtin
use aiken/collection/list
use aiken/math
use aiken/primitive/bytearray
use aiken/primitive/string
use aiken_scott_utils/list as scott_list
use internal/utils.{zip_foldr}

pub type Bit =
  Bool

pub type Bits =
  List<Bit>

pub fn bit_and(left: Bit, right: Bit) -> Bit {
  and {
    left,
    right,
  }
}

pub fn bit_or(left: Bit, right: Bit) -> Bit {
  or {
    left,
    right,
  }
}

pub fn bit_to_string(bit: Bit) -> String {
  if bit {
    @"1"
  } else {
    @"0"
  }
}

pub fn pretty_print(bits: Bits) -> String {
  bits
    |> list.foldr(@"", fn(bit, acc) { string.concat(bit_to_string(bit), acc) })
}

fn op_with_padding(left: Bits, right: Bits, op: fn(Bit, Bit) -> Bit) -> Bits {
  let left_len = list.length(left)
  let right_len = list.length(right)
  let max_len = math.max(left_len, right_len)
  let padded_left = list.repeat(False, max_len - left_len) |> list.concat(left)
  let padded_right =
    list.repeat(False, max_len - right_len) |> list.concat(right)
  zip_foldr(padded_left, padded_right, [], fn(l, r, acc) { [op(l, r), ..acc] })
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
    fn(l, r, acc) { [op(l, r), ..acc] },
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
  let padding = ( 8 - len % 8 ) % 8
  if padding == 0 {
    bits
  } else {
    list.repeat(False, padding) |> list.concat(bits)
  }
}

fn unsafe_one_byte_to_bytearray(bools: List<Bool>) -> ByteArray {
  let
    res,
    _,
  <-
    scott_list.foldr2(
      bools,
      #"00",
      0,
      fn(bit, acc, i, return) {
        return(builtin.write_bits(acc, [i], bit), i + 1)
      },
    )
  res
}

test success__unsafe_one_byte_to_bytearray() {
  let byte = [True, False, False, False, True, True, True, True]
  let expected = #"8f"
  let result = unsafe_one_byte_to_bytearray(byte)
  result == expected
}

fn to_bytearray_helper(bits: List<Bool>, acc: ByteArray) -> ByteArray {
  when bits is {
    [] -> acc
    _ -> {
      let (byte, rest) = list.span(bits, 8)
      to_bytearray_helper(
        rest,
        bytearray.concat(acc, unsafe_one_byte_to_bytearray(byte)),
      )
    }
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
        return(len_so_far + 1, [bit, ..bools_acc])
      },
    )
  let padding = ( 8 - len_before_padding % 8 ) % 8
  let padded_bools =
    if padding == 0 {
      bools_before_padding
    } else {
      list.concat(list.repeat(False, padding), bools_before_padding)
    }
  to_bytearray_helper(padded_bools, #"")
}

fn unsafe_bits_from_one_byte(bytearray: ByteArray) -> Bits {
  [7, 6, 5, 4, 3, 2, 1, 0]
    |> list.foldr([], fn(i, acc) { [builtin.read_bit(bytearray, i), ..acc] })
}

test success__unsafe_bits_from_one_byte() {
  let byte = #"81"
  let expected = [True, False, False, False, False, False, False, True]
  let result = unsafe_bits_from_one_byte(byte)
  result == expected
}

fn unsafe_bits_to_word8(bits: Bits) -> Int {
  bits
    |> list.foldr(
        #"00",
        fn(bit, acc) {
          let left_shited = builtin.shift_bytearray(acc, 1)
          builtin.or_bytearray(
            False,
            left_shited,
            if bit {
              #"01"
            } else {
              #"00"
            },
          )
        },
      )
    |> builtin.bytearray_to_integer(True, _)
}

test success__unsafe_bits_to_word8() {
  let bits = [True, False, False, False, False, False, False, True]
  let expected = 129
  let result = unsafe_bits_to_word8(bits)
  result == expected
}

fn unsafe_bits_from_word8(w8: Int) -> Bits {
  w8 |> bytearray.from_int_big_endian(1) |> unsafe_bits_from_one_byte
}

test success__unsafe_bits_from_word8() {
  let w8 = 129
  let expected = [True, False, False, False, False, False, False, True]
  let result = unsafe_bits_from_word8(w8)
  result == expected
}

pub fn from_bytearray(bytes: ByteArray) -> Bits {
  bytes
    |> bytearray.foldr(
        [],
        fn(byte, acc) {
          let bits = unsafe_bits_from_word8(byte)
          list.concat(bits, acc)
        },
      )
}

/// `tag` is zero-indexed. So for a datatype like:
/// ```aiken
/// pub type Direction {
///   North  // tag == 0
///   South  // tag == 1
///   Center // tag == 2
///   East   // tag == 3
///   West   // tag == 4
/// }
/// ```
/// `constr_count` will be `5`.
///
/// Note that the resulting `Bits` here is in reverse order.
fn do_tag_to_bits(constr_count: Int, tag: Int, so_far: Bits) -> Bits {
  let halved = constr_count / 2
  if halved <= 0 {
    so_far
  } else if halved == 1 {
    if constr_count == 3 {
      if tag == 0 {
        so_far |> list.push(False)
      } else if tag == 1 {
        so_far |> list.push(True) |> list.push(False)
      } else {
        so_far |> list.push(True) |> list.push(True)
      }
    } else {
      if tag == 0 {
        so_far |> list.push(False)
      } else {
        so_far |> list.push(True)
      }
    }
  } else {
    if tag < halved {
      do_tag_to_bits(halved, tag, [False, ..so_far])
    } else {
      let new_constr =
        if constr_count % 2 == 0 {
          halved
        } else {
          halved + 1
        }
      do_tag_to_bits(new_constr, tag - halved, [True, ..so_far])
    }
  }
}

/// Helper function for finding Flat `Bits` of a generic sum type's data
/// constructor. This leverages the `Data` type from UPLC for extracting the
/// `Constr` tag.
///
/// Not enforced, but only `constr_count` values greater than or equal to `1`
/// make sense, with `tag` being less than or equal to `constr_count - 1`.
/// `constr_count`s less than or equal to `1` yield an empty list, while a
/// negative `tag` leads to infinite recursion.
pub fn tag_to_bits(constr_count: Int, tag: Int) -> Bits {
  do_tag_to_bits(constr_count, tag, []) |> list.reverse
}

fn do_bits_to_tag(constr_count: Int, bits: Bits, so_far: Int) -> Int {
  when bits is {
    [curr_bit, ..rest] -> {
      let halved = constr_count / 2
      if curr_bit {
        // Taking the right subtree -> sum with left subtree element count
        do_bits_to_tag(constr_count - halved, rest, halved + so_far)
      } else {
        do_bits_to_tag(halved, rest, so_far)
      }
    }
    [] -> so_far
  }
}

pub fn bits_to_tag(constr_count: Int, bits: Bits) -> Int {
  do_bits_to_tag(constr_count, bits, 0)
}
