///|
test "immutable snapshot lifecycle survives storage, patching and comparison" {
  let original_hashes = [101, 203, 307, 401, 509, 601]
  let original = VerifiedFuseFilter::build(original_hashes).unwrap()
  assert_true(original.validate())

  let stored_words = original.encode_words()
  let loaded = decode_verified_words(stored_words).unwrap()
  assert_true(loaded.validate())
  assert_eq(loaded.hashes(), original_hashes)

  let overlay = FuseOverlay::from_patch(loaded, {
    additions: [701, 809],
    removals: [203, 509],
  }).unwrap()
  assert_true(overlay.validate())
  assert_true(overlay.contains_exact(101))
  assert_false(overlay.contains_exact(203))
  assert_false(overlay.contains_exact(509))
  assert_true(overlay.contains_exact(701))
  assert_true(overlay.contains_exact(809))

  let snapshot = overlay.materialize().unwrap()
  assert_true(snapshot.validate())
  let expected = [101, 307, 401, 601, 701, 809]
  assert_eq(snapshot.hashes(), expected)

  let diff = original.diff(snapshot)
  assert_true(diff.validate())
  assert_eq(diff.additions, [701, 809])
  assert_eq(diff.removals, [203, 509])
  assert_eq(diff.shared_count, 4)
  assert_eq(diff.apply_to(original).unwrap().hashes(), expected)

  let portable_diff = decode_snapshot_diff_words(diff.encode_words()).unwrap()
  assert_eq(portable_diff.apply_to(original).unwrap().hashes(), expected)

  let map = StaticIntMap::build([
    { hash: 101, value: 1 },
    { hash: 307, value: 3 },
    { hash: 401, value: 4 },
    { hash: 601, value: 6 },
    { hash: 701, value: 7 },
    { hash: 809, value: 8 },
  ]).unwrap()
  assert_true(map.validate())
  assert_eq(map.get(701), Some(7))
  assert_eq(map.get(203), None)
  let map_loaded = decode_static_map_words(map.encode_words()).unwrap()
  assert_eq(map_loaded.get(809), Some(8))
}

///|
test "candidate inspection keeps invalid hashes outside the filter domain" {
  let filter = BinaryFuseFilter::build([17, 31, 47]).unwrap()
  assert_true(filter.has_valid_shape())
  assert_true(filter.candidate_locations(-7) is None)
  assert_eq(filter.slot_fingerprints(-7).length(), 0)
  assert_true(filter.candidate_xor(-7) is None)
  assert_false(filter.matches_fingerprint(-7))
  assert_false(filter.contains(-7))
  assert_eq(filter.fingerprint_stats().slot_count, filter.stats().array_length)
}
