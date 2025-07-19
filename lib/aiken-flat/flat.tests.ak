use aiken/builtin
use aiken/fuzz
use aiken_flat/decoder as de
use aiken_flat/encoder as en
use aiken_flat/flat
use aiken_scott_utils/types.{Scott2}
use internal/test_utils.{Color, Direction, color_fuzzer, direction_fuzzer}
use internal/utils.{
  i128_max_bound, i128_min_bound, i16_max_bound, i16_min_bound, i32_max_bound,
  i32_min_bound, i64_max_bound, i64_min_bound, i8_max_bound, i8_min_bound,
}

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

const thirty_two_bytes = 256 * 32

test success__bytes_roundtrip(bytes via fuzz.bytearray_fixed(thirty_two_bytes)) {
  let encoded = flat.encode_bytes(bytes)
  let decoded = flat.decode_bytes(encoded)
  trace encoded
  trace decoded
  decoded == bytes
}

fn validate_integer_roundtrip(integer: Int) -> Bool {
  let encoded = flat.encode_integer(integer)
  let decoded = flat.decode_integer(encoded)
  trace encoded
  trace decoded
  decoded == integer
}

test success__integer_roundtrip_i8(
  integer via fuzz.int_between(i8_min_bound, i8_max_bound),
) {
  validate_integer_roundtrip(integer)
}

test success__integer_roundtrip_i16(
  integer via fuzz.int_between(i16_min_bound, i16_max_bound),
) {
  validate_integer_roundtrip(integer)
}

test success__integer_roundtrip_i32(
  integer via fuzz.int_between(i32_min_bound, i32_max_bound),
) {
  validate_integer_roundtrip(integer)
}

test success__integer_roundtrip_i64(
  integer via fuzz.int_between(i64_min_bound, i64_max_bound),
) {
  validate_integer_roundtrip(integer)
}

test success__integer_roundtrip_i128(
  integer via fuzz.int_between(i128_min_bound, i128_max_bound),
) {
  validate_integer_roundtrip(integer)
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

const encode_direction: fn(Direction) -> ByteArray =
  flat.make_encoder(direction_encoder)

const decode_direction: fn(ByteArray) -> Direction =
  flat.make_decoder(direction_decoder)

test success__direction_roundtrip(direction via direction_fuzzer()) {
  let encoded = encode_direction(direction)
  let decoded = decode_direction(encoded)
  trace encoded
  trace decoded
  decoded == direction
}

fn color_encoder_factory(tag: Int) -> fn(Int) -> en.EncoderFn<Data> {
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

const encode_color = flat.make_encoder(color_encoder)

const decode_color = flat.make_decoder(color_decoder)

test success__color_roundtrip(color via color_fuzzer()) {
  let encoded = encode_color(color)
  let decoded = decode_color(encoded)
  trace encoded
  trace decoded
  decoded == color
}
