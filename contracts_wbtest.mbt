///|
test "string hashing is stable and string filters reject repeated keys" {
  assert_eq(stable_string_hash("moonbit"), stable_string_hash("moonbit"))
  assert_true(stable_string_hash("moonbit") >= 0)
  let filter = StringFuseFilter::build(["alpha", "beta", "gamma"]).unwrap()
  assert_true(filter.contains("alpha"))
  assert_true(filter.contains("beta"))
  assert_true(filter.contains("gamma"))
  assert_eq(filter.len(), 3)
  assert_true(StringFuseFilter::build([]) is Err(EmptyInput))
  assert_true(
    StringFuseFilter::build(["same", "same"]) is Err(DuplicateHash(_)),
  )
}

///|
test "static map construction validates keys and has immutable no-op updates" {
  assert_true(StaticIntMap::build([]) is Err(EmptyInput))
  assert_true(
    StaticIntMap::build([{ hash: -2, value: 9 }]) is Err(NegativeHash(-2)),
  )
  assert_true(
    StaticIntMap::build([{ hash: 4, value: 1 }, { hash: 4, value: 2 }])
    is Err(DuplicateHash(4)),
  )
  let map = StaticIntMap::build([{ hash: 4, value: 1 }]).unwrap()
  let copied = map.with_updates([]).unwrap()
  assert_true(copied.validate())
  assert_eq(copied.entries().length(), 1)
  assert_eq(copied.get(4), Some(1))
  assert_true(
    map.with_updates([{ hash: 4, value: 1 }, { hash: 4, value: 2 }])
    is Err(DuplicateHash(4)),
  )
  assert_true(map.without_keys([4]) is Err(EmptyInput))
}

///|
test "verified patch semantics reject invalid source and preserve unchanged keys" {
  let source = VerifiedFuseFilter::build([3, 5, 7, 11]).unwrap()
  let unchanged = source.apply_patch({ additions: [], removals: [] }).unwrap()
  assert_eq(unchanged.hashes(), source.hashes())
  let changed = source.apply_patch({ additions: [13], removals: [5] }).unwrap()
  assert_true(changed.contains_exact(3))
  assert_false(changed.contains_exact(5))
  assert_true(changed.contains_exact(13))
  assert_true(
    source.apply_patch({ additions: [-1], removals: [] })
    is Err(NegativeHash(-1)),
  )
  assert_true(
    source.apply_patch({ additions: [13, 13], removals: [] })
    is Err(DuplicateHash(13)),
  )
}

///|
test "overlay admits empty sides and does not turn probable matches into exact ones" {
  let base = VerifiedFuseFilter::build([100, 200, 300]).unwrap()
  let additions_only = FuseOverlay::from_patch(base, {
    additions: [400],
    removals: [],
  }).unwrap()
  let removals_only = FuseOverlay::from_patch(base, {
    additions: [],
    removals: [200],
  }).unwrap()
  assert_eq(additions_only.stats().removal_count, 0)
  assert_eq(removals_only.stats().addition_count, 0)
  assert_true(additions_only.contains_exact(400))
  assert_false(removals_only.contains_exact(200))
  assert_true(removals_only.may_contain(200))
  assert_false(removals_only.contains_exact(999))
}

///|
test "epoch domains retain independent keys and report empty construction" {
  assert_true(EpochFuseFilter::build([]) is Err(EmptyInput))
  assert_true(EpochStaticIntMap::build([]) is Err(EmptyInput))
  let filter = EpochFuseFilter::build([
    { epoch: -1, hash: 1 },
    { epoch: 0, hash: 1 },
  ]).unwrap()
  assert_true(filter.contains_at(-1, 1))
  assert_true(filter.contains_at(0, 1))
  assert_false(filter.contains_at(1, 1))
  assert_eq(filter.keep_from(1).epoch_count(), 0)
  let map = EpochStaticIntMap::build([
    { epoch: -1, hash: 1, value: 10 },
    { epoch: 0, hash: 1, value: 20 },
  ]).unwrap()
  assert_eq(map.get_at(-1, 1), Some(10))
  assert_eq(map.get_at(0, 1), Some(20))
  assert_eq(map.keep_from(1).epoch_count(), 0)
}

///|
test "query summaries count every request including invalid hashes" {
  let filter = BinaryFuseFilter::build([2, 4, 6, 8]).unwrap()
  let summary = filter.query_all([2, 4, -1, 999])
  assert_eq(summary.query_count, 4)
  assert_true(summary.positive_count >= 2)
  assert_eq(summary.positive_count + summary.negative_count, 4)
  assert_false(filter.contains(-1))
  assert_false(filter.contains_all([2, -1]))
  assert_eq(filter.count_matches([2, 4, -1]), 2)
}

///|
test "quality reports distinguish source from unrelated probes" {
  let source = spaced_hashes(48, 1)
  let probes = spaced_hashes(48, 2)
  let filter = BinaryFuseFilter::build16(source).unwrap()
  let report = filter.evaluate(source, probes).unwrap()
  assert_eq(report.source_count, 48)
  assert_eq(report.probe_count, 48)
  assert_eq(report.false_negative_count, 0)
  assert_eq(report.negative_probe_count, 48)
  assert_true(report.false_positive_count >= 0)
  assert_eq(filter.fingerprint_denominator(), 65_536)
}
