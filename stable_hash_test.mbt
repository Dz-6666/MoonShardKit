///|
test "stable hash has fixed vectors" {
  assert_eq(@moonshardkit.stable_hash(""), 2166136261U)
  assert_eq(@moonshardkit.stable_hash("moon"), 2274959374U)
  assert_eq(@moonshardkit.stable_hash("Moon"), 1719275566U)
}

///|
test "stable hash is sensitive to boundaries" {
  assert_true(
    @moonshardkit.placement_score("ab", "c", "x") !=
    @moonshardkit.placement_score("a", "bc", "x"),
  )
}

///|
test "virtual positions vary by replica and seed" {
  let first = @moonshardkit.virtual_position("node-a", 0, 7U)
  assert_true(first != @moonshardkit.virtual_position("node-a", 1, 7U))
  assert_true(first != @moonshardkit.virtual_position("node-a", 0, 8U))
}

///|
test "long input remains deterministic" {
  let builder = StringBuilder()
  for index = 0; index < 20000; index = index + 1 {
    builder.write_char('x')
  }
  let text = builder.to_string()
  assert_eq(@moonshardkit.stable_hash(text), @moonshardkit.stable_hash(text))
}
