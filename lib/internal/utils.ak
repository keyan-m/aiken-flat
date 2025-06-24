pub fn zip_foldr(
  self: List<a>,
  bs: List<b>,
  acc: c,
  with: fn(a, b, c) -> c,
) -> c {
  when self is {
    [] -> acc
    [x, ..xs] ->
      when bs is {
        [] -> acc
        [y, ..ys] -> {
          let c = zip_foldr(xs, ys, acc, with)
          with(x, y, c)
        }
      }
  }
}
