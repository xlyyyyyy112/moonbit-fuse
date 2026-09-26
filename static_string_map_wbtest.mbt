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
test "string filters honor caller build options" {
  let options : BuildOptions = {
    fingerprint_bits: 16,
    max_attempts: 16,
    initial_seed: 42,
  }
  let filter = StringFuseFilter::build_with_options(
    ["alpha", "beta", "gamma", "delta"],
    options,
  ).unwrap()
  assert_true(filter.contains("alpha"))
  assert_true(filter.contains("delta"))
  assert_true(filter.stats().fingerprint_bits == 16)
  assert_true(
    StringFuseFilter::build_with_options(["alpha"], {
      fingerprint_bits: 7,
      max_attempts: 1,
      initial_seed: 0,
    })
    is Err(InvalidFingerprintBits(7)),
  )
}

///|
test "static string maps can select fingerprint and seed options" {
  let options : BuildOptions = {
    fingerprint_bits: 16,
    max_attempts: 16,
    initial_seed: 99,
  }
  let map = StaticStringMap::build_with_options(
    [
      { key: "accept", value: 202 },
      { key: "content-type", value: 415 },
      { key: "etag", value: 304 },
    ],
    options,
  ).unwrap()
  assert_true(map.validate())
  assert_eq(map.get("content-type"), Some(415))
  assert_eq(map.get("missing"), None)
  assert_eq(map.filter_stats().fingerprint_bits, 16)
  assert_true(
    map.filter_stats().seed !=
    StringFuseFilter::build(["accept", "content-type", "etag"]).unwrap().stats().seed,
  )
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
