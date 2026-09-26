///|
test "binary fuse 8 has no false negatives" {
  let hashes = Array::make(512, 0)
  for index in 0..<hashes.length() {
    hashes[index] = index * 7919 + 17
  }
  let filter = BinaryFuseFilter::build(hashes).unwrap()
  assert_true(filter.validate(hashes))
  for hash in hashes {
    assert_true(filter.contains(hash))
  }
}

///|
test "binary fuse 16 is deterministic" {
  let hashes = [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]
  let first = BinaryFuseFilter::build16(hashes).unwrap()
  let second = BinaryFuseFilter::build16(hashes).unwrap()
  assert_eq(first.stats().seed, second.stats().seed)
  assert_eq(first.stats().array_length, second.stats().array_length)
  assert_true(first.validate(hashes))
}

///|
test "construction rejects invalid inputs" {
  assert_true(BinaryFuseFilter::build([]) is Err(EmptyInput))
  assert_true(BinaryFuseFilter::build([1, -1]) is Err(NegativeHash(-1)))
  assert_true(BinaryFuseFilter::build([1, 1]) is Err(DuplicateHash(1)))
  assert_true(
    BinaryFuseFilter::build_with_options([1], {
      fingerprint_bits: 7,
      max_attempts: 1,
      initial_seed: 0,
    })
    is Err(InvalidFingerprintBits(7)),
  )
}

///|
test "word encoding round trips and rejects damage" {
  let hashes = [3, 8, 14, 22, 37, 59, 91]
  let original = BinaryFuseFilter::build16(hashes).unwrap()
  let loaded = decode_words(original.encode_words()).unwrap()
  assert_true(loaded.validate(hashes))
  let damaged = original.encode_words()
  damaged[7] = damaged[7] + 1
  assert_true(decode_words(damaged) is Err(InvalidEncoding))
}

///|
test "string adapter and batch queries" {
  let strings = ["GET", "POST", "PATCH", "DELETE"]
  let filter = StringFuseFilter::build16(strings).unwrap()
  for value in strings {
    assert_true(filter.contains(value))
  }
  let hashes = [
    stable_string_hash("GET"),
    stable_string_hash("POST"),
    stable_string_hash("MISS"),
  ]
  let report = filter.filter.query_all(hashes)
  assert_eq(report.query_count, 3)
  assert_true(report.positive_count >= 2)
  assert_true(
    filter.filter.contains_all([
      stable_string_hash("GET"),
      stable_string_hash("POST"),
    ]),
  )
}

///|
test "sharded filters retain every source hash" {
  let hashes = Array::make(300, 0)
  for index in 0..<hashes.length() {
    hashes[index] = index * 4099 + 13
  }
  let filter = ShardedFuseFilter::build(hashes, 7).unwrap()
  assert_true(filter.validate(hashes))
  assert_eq(filter.stats().shard_count, 7)
  assert_true(filter.stats().populated_shards > 1)
  assert_true(ShardedFuseFilter::build(hashes, 0) is Err(InvalidShardCount(0)))
}

///|
test "filter chain accepts members of each immutable batch" {
  let first = BinaryFuseFilter::build([11, 22, 33]).unwrap()
  let second = BinaryFuseFilter::build16([44, 55, 66]).unwrap()
  let chain = FuseFilterChain::from_filters([first, second])
  assert_eq(chain.filter_count(), 2)
  assert_eq(chain.key_count(), 6)
  assert_true(chain.contains(11))
  assert_true(chain.contains(66))
  assert_eq(chain.query_all([11, 66]).positive_count, 2)
}

///|
test "nested codecs preserve sharded and chained membership" {
  let hashes = [17, 31, 47, 61, 79, 97, 113, 131]
  let sharded = ShardedFuseFilter::build(hashes, 3).unwrap()
  let decoded_sharded = decode_sharded_words(sharded.encode_words()).unwrap()
  assert_true(decoded_sharded.validate(hashes))
  let chain = FuseFilterChain::from_filters([
    BinaryFuseFilter::build([17, 31]).unwrap(),
    BinaryFuseFilter::build16([47, 61]).unwrap(),
  ])
  let decoded_chain = decode_chain_words(chain.encode_words()).unwrap()
  assert_true(decoded_chain.contains(17))
  assert_true(decoded_chain.contains(61))
}

///|
test "quality report detects no source false negatives" {
  let source = Array::make(200, 0)
  let probes = Array::make(400, 0)
  for index in 0..<source.length() {
    source[index] = index * 6151 + 7
  }
  for index in 0..<probes.length() {
    probes[index] = index * 6151 + 8
  }
  let filter = BinaryFuseFilter::build16(source).unwrap()
  let report = filter.evaluate(source, probes).unwrap()
  assert_eq(report.false_negative_count, 0)
  assert_eq(report.negative_probe_count, probes.length())
  assert_eq(filter.expected_false_positive_denominator(), 65_536)
  assert_true(filter.bits_per_key_milli() > 0)
}

///|
test "builder validates inputs and delegates construction" {
  let builder = FuseBuilder::with_capacity(4)
  assert_true(builder.add_all([5, 9, 15, 21]) is Ok(_))
  assert_eq(builder.len(), 4)
  let filter = builder.build().unwrap()
  assert_true(filter.contains_all([5, 9, 15, 21]))
  builder.clear()
  assert_eq(builder.len(), 0)
  assert_true(builder.add(-1) is Err(NegativeHash(-1)))
}

///|
test "verified filter eliminates approximate false positives" {
  let verified = VerifiedFuseFilter::build([7, 13, 29, 47, 71]).unwrap()
  assert_true(verified.validate())
  assert_true(verified.may_contain(29))
  assert_true(verified.contains_exact(29))
  assert_false(verified.contains_exact(30))
  let updated = verified
    .apply_patch({ additions: [83], removals: [13] })
    .unwrap()
  assert_true(updated.contains_exact(83))
  assert_false(updated.contains_exact(13))
}

///|
test "verified snapshots support set algebra and checked storage" {
  let left = VerifiedFuseFilter::build([2, 3, 5, 7, 11]).unwrap()
  let right = VerifiedFuseFilter::build([5, 7, 13, 17]).unwrap()
  let union = left.union(right).unwrap()
  assert_true(union.contains_exact(17))
  assert_eq(union.len(), 7)
  let common = left.intersection(right).unwrap()
  assert_eq(common.hashes(), [5, 7])
  let remaining = left.difference(right).unwrap()
  assert_eq(remaining.hashes(), [2, 3, 11])
  let changed = left.symmetric_difference(right).unwrap()
  assert_eq(changed.hashes(), [2, 3, 11, 13, 17])
  let loaded = decode_verified_words(left.encode_words()).unwrap()
  assert_true(loaded.validate())
  assert_true(loaded.contains_exact(11))
}

///|
test "epoch filters isolate windows and support expiry" {
  let entries = [
    { epoch: 10, hash: 101 },
    { epoch: 10, hash: 103 },
    { epoch: 11, hash: 211 },
    { epoch: 12, hash: 307 },
  ]
  let filter = EpochFuseFilter::build(entries).unwrap()
  assert_true(filter.validate(entries))
  assert_true(filter.contains_at(10, 101))
  assert_false(filter.contains_at(11, 101))
  assert_true(filter.contains_any(307))
  assert_eq(filter.stats().epoch_count, 3)
  let retained = filter.keep_from(11)
  assert_eq(retained.epoch_count(), 2)
  assert_false(retained.contains_at(10, 101))
  let loaded = decode_epoch_words(filter.encode_words()).unwrap()
  assert_true(loaded.validate(entries))
}

///|
test "tagged filters isolate namespaces and round trip" {
  let entries = [
    { tag: 3, hash: 101 },
    { tag: 3, hash: 103 },
    { tag: 7, hash: 101 },
    { tag: 7, hash: 211 },
    { tag: 12, hash: 307 },
  ]
  let filter = TaggedFuseFilter::build(entries).unwrap()
  assert_true(filter.validate(entries))
  assert_eq(filter.tag_count(), 3)
  assert_eq(filter.key_count(), 5)
  assert_true(filter.contains(3, 101))
  assert_true(filter.contains(7, 101))
  assert_false(filter.contains(3, 211))
  assert_false(filter.contains(1, 101))
  assert_eq(filter.stats().smallest_tag, 3)
  assert_eq(filter.stats().largest_tag, 12)
  let loaded = decode_tagged_words(filter.encode_words()).unwrap()
  assert_true(loaded.validate(entries))
  assert_true(
    TaggedFuseFilter::build([{ tag: -1, hash: 1 }]) is Err(InvalidTag(-1)),
  )
}

///|
test "static integer maps combine exact lookup with fuse rejection" {
  let map = StaticIntMap::build([
    { hash: 301, value: 9 },
    { hash: 101, value: 1 },
    { hash: 211, value: 4 },
  ]).unwrap()
  assert_true(map.validate())
  assert_eq(map.get(101), Some(1))
  assert_eq(map.get(211), Some(4))
  assert_eq(map.get(999), None)
  assert_eq(map.get_all([301, 999]), [Some(9), None])
  assert_eq(map.stats().smallest_key, 101)
  let revised = map
    .with_updates([{ hash: 211, value: 8 }, { hash: 401, value: 16 }])
    .unwrap()
  assert_eq(revised.get(211), Some(8))
  assert_eq(revised.get(401), Some(16))
  let trimmed = revised.without_keys([101, 401]).unwrap()
  assert_eq(trimmed.len(), 2)
  assert_eq(trimmed.get(211), Some(8))
  assert_eq(trimmed.get(301), Some(9))
  assert_eq(trimmed.get(101), None)
  let loaded = decode_static_map_words(revised.encode_words()).unwrap()
  assert_true(loaded.validate())
  assert_eq(loaded.get(401), Some(16))
}

///|
test "overlays apply checked patches without rebuilding their base" {
  let base = VerifiedFuseFilter::build([10, 20, 30, 40]).unwrap()
  let overlay = FuseOverlay::from_patch(base, {
    additions: [50, 60],
    removals: [20],
  }).unwrap()
  assert_true(overlay.validate())
  assert_true(overlay.contains_exact(10))
  assert_false(overlay.contains_exact(20))
  assert_true(overlay.contains_exact(50))
  assert_false(overlay.contains_exact(99))
  assert_eq(overlay.stats().addition_count, 2)
  assert_eq(overlay.stats().removal_count, 1)
  let snapshot = overlay.materialize().unwrap()
  assert_eq(snapshot.hashes(), [10, 30, 40, 50, 60])
  let loaded = decode_overlay_words(overlay.encode_words()).unwrap()
  assert_true(loaded.validate())
  assert_true(loaded.contains_exact(60))
  assert_false(loaded.contains_exact(20))
  assert_true(
    FuseOverlay::from_patch(snapshot, { additions: [70], removals: [70] })
    is Err(DuplicateHash(70)),
  )
}

///|
test "inspection exposes the exact candidate slots used by membership" {
  let hashes = [17, 43, 71, 101, 131, 163]
  let filter = BinaryFuseFilter::build16(hashes).unwrap()
  assert_true(filter.has_valid_shape())
  let locations = filter.candidate_locations(71).unwrap()
  assert_true(locations.first != locations.second)
  assert_true(locations.second != locations.third)
  assert_eq(filter.slot_fingerprints(71).length(), 3)
  assert_true(filter.matches_fingerprint(71))
  assert_true(filter.candidate_locations(-1) is None)
  assert_eq(filter.slot_fingerprints(-1), [])
  let stats = filter.fingerprint_stats()
  assert_eq(stats.slot_count, filter.stats().array_length)
  assert_eq(stats.slot_count, stats.occupied_slots + stats.empty_slots)
  assert_true(stats.maximum_fingerprint < 65_536)
}

///|
test "epoch static maps retain values by version and encode stably" {
  let entries = [
    { epoch: 1, hash: 10, value: 100 },
    { epoch: 1, hash: 20, value: 200 },
    { epoch: 3, hash: 10, value: 300 },
    { epoch: 3, hash: 30, value: 900 },
    { epoch: 5, hash: 20, value: 500 },
  ]
  let map = EpochStaticIntMap::build(entries).unwrap()
  assert_true(map.validate())
  assert_eq(map.get_at(1, 10), Some(100))
  assert_eq(map.get_at(3, 10), Some(300))
  assert_eq(map.get_at(2, 10), None)
  assert_eq(map.get_at_or_before(4, 10), Some(300))
  assert_eq(map.get_at_or_before(4, 20), None)
  assert_eq(map.epoch_count(), 3)
  assert_eq(map.entry_count(), 5)
  let retained = map.keep_from(3)
  assert_eq(retained.epoch_count(), 2)
  assert_eq(retained.get_at(1, 10), None)
  let loaded = decode_epoch_map_words(map.encode_words()).unwrap()
  assert_true(loaded.validate())
  assert_eq(loaded.get_at(5, 20), Some(500))
}

///|
test "static map algebra makes conflict handling explicit" {
  let left = StaticIntMap::build([
    { hash: 10, value: 1 },
    { hash: 20, value: 2 },
    { hash: 40, value: 4 },
  ]).unwrap()
  let right = StaticIntMap::build([
    { hash: 20, value: 9 },
    { hash: 30, value: 3 },
    { hash: 40, value: 4 },
  ]).unwrap()
  let stats = left.merge_stats(right)
  assert_eq(stats.left_only_count, 1)
  assert_eq(stats.right_only_count, 1)
  assert_eq(stats.shared_count, 2)
  assert_eq(stats.conflicting_count, 1)
  let left_wins = left.merge(right, PreferLeft).unwrap()
  assert_eq(left_wins.get(20), Some(2))
  assert_eq(left_wins.get(30), Some(3))
  let right_wins = left.merge(right, PreferRight).unwrap()
  assert_eq(right_wins.get(20), Some(9))
  assert_true(left.merge(right, RejectConflicts) is Err(ConflictingValue(20)))
  let shared = left.intersection(right, PreferRight).unwrap()
  assert_eq(shared.len(), 2)
  assert_eq(shared.get(20), Some(9))
  let only_left = left.difference(right).unwrap()
  assert_eq(only_left.len(), 1)
  assert_eq(only_left.get(10), Some(1))
}

///|
test "snapshot diffs are stable, validated and directly applicable" {
  let source = VerifiedFuseFilter::build([10, 20, 30, 40]).unwrap()
  let target = VerifiedFuseFilter::build([10, 30, 50, 60]).unwrap()
  let diff = source.diff(target)
  assert_true(diff.validate())
  assert_false(diff.is_empty())
  assert_eq(diff.change_count(), 4)
  assert_eq(diff.shared_count, 2)
  let rebuilt = diff.apply_to(source).unwrap()
  assert_eq(rebuilt.hashes(), target.hashes())
  let loaded = decode_snapshot_diff_words(diff.encode_words()).unwrap()
  assert_true(loaded.validate())
  assert_eq(loaded.change_count(), 4)
  assert_true(
    decode_snapshot_diff_words([81, 1, 1, 0, 7, 7]) is Err(InvalidEncoding),
  )
}

///|
test "batch classification keeps probability and exactness separate" {
  let source = [11, 23, 37, 53, 71]
  let filter = BinaryFuseFilter::build(source).unwrap()
  let verified = VerifiedFuseFilter::build(source).unwrap()
  let possible = filter.classify([11, 12, 23, 24])
  assert_eq(possible.length(), 4)
  assert_true(possible[0].might_contain)
  assert_true(possible[2].might_contain)
  assert_eq(filter.count_matches(source), source.length())
  let exact = verified.classify_exact([11, 12, 23, 24])
  assert_true(exact[0].contains)
  assert_false(exact[1].contains)
  assert_eq(verified.count_exact_matches([11, 12, 23, 24]), 2)
}
