///|
test "static string maps use exact keys after approximate prefiltering" {
  let map = StaticStringMap::build([
    { key: "accept", value: 202 },
    { key: "content-type", value: 415 },
    { key: "etag", value: 304 },
    { key: "x-request-id", value: 200 },
  ]).unwrap()
  assert_true(map.validate())
  assert_eq(map.len(), 4)
  assert_eq(map.get("accept"), Some(202))
  assert_eq(map.get("etag"), Some(304))
  assert_eq(map.get("missing"), None)
  assert_eq(map.get_all(["accept", "missing"]), [Some(202), None])
  assert_true(map.contains_key("content-type"))
  assert_false(map.contains_key("Content-Type"))
  assert_eq(map.stats().shortest_key_length, 4)
  assert_eq(map.stats().longest_key_length, 12)
}

///|
test "static string maps rebuild immutably for update and removal" {
  let original = StaticStringMap::build([
    { key: "a", value: 1 },
    { key: "b", value: 2 },
    { key: "d", value: 4 },
  ]).unwrap()
  let updated = original
    .with_updates([{ key: "b", value: 20 }, { key: "c", value: 3 }])
    .unwrap()
  assert_true(updated.validate())
  assert_eq(updated.get("a"), Some(1))
  assert_eq(updated.get("b"), Some(20))
  assert_eq(updated.get("c"), Some(3))
  assert_eq(updated.get("d"), Some(4))
  assert_eq(original.get("b"), Some(2))
  let trimmed = updated.without_keys(["a", "d"]).unwrap()
  assert_true(trimmed.validate())
  assert_eq(trimmed.len(), 2)
  assert_eq(trimmed.get("a"), None)
  assert_eq(trimmed.get("b"), Some(20))
  assert_true(StaticStringMap::build([]) is Err(EmptyInput))
  assert_true(
    StaticStringMap::build([
      { key: "same", value: 1 },
      { key: "same", value: 2 },
    ])
    is Err(DuplicateString("same")),
  )
}
