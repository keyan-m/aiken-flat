# Aiken Flat Encoder and Decoder

Based on [Flat specs](http://quid2.org/docs/Flat.pdf), Haskell's
[`flat`](https://hackage.haskell.org/package/flat-0.6) and
[`pallas-codec` crate](https://github.com/txpipe/pallas/tree/main/pallas-codec).

## How to Define Encoders/Decoders for Custom Types

To enable the same encoding/decoding as off-chain tooling offers, this package
exposes generic encoder/decoder generator functions (thanks to `Data`).
Currently the interface has a lot of room for improvement, but this is primarily
because of how Aiken doesn't allow functions to be passed along in other
constructs (such as pairs and lists), as they can't be encoded to `Data`.

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

const direction_encoder =
  en.make_sum(5, en.identity_encoder_fn_selector_factory)
```
The first argument is the number of constructors in the target sum type. The
second argument is more complex: it should be a function that given the index of
a constructors, returns another function that can be used for encoding the
values stored in the corresponding constructor.

Here however, none of the constructors carry values, so we can just use the
helper provided by `encode`. We'll take a deeper look into this "selector" in
the next example.

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
Other than the difference in module, here we also need to add a mapping function
to coerce the decoded `Data` to our target type.

#### Flat
The two functions we defined are only capable of working with `Encoder` and
`Decoder` values, which are essentially "states" that carry a buffer for
tracking progress.

To get the final Flat encoder/decoder functions, we must use the two other
makers from `aiken_flat/flat`:
```aiken
use aiken_flat/flat

const encode_direction: fn(Direction) -> ByteArray =
  flat.make_encoder(direction_encoder)

const decode_direction: fn(ByteArray) -> Direction =
  flat.make_decoder(direction_decoder)
```
As you can see, `Encoder` and `Decoder` are not involved anymore. Also, these
two also take care of incorporating "filler" bits.

### `Color`
For a custom type with values stored in some of its constructors, let's contrive
another example!
```aiken
pub type Color {
  Abyss
  BlackAndWhite { white: Int }
  Colored { red: Int, green: Int, blue: Int }
}
```

#### Encoder

Flat encoding simply concatenates encoded values in record types. `make_sum`
therefore needs a way to know which encoder to use for each field of each
constructor.

So the second argument of `make_sum` is expected to be a function that first
takes the "tag index" of a constructor, and returns another function, which
itself takes the index of a value in the record type, and returns an encoder
function (`EncoderFn<a>`).
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
        // This `contramap` is something that might be possible to avoid with
        // better typing.
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
```
