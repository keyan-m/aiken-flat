use aiken/builtin
use aiken/fuzz
use aiken/primitive/bytearray

pub opaque type Integer {
  value: Int,
  size: Int,
}

pub fn equals(x: Integer, y: Integer) -> Bool {
  and {
    x.value == y.value,
    x.size == y.size,
  }
}

pub fn is_zero(x: Integer) -> Bool {
  x.value == 0
}

pub fn from_int(x: Int) -> Integer {
  Integer { value: x, size: do_find_byte_count(x, 1) }
}

pub fn to_int(x: Integer) -> Int {
  x.value
}

pub fn size(x: Integer) -> Int {
  x.size
}

pub fn to_word8(x: Integer) -> Int {
  x.value % 256
}

pub fn to_bytearray(x: Integer) -> ByteArray {
  x.value |> bytearray.from_int_big_endian(x.size)
}

pub fn shift_right(x: Integer, bit_count: Int) -> Integer {
  x
    |> to_bytearray
    |> builtin.shift_bytearray(-bit_count)
    |> builtin.bytearray_to_integer(True, _)
    |> from_int
}

/// Assumes x is positive, and finds the number of bytes needed to represent
/// given number, up to 32 bytes.
fn do_find_byte_count(x: Int, count_so_far: Int) -> Int {
  if x < 256 {
    count_so_far
  } else {
    do_find_byte_count(x / 256, count_so_far + 1)
  }
}

// {{{

/// Fuzzer
const max_1 = 255

const max_2 = 65535

const max_3 = 16777215

const max_4 = 4294967295

const max_5 = 1099511627775

const max_6 = 281474976710655

const max_7 = 72057594037927935

const max_8 = 18446744073709551615

const max_9 = 4722366482869645213695

const max_10 = 1208925819614629174706175

const max_11 = 309485009821345068724781055

const max_12 = 79228162514264337593543950335

const max_13 = 20282409603651670423947251286015

const max_14 = 5192296858534827628530496329220095

const max_15 = 1329227995784915872903807060280344575

const max_16 = 340282366920938463463374607431768211455

const max_17 = 87112285931760246646623899502532662132735

const max_18 = 22300745198530623141535718272648361505980415

const max_19 = 5708990770823839524233143877797980545530986495

const max_20 = 1461501637330902918203684832716283019655932542975

const max_21 = 374144419156711147060143317175368453031918731001855

const max_22 = 95780971304118053647396689196894323976171195136475135

const max_23 = 24519928653854221733733552434404946937899825954937634815

const max_24 = 6277101735386680763835789423207666416102355444464034512895

const max_25 = 1606938044258990275541962092341162602522202993782792835301375

const max_26 = 411376139330301510538742295639337626245683966408394965837152255

const max_27 =
  105312291668557186697918027683670432318895095400549111254310977535

const max_28 =
  26959946667150639794667015087019630673637144422540572481103610249215

const max_29 =
  6901746346790563787434755862277025452451108972170386555162524223799295

const max_30 =
  1766847064778384329583297500742918515827483896875618958121606201292619775

const max_31 =
  452312848583266388373324160190187140051835877600158453279131187530910662655

const max_32 =
  115792089237316195423570985008687907853269984665640564039457584007913129639935

/// Up to 32 bytes.
pub fn fuzzer_with_given_size(size: Int) -> Fuzzer<Integer> {
  if size <= 1 {
    let x <- fuzz.and_then(fuzz.int_between(0, max_1))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 2 {
    let x <- fuzz.and_then(fuzz.int_between(max_1 + 1, max_2))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 3 {
    let x <- fuzz.and_then(fuzz.int_between(max_2 + 1, max_3))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 4 {
    let x <- fuzz.and_then(fuzz.int_between(max_3 + 1, max_4))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 5 {
    let x <- fuzz.and_then(fuzz.int_between(max_4 + 1, max_5))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 6 {
    let x <- fuzz.and_then(fuzz.int_between(max_5 + 1, max_6))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 7 {
    let x <- fuzz.and_then(fuzz.int_between(max_6 + 1, max_7))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 8 {
    let x <- fuzz.and_then(fuzz.int_between(max_7 + 1, max_8))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 9 {
    let x <- fuzz.and_then(fuzz.int_between(max_8 + 1, max_9))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 10 {
    let x <- fuzz.and_then(fuzz.int_between(max_9 + 1, max_10))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 11 {
    let x <- fuzz.and_then(fuzz.int_between(max_10 + 1, max_11))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 12 {
    let x <- fuzz.and_then(fuzz.int_between(max_11 + 1, max_12))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 13 {
    let x <- fuzz.and_then(fuzz.int_between(max_12 + 1, max_13))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 14 {
    let x <- fuzz.and_then(fuzz.int_between(max_13 + 1, max_14))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 15 {
    let x <- fuzz.and_then(fuzz.int_between(max_14 + 1, max_15))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 16 {
    let x <- fuzz.and_then(fuzz.int_between(max_15 + 1, max_16))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 17 {
    let x <- fuzz.and_then(fuzz.int_between(max_16 + 1, max_17))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 18 {
    let x <- fuzz.and_then(fuzz.int_between(max_17 + 1, max_18))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 19 {
    let x <- fuzz.and_then(fuzz.int_between(max_18 + 1, max_19))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 20 {
    let x <- fuzz.and_then(fuzz.int_between(max_19 + 1, max_20))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 21 {
    let x <- fuzz.and_then(fuzz.int_between(max_20 + 1, max_21))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 22 {
    let x <- fuzz.and_then(fuzz.int_between(max_21 + 1, max_22))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 23 {
    let x <- fuzz.and_then(fuzz.int_between(max_22 + 1, max_23))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 24 {
    let x <- fuzz.and_then(fuzz.int_between(max_23 + 1, max_24))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 25 {
    let x <- fuzz.and_then(fuzz.int_between(max_24 + 1, max_25))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 26 {
    let x <- fuzz.and_then(fuzz.int_between(max_25 + 1, max_26))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 27 {
    let x <- fuzz.and_then(fuzz.int_between(max_26 + 1, max_27))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 28 {
    let x <- fuzz.and_then(fuzz.int_between(max_27 + 1, max_28))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 29 {
    let x <- fuzz.and_then(fuzz.int_between(max_28 + 1, max_29))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 30 {
    let x <- fuzz.and_then(fuzz.int_between(max_29 + 1, max_30))
    fuzz.constant(Integer { value: x, size })
  } else if size <= 31 {
    let x <- fuzz.and_then(fuzz.int_between(max_30 + 1, max_31))
    fuzz.constant(Integer { value: x, size })
  } else {
    let x <- fuzz.and_then(fuzz.int_between(max_31 + 1, max_32))
    fuzz.constant(Integer { value: x, size })
  }
}

pub fn fuzzer() -> Fuzzer<Integer> {
  let size <- fuzz.and_then(fuzz.int_between(1, 32))
  fuzzer_with_given_size(size)
}
// }}}
