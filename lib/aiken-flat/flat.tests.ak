use aiken/builtin
use aiken/fuzz
use aiken_flat/decoder as de
use aiken_flat/encoder as en
use aiken_flat/flat
use aiken_scott_utils/types.{Scott2}
use internal/test_utils.{Color, Direction, color_fuzzer, direction_fuzzer}
use internal/utils.{i128_max_bound, i128_min_bound}

test success__bool_roundtrip(b via fuzz.bool()) {
  let encoded = flat.encode_bool(b)
  let decoded = flat.decode_bool(encoded)
  trace encoded
  trace decoded
  decoded == b
}

test success__u8_roundtrip(byte via fuzz.bytearray_fixed(1)) {
  let encoded = flat.unsafe_encode_u8(byte)
  let decoded = flat.decode_u8(encoded)
  trace encoded
  trace decoded
  decoded == byte
}

test success__bytes_roundtrip(bytes via fuzz.bytearray_fixed(2550)) {
  let encoded = flat.encode_bytes(bytes)
  let decoded = flat.decode_bytes(encoded)
  trace encoded
  trace decoded
  decoded == bytes
}

test success__integer_roundtrip(
  integer via fuzz.int_between(i128_min_bound, i128_max_bound),
) {
  let encoded = flat.encode_integer(integer)
  let encoded_le = flat.encode_integer_le(integer)
  let decoded = flat.decode_integer(encoded)
  trace encoded
  trace encoded_le
  trace decoded
  decoded == integer
}

test success__i128_min_bound() {
  let encoded = flat.encode_integer(i128_min_bound)
  encoded == #"ffffffffffffffffffffffffffffffffffff0301"
}

test success__i128_min_bound_le() {
  let encoded = flat.encode_integer_le(i128_min_bound)
  encoded == #"ffffffffffffffffffffffffffffffffffff0301"
}

test success__i128_max_bound() {
  let encoded = flat.encode_integer(i128_max_bound)
  encoded == #"feffffffffffffffffffffffffffffffffff0301"
}

test success__i128_max_bound_le() {
  let encoded = flat.encode_integer_le(i128_max_bound)
  encoded == #"feffffffffffffffffffffffffffffffffff0301"
}

test success__255() {
  let encoded = flat.encode_integer(255)
  encoded == #"fe0301"
}

test success__255_le() {
  let encoded = flat.encode_integer_le(255)
  encoded == #"fe0301"
}

const direction_encoder =
  en.make_sum(5, en.identity_encoder_fn_selector_factory)

const direction_decoder =
  de.make_sum(5, de.identity_decoder_fn_selector_factory)
    |> de.map(
        fn(d: Data) -> Direction {
          expect c: Direction = d
          c
        },
      )

fn encode_direction(self: Direction) -> ByteArray {
  en.new |> direction_encoder(self) |> en.filler |> en.unwrap
}

fn decode_direction(bytes: ByteArray) -> Direction {
  de.new(bytes) |> direction_decoder |> de.unwrap
}

test success__direction_roundtrip(direction via direction_fuzzer()) {
  let encoded = encode_direction(direction)
  let decoded = decode_direction(encoded)
  trace encoded
  trace decoded
  decoded == direction
}

fn color_encoder_factory(tag: Int) {
  if tag == 0 {
    en.identity_encoder_fn_selector
  } else if tag == 1 {
    fn(f_index: Int) {
      if f_index == 0 {
        en.integer |> en.contramap(builtin.un_i_data)
      } else {
        fail
      }
    }
  } else if tag == 2 {
    fn(f_index: Int) {
      if f_index <= 2 {
        en.integer |> en.contramap(builtin.un_i_data)
      } else {
        fail
      }
    }
  } else {
    fail
  }
}

const color_encoder = en.make_sum(3, color_encoder_factory)

fn color_decoder_factory(
  tag: Int,
  return: Scott2<Int, fn(Int) -> de.DecoderFn<Data>, (Data, de.Decoder)>,
) -> (Data, de.Decoder) {
  if tag == 0 {
    return(0, de.identity_decoder_fn_selector)
  } else if tag == 1 {
    return(1, fn(_) { de.integer |> de.map(builtin.i_data) })
  } else if tag == 2 {
    return(3, fn(_) { de.integer |> de.map(builtin.i_data) })
  } else {
    fail
  }
}

const color_decoder =
  de.make_sum(3, color_decoder_factory)
    |> de.map(
        fn(d: Data) -> Color {
          expect c: Color = d
          c
        },
      )

fn encode_color(self: Color) -> ByteArray {
  en.new |> color_encoder(self) |> en.filler |> en.unwrap
}

fn decode_color(bytes: ByteArray) -> Color {
  de.new(bytes) |> color_decoder |> de.unwrap
}

test success__color_roundtrip(color via color_fuzzer()) {
  let encoded = encode_color(color)
  let decoded = decode_color(encoded)
  trace encoded
  trace decoded
  decoded == color
}
