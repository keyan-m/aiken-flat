# Aiken Flat Encoder and Decoder

Based on [Flat specs](http://quid2.org/docs/Flat.pdf), Haskell's
[`flat`](https://hackage.haskell.org/package/flat-0.6) and
[`pallas-codec` crate](https://github.com/txpipe/pallas/tree/main/pallas-codec).

## How to Define Encoders/Decoders for Custom Types

To enable the same encoding/decoding as off-chain tooling offers, this package
exposes generic encoder/decoder generator functions (thanks to `Data`).
Currently the interface has a lot of room for improvement, but this is primarily
a theoretical implementation at the moment.

Here I show how we can define Flat encoders and decoders for the two custom
types from tests.

### `Direction`
First, the datatype from the paper:
```aiken
pub type Direction {
  North
  South
  Center
  East
  West
}
```

#### Encoder
The primary helper we need here is `make_sum` (short for "make a sum type
encoder"):
```aiken
use aiken_flat/encoder as en

const direction_encoder: fn(en.Encoder, Direction) -> en.Encoder =
  en.make_sum(5, en.identity_encoder_fn_selector_factory)
    |> en.contramap(
        fn(c: Direction) -> Data {
          let d: Data = c
          d
        },
      )
```
The first argument is the number of constructors in the target sum type. The
second argument is more complex: it should be a function that given the index of
a constructor, returns another function that can be used for encoding the
values stored in the corresponding constructor.

Here however, none of the constructors carry values, so we can just use the
helper provided by `encoder`. We'll take a deeper look into this "selector" in
the next example.

The `en.contramap` is a sort of boilerplate that might be avoidable.

#### Decoder
The `decoder` module also has a `make_sum`:
```aiken
use aiken_flat/decoder as de

const direction_decoder =
  de.make_sum(5, de.identity_decoder_fn_selector_factory)
    |> de.map(
        fn(d: Data) -> Direction {
          expect c: Direction = d
          c
        },
      )
```
Quite similar to its encoder counterpart.

#### Flat

The two functions we defined are only capable of working with `Encoder` and
`Decoder` values, which are essentially "states" that carry a buffer for
tracking progress. They also don't use/consider "filler" bits.

To get the final Flat encoder/decoder functions, we must use the two other
makers from `aiken_flat/flat`:
```aiken
use aiken_flat/flat

const encode_direction: fn(Direction) -> ByteArray =
  flat.make_encoder(direction_encoder)

const decode_direction: fn(ByteArray) -> Direction =
  flat.make_decoder(direction_decoder)
```
As you can see, `Encoder` and `Decoder` are not involved anymore. These two will
also take care of incorporating filler bits.

### `Color`
For a custom type with values stored in some of its constructors, let's look at
another example:
```aiken
pub type Color {
  Abyss
  BlackAndWhite { white: Int }
  Colored { red: Int, green: Int, blue: Int }
}
```

#### Encoder

For record types, we must simply concatenate encoded fields in order. `make_sum`
therefore needs a way to know which encoder to use for each field of each
constructor.

So the second argument of `make_sum` is expected to be a function that first
takes the "tag index" of a constructor, and returns another function, which
itself takes the index of a value in the record type, and returns an encoder
function (`EncoderFn<a>`, which is an alias for `fn(Encoder, a) -> Encoder`).
```aiken
use aiken_flat/encoder as en

fn color_encoder_factory(tag: Int) -> fn(Int) -> en.EncoderFn<Data> {
  if tag == 0 {
    // `Abyss` has no values, so no encoder is needed.
    en.identity_encoder_fn_selector
  } else if tag == 1 {
    // `BlackAndWhite` carries a single `Int`, so the encoder function must only
    // encode the value at index `0` with `en.integer`.
    fn(f_index: Int) {
      if f_index == 0 {
        // Similar to `Direction` encoder above, This `contramap` boilerplate is
        // needed.
        en.integer |> en.contramap(builtin.un_i_data)
      } else {
        fail
      }
    }
  } else if tag == 2 {
    // Similarly, `Colored` carries three `Int` values. Since they are all of
    // the same type, we don't need to handle individual fields.
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
```

#### Decoder

The "factory" function for decoders is a bit more involved, as along with
decoder functions for each of the record types' fields, the factory also needs
to inform the outer decoder of the number of fields expected for a given
constructor.

But Aiken currently doesn't allow for functions to be wrapped under other
constructs (such as a `Pair`, which could be suitable here). Therefore, we must
use Scott encoding to provide the factory with a continuation.
```aiken
use aiken_flat/decoder as de

fn color_decoder_factory(
  tag: Int,
  return: Scott2<Int, fn(Int) -> de.DecoderFn<Data>, (Data, de.Decoder)>,
) -> (Data, de.Decoder) {
  if tag == 0 {
    // `Abyss` expects 0 values to be decoded after its tag bits.
    return(0, de.identity_decoder_fn_selector)
  } else if tag == 1 {
    // `BlackAndWhite` expects 1 integer to be decoded after its tag bits.
    return(1, fn(_) { de.integer |> de.map(builtin.i_data) })
  } else if tag == 2 {
    // Similartly, `Colored` expects 3 integers to be decoded after its tag
    // bits.
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
```

#### Flat

We can now use the encoder and decoder we just defined to have the final Flat
functions:
```aiken
use aiken_flat/flat

const encode_color = flat.make_encoder(color_encoder)

const decode_color = flat.make_decoder(color_decoder)
```

## Running Tests

Tests cover roundtrip tests for basic types, plus `Direction` and `Color` that
we just looked at.

1. (Optional) Run `aikup` to align your `aiken` version with the one stated in
   `aiken.toml` file here.
2. Run `aiken check`.
