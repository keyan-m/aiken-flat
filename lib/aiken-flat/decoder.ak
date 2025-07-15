use aiken/builtin
use aiken/collection/list
use aiken/primitive/bytearray
use aiken_flat/bits.{Bits, bits_to_tag}
use aiken_flat/zig_zag.{zag_zig}
use aiken_scott_utils/types.{Scott2}
use internal/extra/bytearray as ba_extra

/// Opaque type for decoding from a stored buffer.
pub opaque type Decoder {
  buffer: ByteArray,
  used_bits: Int,
  pos: Int,
}

/// Function type shared by all decoders.
type DecoderFn<a> =
  fn(Decoder) -> (a, Decoder)

/// Initiate a decoder.
pub fn new(bytes: ByteArray) -> Decoder {
  Decoder { buffer: bytes, used_bits: 0, pos: 0 }
}

pub const identity_decoder_fn_selector =
  fn(_: Int) -> DecoderFn<Data> { fn(self) { (builtin.list_data([]), self) } }

// ## Basics

pub fn map_decoded(
  decoder_res: (a, Decoder),
  map_fn: fn(a) -> b,
) -> (b, Decoder) {
  let (decoded_a, self) = decoder_res
  (decoded_a |> map_fn, self)
}

pub fn pipe(
  decoder_res: (a, Decoder),
  next_decoder: DecoderFn<b>,
  monoid: fn(a, b) -> c,
) -> (c, Decoder) {
  let (decoded_a, self) = decoder_res
  let (decoded_b, updated_self) = self |> next_decoder
  let decoded_c = monoid(decoded_a, decoded_b)
  (decoded_c, updated_self)
}

// ## Runners

/// Returns the decoded value.
pub fn unwrap(decoder_res: (a, Decoder)) -> a {
  decoder_res.1st
}

// ## Essential Decoders

pub fn integer(self: Decoder) -> (Int, Decoder) {
  let (w, new_decoder) = self |> word
  (zag_zig(w), new_decoder)
}

pub fn bool(self: Decoder) -> (Bool, Decoder) {
  self |> bit
}

pub fn u8(self: Decoder) -> (ByteArray, Decoder) {
  self |> bits8(8)
}

pub fn bytes(self: Decoder) -> (ByteArray, Decoder) {
  self |> filler |> byte_array
}

pub fn filler(self: Decoder) -> Decoder {
  let (current_bit_is_zero, new_decoder) = self |> zero
  if current_bit_is_zero {
    filler(new_decoder)
  } else {
    new_decoder
  }
}

pub fn word(self: Decoder) -> (Int, Decoder) {
  let leading_bit = #"01"
  let final_word = #"00"
  let shl = 0
  do_word(self, leading_bit, final_word, shl)
}

fn do_word(
  self: Decoder,
  leading_bit: ByteArray,
  final_word: ByteArray,
  shl: Int,
) -> (Int, Decoder) {
  let int_leading_bit = builtin.bytearray_to_integer(True, leading_bit)
  if int_leading_bit > 0 {
    let (word8, new_decoder) = self |> bits8(8)
    let word7 = builtin.and_bytearray(False, word8, #"7f")
    let shifted_word7 = ba_extra.shift_left(word7, shl)
    let (padded_final_word, padded_shifted_word7) =
      ba_extra.left_zero_pad_to_match(final_word, shifted_word7)
    let new_final_word =
      builtin.or_bytearray(False, padded_final_word, padded_shifted_word7)
    let new_shl = shl + 7
    let new_leading_bit = builtin.and_bytearray(True, word8, #"80")
    do_word(new_decoder, new_leading_bit, new_final_word, new_shl)
  } else {
    let res = (builtin.bytearray_to_integer(True, final_word), self)
    res
  }
}

pub fn decode_list_with(
  self: Decoder,
  decoder_func: fn(Decoder) -> (a, Decoder),
) -> (List<a>, Decoder) {
  do_decode_list_with(self, decoder_func, [])
    |> map_decoded(list.reverse)
}

fn do_decode_list_with(
  self: Decoder,
  decoder_fn: DecoderFn<a>,
  acc: List<a>,
) -> (List<a>, Decoder) {
  let (current_bit, new_self) = self |> bit
  if current_bit {
    let (decoded, new_decoder) = self |> decoder_fn
    do_decode_list_with(new_decoder, decoder_fn, list.push(acc, decoded))
  } else {
    (acc, new_self)
  }
}

fn zero(self: Decoder) -> (Bool, Decoder) {
  let (current_bit, new_decoder) = self |> bit
  (!current_bit, new_decoder)
}

fn bit(self: Decoder) -> (Bool, Decoder) {
  let Decoder { buffer, used_bits, pos } = self
  // `get_byte_at` uses `bytearray.at` under the hood, which itself fails if
  // given index is out of bounds. So no need to validate that `pos` is not less
  // than `buffer`'s length.
  let current_byte = buffer |> get_byte_at(pos)
  let byte_with_current_bit_on = builtin.shift_bytearray(#"80", -used_bits)
  let current_bit_as_byte =
    builtin.and_bytearray(False, current_byte, byte_with_current_bit_on)
  let current_bit_is_on =
    ( current_bit_as_byte |> bytearray.compare(#"00") ) == Greater

  (current_bit_is_on, self |> increment_buffer_by_bit)
}

/// Decoded bits are in reverse order here.
fn do_bits(self: Decoder, so_far: Bits, bit_count: Int) -> (Bits, Decoder) {
  if bit_count <= 0 {
    (so_far, self)
  } else {
    let (b, new_self) = self |> bit
    new_self |> do_bits([b, ..so_far], bit_count - 1)
  }
}

pub fn bits(self: Decoder, bit_count: Int) -> (Bits, Decoder) {
  self |> do_bits([], bit_count) |> map_decoded(list.reverse)
}

fn do_byte_array(
  self: Decoder,
  decoded_array_so_far: ByteArray,
) -> (ByteArray, Decoder) {
  let Decoder { buffer, used_bits, pos } = self

  expect used_bits == 0

  // `bytearray.at` fails if `pos` is out of bounds, so no need for
  // `ensure_bytes` here.
  let chunk_len = buffer |> bytearray.at(pos)

  let new_pos = pos + 1

  if chunk_len != 0 {
    expect self |> ensure_bytes(chunk_len + 1)

    let pos_after_chunk = new_pos + chunk_len

    let decoded_chunk = buffer |> bytearray.slice(new_pos, pos_after_chunk - 1)

    let updated_decoded_array =
      bytearray.concat(decoded_array_so_far, decoded_chunk)

    do_byte_array(
      Decoder { ..self, pos: pos_after_chunk },
      updated_decoded_array,
    )
  } else {
    (decoded_array_so_far, Decoder { ..self, pos: new_pos })
  }
}

pub fn byte_array(self: Decoder) -> (ByteArray, Decoder) {
  do_byte_array(self, #"")
}

/// Decoded value is a single byte.
pub fn bits8(self: Decoder, n: Int) -> (ByteArray, Decoder) {
  expect n <= 8

  expect ensure_bits(self, n)

  let Decoder { buffer, used_bits, pos } = self
  let unused_bits = 8 - used_bits
  let leading_zeroes = 8 - n
  let current_byte = buffer |> get_byte_at(pos)
  let r =
    current_byte
      |> builtin.shift_bytearray(used_bits)
      |> builtin.shift_bytearray(-leading_zeroes)

  let x =
    if n > unused_bits {
      let next_byte = buffer |> get_byte_at(pos + 1)
      let next_byte_shifted =
        next_byte |> builtin.shift_bytearray(-unused_bits - leading_zeroes)
      builtin.or_bytearray(False, r, next_byte_shifted)
    } else {
      r
    }

  (x, self |> drop_bits(n))
}

fn ensure_bytes(self: Decoder, required_bytes: Int) -> Bool {
  let Decoder { buffer, pos, .. } = self
  if required_bytes > bytearray.length(buffer) - pos {
    fail @"Not enough bytes"
  } else {
    True
  }
}

fn ensure_bits(self: Decoder, required_bits: Int) -> Bool {
  let Decoder { buffer, used_bits, pos } = self
  if required_bits > ( bytearray.length(buffer) - pos ) * 8 - used_bits {
    fail @"Not enought bits"
  } else {
    True
  }
}

fn drop_bits(self: Decoder, n: Int) -> Decoder {
  let Decoder { used_bits, pos, .. } = self
  let all_used_bits = n + used_bits
  Decoder { ..self, used_bits: all_used_bits % 8, pos: pos + all_used_bits / 8 }
}

fn increment_buffer_by_bit(self: Decoder) -> Decoder {
  let Decoder { used_bits, pos, .. } = self
  if used_bits == 7 {
    Decoder { ..self, pos: pos + 1, used_bits: 0 }
  } else {
    Decoder { ..self, used_bits: used_bits + 1 }
  }
}

fn get_byte_at(self: ByteArray, i: Int) -> ByteArray {
  self |> bytearray.at(i) |> builtin.integer_to_bytearray(True, 1, _)
}

// ## Custom Type Decoders

pub fn make_rec_2(
  f0_decoder: DecoderFn<Data>,
  f1_decoder: DecoderFn<Data>,
) -> DecoderFn<List<Data>> {
  fn(self: Decoder) -> (List<Data>, Decoder) {
    self
      |> f0_decoder
      |> pipe(f1_decoder, fn(f0, f1) { [f0, f1] })
  }
}

pub fn make_rec_3(
  f0_decoder: DecoderFn<Data>,
  f1_decoder: DecoderFn<Data>,
  f2_decoder: DecoderFn<Data>,
) -> DecoderFn<List<Data>> {
  fn(self: Decoder) -> (List<Data>, Decoder) {
    self
      |> f0_decoder
      |> pipe(f1_decoder, fn(f0, f1) { [f0, f1] })
      |> pipe(f2_decoder, fn(fs, f2) { list.concat(fs, [f2]) })
  }
}

pub fn make_rec_4(
  f0_decoder: DecoderFn<Data>,
  f1_decoder: DecoderFn<Data>,
  f2_decoder: DecoderFn<Data>,
  f3_decoder: DecoderFn<Data>,
) -> DecoderFn<List<Data>> {
  fn(self: Decoder) -> (List<Data>, Decoder) {
    self
      |> f0_decoder
      |> pipe(f1_decoder, fn(f0, f1) { [f1, f0] })
      |> pipe(f2_decoder, fn(fs, f2) { [f2, ..fs] })
      |> pipe(f3_decoder, fn(fs, f3) { [f3, ..fs] })
      |> map_decoded(list.reverse)
  }
}

fn do_make_rec(
  res_so_far: (List<Data>, Decoder),
  decoder_fn_selector: fn(Int) -> DecoderFn<Data>,
  curr_index: Int,
  field_count: Int,
) -> (List<Data>, Decoder) {
  if curr_index >= field_count {
    res_so_far |> map_decoded(list.reverse)
  } else {
    let decoder_fn = decoder_fn_selector(curr_index)
    res_so_far
      |> pipe(decoder_fn, fn(fs, f) { [f, ..fs] })
      |> do_make_rec(decoder_fn_selector, curr_index + 1, field_count)
  }
}

/// Helper for making record type decoders. `field_count` can't be negative, but
/// this is not validated (TODO?).
pub fn make_rec(
  field_count: Int,
  decoder_fn_selector: fn(Int) -> DecoderFn<Data>,
) -> DecoderFn<List<Data>> {
  fn(self: Decoder) -> (List<Data>, Decoder) {
    do_make_rec(([], self), decoder_fn_selector, 0, field_count)
  }
}

/// Helper for making decoders for sum types with 2 data constructors, with
/// specified number of arguments each. More performant than using
/// [`make_sum`](#make_sum). The `Data` in return type is a `Constr`.
pub fn make_sum_2(
  c0_decoders: fn(Int) -> DecoderFn<Data>,
  c0_field_count: Int,
  c1_decoders: fn(Int) -> DecoderFn<Data>,
  c1_field_count: Int,
) -> DecoderFn<Data> {
  fn(self: Decoder) -> (Data, Decoder) {
    let (is_one, one_bit_decoded) = self |> bit
    if is_one {
      let (fields, new_self) =
        one_bit_decoded |> make_rec(c1_field_count, c1_decoders)
      (builtin.constr_data(1, fields), new_self)
    } else {
      let (fields, new_self) =
        one_bit_decoded |> make_rec(c0_field_count, c0_decoders)
      (builtin.constr_data(0, fields), new_self)
    }
  }
}

/// Helper for making decoders for sum types with 3 data constructors, with
/// specified number of arguments each. More performant than using
/// [`make_sum`](#make_sum). The `Data` in return type is a `Constr`.
pub fn make_sum_3(
  c0_decoders: fn(Int) -> DecoderFn<Data>,
  c0_field_count: Int,
  c1_decoders: fn(Int) -> DecoderFn<Data>,
  c1_field_count: Int,
  c2_decoders: fn(Int) -> DecoderFn<Data>,
  c2_field_count: Int,
) -> DecoderFn<Data> {
  fn(self: Decoder) -> (Data, Decoder) {
    let (is_one, one_bit_decoded) = self |> bit
    if is_one {
      let (is_one, two_bits_decoded) = one_bit_decoded |> bit
      if is_one {
        let (fields, new_self) =
          two_bits_decoded |> make_rec(c2_field_count, c2_decoders)
        (builtin.constr_data(2, fields), new_self)
      } else {
        let (fields, new_self) =
          two_bits_decoded |> make_rec(c1_field_count, c1_decoders)
        (builtin.constr_data(1, fields), new_self)
      }
    } else {
      let (fields, new_self) =
        one_bit_decoded |> make_rec(c0_field_count, c0_decoders)
      (builtin.constr_data(0, fields), new_self)
    }
  }
}

/// Helper for making decoders for sum types with 4 data constructors, with
/// specified number of arguments each. More performant than using
/// [`make_sum`](#make_sum). The `Data` in return type is a `Constr`.
pub fn make_sum_4(
  c0_decoders: fn(Int) -> DecoderFn<Data>,
  c0_field_count: Int,
  c1_decoders: fn(Int) -> DecoderFn<Data>,
  c1_field_count: Int,
  c2_decoders: fn(Int) -> DecoderFn<Data>,
  c2_field_count: Int,
  c3_decoders: fn(Int) -> DecoderFn<Data>,
  c3_field_count: Int,
) -> DecoderFn<Data> {
  fn(self: Decoder) -> (Data, Decoder) {
    let (is_one, one_bit_decoded) = self |> bit
    if is_one {
      let (is_one, two_bits_decoded) = one_bit_decoded |> bit
      if is_one {
        let (fields, new_self) =
          two_bits_decoded |> make_rec(c3_field_count, c3_decoders)
        (builtin.constr_data(3, fields), new_self)
      } else {
        let (fields, new_self) =
          two_bits_decoded |> make_rec(c2_field_count, c2_decoders)
        (builtin.constr_data(2, fields), new_self)
      }
    } else {
      let (is_one, two_bits_decoded) = one_bit_decoded |> bit
      if is_one {
        let (fields, new_self) =
          two_bits_decoded |> make_rec(c1_field_count, c1_decoders)
        (builtin.constr_data(1, fields), new_self)
      } else {
        let (fields, new_self) =
          two_bits_decoded |> make_rec(c0_field_count, c0_decoders)
        (builtin.constr_data(0, fields), new_self)
      }
    }
  }
}

/// Helper function for generating decoders for sum types. The factory is
/// expected to be a function that takes an index, which is the index of the
/// constructor in the subject sum type, and a continuation that provides 2
/// values: the number of fields for the given tag, and a decoder selector,
/// which itself is a function that given the index of a field, returns a
/// decoder. I've used Scott encoding here as a function cannot be put inside a
/// tuple.
///
/// An example can be:
/// ```aiken
/// pub type Color {
///   Abyss
///   BlackAndWhite {
///     white: Int,
///   }
///   Colored {
///     red: Int,
///     green: Int,
///     blue: Int,
///   }
/// }
/// ```
/// The factory function for this datatype should be:
/// ```aiken
/// let color_decoder_factory =
///   fn(
///     tag: Int,
///     return: Scott2<Int, fn(Int) -> DecoderFn<Data>, (Data, Decoder),
///   ) -> (Data, Decoder) {
///     if tag == 0 {
///       return(0, identity_decoder_fn_selector)
///     } if tag == 1 {
///       return(1, fn(_) { integer })
///     } if tag == 2 {
///       return(3, fn(_) { integer })
///     } else {
///       fail
///     }
///   }
/// ```
/// And the decoder itself will be:
/// ```aiken
/// let color_decoder = make_sum(3, color_decoder_factory)
/// ```
pub fn make_sum(
  constr_count: Int,
  decoder_fn_selector_factory: fn(
    Int,
    Scott2<Int, fn(Int) -> DecoderFn<Data>, (Data, Decoder)>,
  ) ->
    (Data, Decoder),
) -> DecoderFn<Data> {
  fn(self: Decoder) -> (Data, Decoder) {
    let flat_tree = flat_tree_from_constr_count(constr_count)
    let (constr_bits, new_self) = self |> make_sum_helper(flat_tree, [])
    let constr_tag = bits_to_tag(constr_count, constr_bits)
    let
      tags_field_count,
      decoder_fn_selector,
    <- decoder_fn_selector_factory(constr_tag)
    let rec_decoder = make_rec(tags_field_count, decoder_fn_selector)
    new_self
      |> rec_decoder
      |> map_decoded(fn(fields) { builtin.constr_data(constr_tag, fields) })
  }
}

fn make_sum_helper(
  self: Decoder,
  flat_tree: FlatTree,
  acc: Bits,
) -> (Bits, Decoder) {
  let (decoded_bit, one_bit_decoded) = self |> bit
  let
    new_tree,
    new_acc,
  <-
    step_tree(
      flat_tree,
      decoded_bit,
      acc,
      fn(final_acc) { (final_acc, one_bit_decoded) },
    )
  make_sum_helper(one_bit_decoded, new_tree, new_acc)
}

fn step_tree(
  self: FlatTree,
  flag: Bool,
  acc: Bits,
  terminate: fn(Bits) -> result,
  continue: fn(FlatTree, Bits) -> result,
) -> result {
  let FlatTree { left_branch, right_branch } = self
  let check_right =
    fn() {
      when right_branch is {
        Leaf(right_value) ->
          if right_value == flag {
            terminate([right_value, ..acc])
          } else {
            // Shouldn't reach here, TODO?
            terminate(acc)
          }
        Node { value, left, right } ->
          if value == flag {
            continue(
              FlatTree { left_branch: left, right_branch: right },
              [value, ..acc],
            )
          } else {
            // Shouldn't reach here, TODO?
            terminate(acc)
          }
      }
    }
  when left_branch is {
    Leaf(left_value) ->
      if left_value == flag {
        terminate([left_value, ..acc])
      } else {
        check_right()
      }
    Node { value, left, right } ->
      if value == flag {
        continue(
          FlatTree { left_branch: left, right_branch: right },
          [value, ..acc],
        )
      } else {
        check_right()
      }
  }
}

type FlatTree {
  left_branch: FlatBranch,
  right_branch: FlatBranch,
}

type FlatBranch {
  Leaf(Bool)
  Node { value: Bool, left: FlatBranch, right: FlatBranch }
}

fn flat_tree_from_constr_count(constr_count: Int) -> FlatTree {
  // Using `expect` to avoid `Option`.
  expect constr_count > 1
  if constr_count == 2 {
    FlatTree { left_branch: Leaf(False), right_branch: Leaf(True) }
  } else if constr_count == 3 {
    FlatTree {
      left_branch: Leaf(False),
      right_branch: Node { value: True, left: Leaf(False), right: Leaf(True) },
    }
  } else {
    let halved = constr_count / 2
    FlatTree {
      left_branch: do_flat_branch_from_constr_count(halved, False),
      right_branch: do_flat_branch_from_constr_count(
        constr_count - halved,
        True,
      ),
    }
  }
}

fn do_flat_branch_from_constr_count(
  constr_count: Int,
  on_right: Bool,
) -> FlatBranch {
  // Avoiding validation on `constr_count` on the presumption that this function
  // will only be invoked with `flat_tree_from_constr_count`.
  if constr_count == 1 {
    Leaf(on_right)
  } else if constr_count == 2 {
    Node { value: on_right, left: Leaf(False), right: Leaf(True) }
  } else if constr_count == 3 {
    Node {
      value: on_right,
      left: Leaf(False),
      right: Node { value: True, left: Leaf(False), right: Leaf(True) },
    }
  } else {
    let halved = constr_count / 2
    Node {
      value: on_right,
      left: do_flat_branch_from_constr_count(halved, False),
      right: do_flat_branch_from_constr_count(constr_count - halved, True),
    }
  }
}
