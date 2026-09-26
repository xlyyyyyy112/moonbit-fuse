///|
test "construction options enforce bounded deterministic attempts" {
  let hashes = spaced_hashes(40, 101)
  let options = { fingerprint_bits: 8, max_attempts: 96, initial_seed: 77 }
  let first = BinaryFuseFilter::build_with_options(hashes, options).unwrap()
  let second = BinaryFuseFilter::build_with_options(hashes, options).unwrap()
  assert_eq(first.encode_words(), second.encode_words())
  assert_true(first.stats().attempts >= 1)
  assert_true(first.stats().attempts <= 96)
  assert_true(
    BinaryFuseFilter::build_with_options(hashes, {
      fingerprint_bits: 8,
      max_attempts: 0,
      initial_seed: 0,
    })
    is Err(InvalidAttempts(0)),
  )
  assert_true(
    BinaryFuseFilter::build_with_options(hashes, {
      fingerprint_bits: 24,
      max_attempts: 1,
      initial_seed: 0,
    })
    is Err(InvalidFingerprintBits(24)),
  )
}

///|
test "filter chains retain batch boundaries without losing query coverage" {
  let first = BinaryFuseFilter::build([1, 3, 5, 7]).unwrap()
  let second = BinaryFuseFilter::build16([2, 4, 6, 8]).unwrap()
  let third = BinaryFuseFilter::build([10, 20, 30]).unwrap()
  let chain = FuseFilterChain::from_filters([first, second, third])
  assert_eq(chain.filter_count(), 3)
  assert_eq(chain.key_count(), 11)
  for hash in [1, 2, 3, 4, 5, 6, 7, 8, 10, 20, 30] {
    assert_true(chain.contains(hash))
  }
  assert_eq(chain.query_all([1, 2, 30]).positive_count, 3)
  let words = chain.encode_words()
  assert_true(decode_chain_words(words).unwrap().contains(20))
}

///|
test "identical static-map values never conflict under strict merge" {
  let left = StaticIntMap::build([
    { hash: 1, value: 10 },
    { hash: 2, value: 20 },
  ]).unwrap()
  let right = StaticIntMap::build([
    { hash: 2, value: 20 },
    { hash: 3, value: 30 },
  ]).unwrap()
  let merged = left.merge(right, RejectConflicts).unwrap()
  assert_true(merged.validate())
  assert_eq(merged.len(), 3)
  assert_eq(merged.get(1), Some(10))
  assert_eq(merged.get(2), Some(20))
  assert_eq(merged.get(3), Some(30))
  let shared = left.intersection(right, RejectConflicts).unwrap()
  assert_eq(shared.len(), 1)
  assert_eq(shared.get(2), Some(20))
}

///|
test "top-level codecs fail fast for foreign versions" {
  assert_true(decode_sharded_words([0, 1]) is Err(InvalidEncoding))
  assert_true(decode_chain_words([0, 0]) is Err(InvalidEncoding))
  assert_true(decode_epoch_words([0, 1]) is Err(InvalidEncoding))
  assert_true(decode_tagged_words([0, 1]) is Err(InvalidEncoding))
  assert_true(decode_static_map_words([0, 1, 1]) is Err(InvalidEncoding))
  assert_true(decode_overlay_words([0, 1, 1]) is Err(InvalidEncoding))
  assert_true(decode_epoch_map_words([0, 1]) is Err(InvalidEncoding))
  assert_true(decode_snapshot_diff_words([0, 0, 0, 0]) is Err(InvalidEncoding))
}
