///|
fn spaced_hashes(size : Int, offset : Int) -> Array[Int] {
  let hashes = Array::make(size, 0)
  for index in 0..<size {
    hashes[index] = offset + index * 65_537
  }
  hashes
}

///|
test "all supported filter variants preserve members across a size matrix" {
  for size in [1, 2, 7, 15, 32, 63, 128, 255] {
    let hashes = spaced_hashes(size, size * 13 + 1)
    let eight = BinaryFuseFilter::build(hashes).unwrap()
    let sixteen = BinaryFuseFilter::build16(hashes).unwrap()
    assert_true(eight.has_valid_shape())
    assert_true(sixteen.has_valid_shape())
    assert_true(eight.validate(hashes))
    assert_true(sixteen.validate(hashes))
    for hash in hashes {
      assert_true(eight.matches_fingerprint(hash))
      assert_true(sixteen.matches_fingerprint(hash))
    }
  }
}

///|
test "filter codecs reject truncated, trailing and invalid-version data" {
  let filter = BinaryFuseFilter::build16(spaced_hashes(32, 19)).unwrap()
  let words = filter.encode_words()
  let truncated = Array::make(words.length() - 1, 0)
  for index in 0..<truncated.length() {
    truncated[index] = words[index]
  }
  assert_true(decode_words(truncated) is Err(InvalidEncoding))
  let trailing = words.copy()
  trailing.push(0)
  assert_true(decode_words(trailing) is Err(InvalidEncoding))
  let wrong_version = words.copy()
  wrong_version[0] = 999
  assert_true(decode_words(wrong_version) is Err(UnsupportedVersion(999)))
  let bad_bits = words.copy()
  bad_bits[6] = 12
  assert_true(decode_words(bad_bits) is Err(InvalidEncoding))
  let bad_length = words.copy()
  bad_length[7] = bad_length[7] + 1
  assert_true(decode_words(bad_length) is Err(InvalidEncoding))
}

///|
test "shards and tags agree with their unpartitioned source domain" {
  let hashes = spaced_hashes(180, 37)
  let sharded = ShardedFuseFilter::build(hashes, 11).unwrap()
  assert_true(sharded.validate(hashes))
  let entries : Array[TaggedHash] = []
  for index in 0..<hashes.length() {
    entries.push({ tag: index % 5, hash: hashes[index] })
  }
  let tagged = TaggedFuseFilter::build(entries).unwrap()
  assert_true(tagged.validate(entries))
  for index in 0..<hashes.length() {
    assert_true(sharded.contains(hashes[index]))
    assert_true(tagged.contains(index % 5, hashes[index]))
  }
  let sharded_loaded = decode_sharded_words(sharded.encode_words()).unwrap()
  let tagged_loaded = decode_tagged_words(tagged.encode_words()).unwrap()
  assert_true(sharded_loaded.validate(hashes))
  assert_true(tagged_loaded.validate(entries))
}

///|
test "static map updates have the same result as rebuilding the final entries" {
  let initial : Array[FuseValue] = []
  let updates : Array[FuseValue] = []
  let expected : Array[FuseValue] = []
  for index in 0..<80 {
    initial.push({ hash: index * 100 + 1, value: index })
    expected.push({ hash: index * 100 + 1, value: index })
  }
  for index in 0..<40 {
    updates.push({ hash: index * 200 + 1, value: index * 10 })
    expected[index * 2] = { hash: index * 200 + 1, value: index * 10 }
  }
  for index in 0..<20 {
    updates.push({ hash: 10_000 + index, value: 500 + index })
    expected.push({ hash: 10_000 + index, value: 500 + index })
  }
  let updated = StaticIntMap::build(initial)
    .unwrap()
    .with_updates(updates)
    .unwrap()
  let rebuilt = StaticIntMap::build(expected).unwrap()
  assert_true(updated.validate())
  assert_true(rebuilt.validate())
  for entry in expected {
    assert_eq(updated.get(entry.hash), Some(entry.value))
    assert_eq(rebuilt.get(entry.hash), Some(entry.value))
  }
  assert_eq(updated.len(), rebuilt.len())
}

///|
test "overlay materialization equals direct patching for independent patches" {
  let base_hashes = spaced_hashes(100, 3)
  let base = VerifiedFuseFilter::build(base_hashes).unwrap()
  let additions = [9_001, 9_002, 9_003, 9_004]
  let removals = [base_hashes[2], base_hashes[17], base_hashes[61]]
  let patch = { additions, removals }
  let overlay = FuseOverlay::from_patch(base, patch).unwrap()
  let direct = base.apply_patch(patch).unwrap()
  let materialized = overlay.materialize().unwrap()
  assert_true(overlay.validate())
  assert_eq(materialized.hashes(), direct.hashes())
  for hash in direct.hashes() {
    assert_true(overlay.contains_exact(hash))
  }
  for hash in removals {
    assert_false(overlay.contains_exact(hash))
  }
  let loaded = decode_overlay_words(overlay.encode_words()).unwrap()
  assert_eq(loaded.materialize().unwrap().hashes(), direct.hashes())
}

///|
test "diff direction and reversal preserve every target snapshot" {
  for size in [3, 7, 31, 79] {
    let source = VerifiedFuseFilter::build(spaced_hashes(size, 1)).unwrap()
    let target = VerifiedFuseFilter::build(spaced_hashes(size + 5, 50_000)).unwrap()
    let forward = source.diff(target)
    let backward = target.diff(source)
    assert_true(forward.validate())
    assert_true(backward.validate())
    assert_eq(forward.apply_to(source).unwrap().hashes(), target.hashes())
    assert_eq(backward.apply_to(target).unwrap().hashes(), source.hashes())
    assert_eq(forward.change_count(), backward.change_count())
    assert_eq(source.diff(source).change_count(), 0)
    assert_true(source.diff(source).is_empty())
  }
}

///|
test "epoch map lookup only falls back to a previous stored epoch" {
  let entries = [
    { epoch: 2, hash: 10, value: 20 },
    { epoch: 2, hash: 11, value: 21 },
    { epoch: 4, hash: 10, value: 40 },
    { epoch: 6, hash: 12, value: 60 },
  ]
  let map = EpochStaticIntMap::build(entries).unwrap()
  assert_eq(map.get_at_or_before(1, 10), None)
  assert_eq(map.get_at_or_before(2, 10), Some(20))
  assert_eq(map.get_at_or_before(3, 11), Some(21))
  assert_eq(map.get_at_or_before(4, 10), Some(40))
  assert_eq(map.get_at_or_before(5, 12), None)
  assert_eq(map.get_at_or_before(6, 12), Some(60))
  let words = map.encode_words()
  let trailing = words.copy()
  trailing.push(0)
  assert_true(decode_epoch_map_words(trailing) is Err(InvalidEncoding))
}
