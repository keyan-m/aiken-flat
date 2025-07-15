use aiken/builtin.{head_list, tail_list}
use aiken/collection/list
use aiken/primitive/bytearray
use aiken_flat/bits.{Bits, tag_to_bits}
use aiken_flat/zig_zag.{zig_zag}
use internal/extra/bytearray as ba_extra
use internal/utils.{bytearray_chunks}

/// Opaque type for encoding given values and collecting them in a buffer.
pub opaque type Encoder {
  buffer: ByteArray,
  used_bits: Int,
  current_byte: ByteArray,
}

/// Function type shared by all encoders.
type EncoderFn<a> =
  fn(Encoder, a) -> Encoder

// ## Basics

pub fn contramap(
  encoder_fn: EncoderFn<a>,
  mapping_fn: fn(b) -> a,
) -> EncoderFn<b> {
  fn(self: Encoder, x: b) -> Encoder { self |> encoder_fn(mapping_fn(x)) }
}

/// Initiate an encoder.
pub const new: Encoder =
  Encoder { buffer: #"", used_bits: 0, current_byte: #"00" }

/// Identity encoder selector against field indices (helpful for defining empty
/// record type encoders).
pub const identity_encoder_fn_selector =
  fn(_: Int) -> EncoderFn<Data> { fn(self, _) { self } }

/// Identity encoder selector factory against tag indices (helpful for defining
/// empty sum type encoders).
pub const identity_encoder_fn_selector_factory =
  fn(_: Int) { identity_encoder_fn_selector }

// ## Runners

/// Returns the encoded bytes so far, ignoring the current byte.
pub fn unwrap(self: Encoder) -> ByteArray {
  self.buffer
}

// ## Essential Encoders

/// Assumes given `ByteArray` is a single byte.
pub fn unsafe_u8(self: Encoder, u8: ByteArray) -> Encoder {
  if self.used_bits == 0 {
    next_word(Encoder { ..self, current_byte: u8 })
  } else {
    byte_unaligned(self, u8)
  }
}

pub fn bool(self: Encoder, b: Bool) -> Encoder {
  if b {
    one(self)
  } else {
    zero(self)
  }
}

pub fn bytes(self: Encoder, arr: ByteArray) -> Encoder {
  self |> filler |> byte_array(arr)
}

pub fn byte_array(self: Encoder, arr: ByteArray) -> Encoder {
  expect self.used_bits == 0
  self |> unsafe_write_blk(arr)
}

pub fn integer(self: Encoder, x: Int) -> Encoder {
  self |> word(zig_zag(x))
}

fn do_word(self: Encoder, d: ByteArray) -> Encoder {
  let (_, padded_7f) = ba_extra.left_zero_pad_to_match(d, #"7f")
  let w = builtin.and_bytearray(False, d, padded_7f)
  let w =
    builtin.bytearray_to_integer(True, w)
      |> builtin.integer_to_bytearray(True, 0, _)
      |> builtin.or_bytearray(True, _, #"00")
  let shifted_d = d |> builtin.shift_bytearray(-7)
  let int_shifted_d = builtin.bytearray_to_integer(True, shifted_d)
  let shifted_d =
    int_shifted_d
      |> builtin.integer_to_bytearray(True, 0, _)
      |> builtin.or_bytearray(True, _, #"00")
  if int_shifted_d != 0 {
    let (_, padded_80) = ba_extra.left_zero_pad_to_match(w, #"80")
    let new_w = builtin.or_bytearray(False, w, padded_80)
    let new_w_bits = bits.from_bytearray(new_w)
    let new_encoder = self |> bits(new_w_bits)
    do_word(new_encoder, shifted_d)
  } else {
    let w_bits = bits.from_bytearray(w)
    self |> bits(w_bits)
  }
}

pub fn word(self: Encoder, x: Int) -> Encoder {
  // Size of `0` is equivalent to minimum required byte count.
  self |> do_word(builtin.integer_to_bytearray(True, 0, x))
}

pub fn encode_list_with(
  self: Encoder,
  list: List<a>,
  with: fn(Encoder, a) -> Encoder,
) -> Encoder {
  when list is {
    [] -> zero(self)
    _ ->
      list
        |> list.foldl(self, fn(item, acc) { with(one(acc), item) })
        |> zero
  }
}

pub fn bits(self: Encoder, bits: Bits) -> Encoder {
  bits
    |> list.foldl(
        self,
        fn(bit, acc) {
          if bit {
            one(acc)
          } else {
            zero(acc)
          }
        },
      )
}

pub fn filler(self: Encoder) -> Encoder {
  let (padded_current_byte, padded_01) =
    ba_extra.left_zero_pad_to_match(self.current_byte, #"01")
  Encoder {
    ..self,
    current_byte: builtin.or_bytearray(True, padded_current_byte, padded_01),
  }
    |> next_word
}

fn zero(self: Encoder) -> Encoder {
  let Encoder { used_bits, .. } = self
  if used_bits == 7 {
    next_word(self)
  } else {
    Encoder { ..self, used_bits: used_bits + 1 }
  }
}

fn one(self: Encoder) -> Encoder {
  let Encoder { buffer, current_byte, used_bits } = self
  if used_bits == 7 {
    let new_byte = current_byte |> builtin.or_bytearray(False, _, #"01")
    Encoder {
      buffer: bytearray.concat(buffer, new_byte),
      used_bits: 0,
      current_byte: #"00",
    }
  } else {
    Encoder {
      buffer,
      used_bits: used_bits + 1,
      current_byte: builtin.or_bytearray(
        False,
        current_byte,
        #"80" |> builtin.shift_bytearray(-used_bits),
      ),
    }
  }
}

fn next_word(self: Encoder) -> Encoder {
  let Encoder { buffer, current_byte, .. } = self
  Encoder {
    buffer: bytearray.concat(buffer, current_byte),
    used_bits: 0,
    current_byte: #"00",
  }
}

fn byte_unaligned(self: Encoder, byte: ByteArray) -> Encoder {
  let Encoder { buffer, current_byte, used_bits } = self
  // Fill the remaining bits of the current byte with first bits of the given
  // byte.
  let shifted_byte =
    byte
      |> builtin.shift_bytearray(-used_bits)
      |> builtin.or_bytearray(False, _, current_byte)
  // Preserve the remaining bits of the given byte in `current_byte`.
  let new_current_byte = byte |> builtin.shift_bytearray(8 - used_bits)
  Encoder {
    buffer: bytearray.concat(buffer, shifted_byte),
    used_bits,
    current_byte: new_current_byte,
  }
}

/// Assumes byte alignment.
fn unsafe_write_blk(self: Encoder, arr: ByteArray) -> Encoder {
  let buffer_before_0 =
    arr
      |> bytearray_chunks(255)
      |> list.foldl(
          self.buffer,
          fn(chunk, acc) {
            let chunk_length_byte =
              builtin.integer_to_bytearray(True, 1, bytearray.length(chunk))
            acc
              |> bytearray.concat(chunk_length_byte)
              |> bytearray.concat(chunk)
          },
        )
  Encoder { ..self, buffer: bytearray.concat(buffer_before_0, #"00") }
}

// ## Custom Type Encoders

/// Helper for making encoders for record types with 2 fields. More performant
/// than using [`make_rec`](#make_rec).
pub fn make_rec_2(
  f0_encoder: EncoderFn<Data>,
  f1_encoder: EncoderFn<Data>,
) -> EncoderFn<List<Data>> {
  fn(self: Encoder, fields: List<Data>) -> Encoder {
    self
      |> f0_encoder(fields |> head_list)
      |> f1_encoder(fields |> tail_list |> head_list)
  }
}

/// Helper for making encoders for record types with 3 fields. More performant
/// than using [`make_rec`](#make_rec).
pub fn make_rec_3(
  f0_encoder: EncoderFn<Data>,
  f1_encoder: EncoderFn<Data>,
  f2_encoder: EncoderFn<Data>,
) -> EncoderFn<List<Data>> {
  fn(self: Encoder, fields: List<Data>) -> Encoder {
    let no_head = fields |> tail_list
    self
      |> f0_encoder(fields |> head_list)
      |> f1_encoder(no_head |> head_list)
      |> f2_encoder(no_head |> tail_list |> head_list)
  }
}

/// Helper for making encoders for record types with 4 fields. More performant
/// than using [`make_rec`](#make_rec).
pub fn make_rec_4(
  f0_encoder: EncoderFn<Data>,
  f1_encoder: EncoderFn<Data>,
  f2_encoder: EncoderFn<Data>,
  f3_encoder: EncoderFn<Data>,
) -> EncoderFn<List<Data>> {
  fn(self: Encoder, fields: List<Data>) -> Encoder {
    let no_head = fields |> tail_list
    let no_head_and_next = no_head |> tail_list
    self
      |> f0_encoder(fields |> head_list)
      |> f1_encoder(no_head |> head_list)
      |> f2_encoder(no_head_and_next |> head_list)
      |> f3_encoder(no_head_and_next |> tail_list |> head_list)
  }
}

/// Helper for creating record type encoders. The resulting encoder traverses a
/// list of `Data` values and uses their indices to find their corresponding
/// encoders from the provided selector function.
/// 
/// We're using `Data` here since Aiken does not support downcasting a
/// polymorphic type yet.
pub fn make_rec(
  encoder_fn_selector: fn(Int) -> EncoderFn<Data>,
) -> EncoderFn<List<Data>> {
  fn(self: Encoder, fields: List<Data>) -> Encoder {
    let
      _,
      final_encoder,
    <-
      list.foldl2(
        fields,
        0,
        self,
        fn(field_data: Data, curr_index: Int, acc: Encoder, return) {
          let f_encoder = encoder_fn_selector(curr_index)
          return(curr_index + 1, acc |> f_encoder(field_data))
        },
      )
    final_encoder
  }
}

/// Helper for making encoders for sum types with 2 data constructors, and
/// arbitrary fields in each. More performant than using
/// [`make_sum`](#make_sum). The `Data` in return type is assumed to be a
/// `Constr`.
pub fn make_sum_2(
  c0_encoders: fn(Int) -> EncoderFn<Data>,
  c1_encoders: fn(Int) -> EncoderFn<Data>,
) -> EncoderFn<Data> {
  fn(self: Encoder, constr_data: Data) -> Encoder {
    let Pair(tag, fields) = builtin.un_constr_data(constr_data)
    if tag == 0 {
      self |> zero |> make_rec(c0_encoders)(fields)
    } else {
      self |> one |> make_rec(c1_encoders)(fields)
    }
  }
}

/// Helper for making encoders for sum types with 3 data constructors, and
/// arbitrary fields in each. More performant than using
/// [`make_sum`](#make_sum). The `Data` in return type is assumed to be a
/// `Constr`.
pub fn make_sum_3(
  c0_encoders: fn(Int) -> EncoderFn<Data>,
  c1_encoders: fn(Int) -> EncoderFn<Data>,
  c2_encoders: fn(Int) -> EncoderFn<Data>,
) -> EncoderFn<Data> {
  fn(self: Encoder, constr_data: Data) -> Encoder {
    let Pair(tag, fields) = builtin.un_constr_data(constr_data)
    if tag == 0 {
      self |> zero |> make_rec(c0_encoders)(fields)
    } else if tag == 1 {
      self |> one |> zero |> make_rec(c1_encoders)(fields)
    } else {
      self |> one |> one |> make_rec(c2_encoders)(fields)
    }
  }
}

/// Helper for making encoders for sum types with 4 data constructors, and
/// arbitrary fields in each. More performant than using
/// [`make_sum`](#make_sum). The `Data` in return type is assumed to be a
/// `Constr`.
pub fn make_sum_4(
  c0_encoders: fn(Int) -> EncoderFn<Data>,
  c1_encoders: fn(Int) -> EncoderFn<Data>,
  c2_encoders: fn(Int) -> EncoderFn<Data>,
  c3_encoders: fn(Int) -> EncoderFn<Data>,
) -> EncoderFn<Data> {
  fn(self: Encoder, constr_data: Data) -> Encoder {
    let Pair(tag, fields) = builtin.un_constr_data(constr_data)
    if tag == 0 {
      self |> zero |> zero |> make_rec(c0_encoders)(fields)
    } else if tag == 1 {
      self |> zero |> one |> make_rec(c1_encoders)(fields)
    } else if tag == 2 {
      self |> one |> zero |> make_rec(c2_encoders)(fields)
    } else {
      self |> one |> one |> make_rec(c3_encoders)(fields)
    }
  }
}

/// Helper function for generating encoders for sum types. The factory is
/// expected to be a function that takes an index, which is the index of the
/// constructor in the subject sum type, and returns another function that given
/// the index of a field from the record, returns an encoder function.
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
/// let color_encoder_factory =
///   fn(tag: Int) {
///     if tag == 0 {
///       identity_encoder_fn_selector
///     } else if tag == 1 {
///       fn(f_index: Int) {
///         if f_index == 0 {
///           integer |> contramap(builtin.un_i_data)
///         } else {
///           fail
///         }
///       }
///     } else if tag == 2 {
///       fn(f_index: Int) {
///         if f_index <= 2 {
///           integer |> contramap(builtin.un_i_data)
///         } else {
///           fail
///         }
///       }
///     } else {
///       fail
///     }
///   }
/// ```
/// In this case, it can be much simpler if we forgo the strictness:
/// ```aiken
/// let color_encoder_factory =
///   fn(_) {
///     fn(_) {
///       integer |> contramap(builtin.un_i_data)
///     }
///   }
/// ```
/// And the encoder itself will be:
/// ```aiken
/// let color_encoder = make_sum(3, color_encoder_factory)
/// ```
pub fn make_sum(
  constr_count: Int,
  encoder_fn_selector_factory: fn(Int) -> fn(Int) -> EncoderFn<Data>,
) -> EncoderFn<Data> {
  fn(self: Encoder, constr_data: Data) -> Encoder {
    let Pair(tag, fields) = builtin.un_constr_data(constr_data)
    let tag_bits = tag_to_bits(constr_count, tag)
    self |> bits(tag_bits) |> make_rec(encoder_fn_selector_factory(tag))(fields)
  }
}

// ## Tests
// Correct values acquired with Haskell's `flat` library.
// {{{
/// Datatype from the specs.
type Direction {
  North
  South
  Center
  East
  West
}

/// `current_byte`s are occupied from left to right on a `#"00"`, so a `0b1`
/// would yield a `used_bits == 1` and `current_byte` of `#"80"`.
///
/// ```
/// North  ─▶ 0b00  ─▶ 0000 0000 ─▶ #"00"
/// South  ─▶ 0b01  ─▶ 0100 0000 ─▶ #"40"
/// Center ─▶ 0b100 ─▶ 1000 0000 ─▶ #"80"
/// East   ─▶ 0b110 ─▶ 1100 0000 ─▶ #"C0"
/// West   ─▶ 0b111 ─▶ 1110 0000 ─▶ #"E0"
/// ```
test success__direction() {
  let direction_encoder = make_sum(5, identity_encoder_fn_selector_factory)
  let north = new |> direction_encoder(North)
  let south = new |> direction_encoder(South)
  let center = new |> direction_encoder(Center)
  let east = new |> direction_encoder(East)
  let west = new |> direction_encoder(West)
  trace north
  trace south
  trace center
  trace east
  trace west
  and {
    north.buffer == #"",
    north.used_bits == 2,
    north.current_byte == #"00",
    south.buffer == #"",
    south.used_bits == 2,
    south.current_byte == #"40",
    center.buffer == #"",
    center.used_bits == 2,
    center.current_byte == #"80",
    east.buffer == #"",
    east.used_bits == 3,
    east.current_byte == #"c0",
    west.buffer == #"",
    west.used_bits == 3,
    west.current_byte == #"e0",
  }
}

type Color {
  Abyss
  BlackAndWhite { white: Int }
  Colored { red: Int, green: Int, blue: Int }
}

/// ```
///  data              encoded bits              current byte
/// ----------------||------------------------||--------------
/// Abyss           ─▶ 0b0                    ─▶ #"00"
/// BlackAndWhite 0 ─▶ 0b10 <> (1 zero byte)  ─▶ #"00"
/// Colored 0 0 0   ─▶ 0b11 <> (3 bytes of 0) ─▶ #"00"
/// ```
test success__color() {
  let color_encoder_factory =
    fn(tag: Int) {
      if tag == 0 {
        identity_encoder_fn_selector
      } else if tag == 1 {
        fn(f_index: Int) {
          if f_index == 0 {
            integer |> contramap(builtin.un_i_data)
          } else {
            fail
          }
        }
      } else if tag == 2 {
        fn(f_index: Int) {
          if f_index <= 2 {
            integer |> contramap(builtin.un_i_data)
          } else {
            fail
          }
        }
      } else {
        fail
      }
    }

  // let color_encoder_factory =
  //   fn(_) {
  //     fn(_) {
  //       integer |> contramap(builtin.un_i_data)
  //     }
  //   }

  let color_encoder = make_sum(3, color_encoder_factory)
  let abyss = new |> color_encoder(Abyss)
  let black_and_white = new |> color_encoder(BlackAndWhite { white: 0 })
  let colored = new |> color_encoder(Colored { red: 0, green: 0, blue: 0 })
  trace abyss
  trace black_and_white
  trace colored
  and {
    abyss.buffer == #"",
    abyss.used_bits == 1,
    abyss.current_byte == #"00",
    black_and_white.buffer == #"80",
    black_and_white.used_bits == 2,
    black_and_white.current_byte == #"00",
    colored.buffer == #"c00000",
    colored.used_bits == 2,
    colored.current_byte == #"00",
  }
}
// }}}
