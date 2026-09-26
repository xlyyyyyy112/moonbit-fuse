///|
fn mutate_word(words : Array[Int], index : Int, value : Int) -> Array[Int] {
  let copy = words.copy()
  copy[index] = value
  copy
}

///|
test "composite codecs retain all member types after nesting" {
  let hashes = [101, 103, 107, 109, 113, 127, 131, 137]
  let sharded = ShardedFuseFilter::build(hashes, 4).unwrap()
  let chain = FuseFilterChain::from_filters([
    BinaryFuseFilter::build([101, 103]).unwrap(),
    BinaryFuseFilter::build16([107, 109]).unwrap(),
  ])
  let epoch = EpochFuseFilter::build([
    { epoch: 1, hash: 101 },
    { epoch: 1, hash: 103 },
    { epoch: 2, hash: 107 },
  ]).unwrap()
  let tagged = TaggedFuseFilter::build([
    { tag: 1, hash: 101 },
    { tag: 1, hash: 103 },
    { tag: 2, hash: 107 },
  ]).unwrap()
  assert_true(
    decode_sharded_words(sharded.encode_words()).unwrap().validate(hashes),
  )
  assert_true(decode_chain_words(chain.encode_words()).unwrap().contains(109))
  assert_true(
    decode_epoch_words(epoch.encode_words()).unwrap().contains_at(2, 107),
  )
  assert_true(
    decode_tagged_words(tagged.encode_words()).unwrap().contains(1, 103),
  )
}

///|
test "composite codecs reject impossible counts and truncated children" {
  let filter = BinaryFuseFilter::build([11, 13, 17, 19]).unwrap()
  let chain = FuseFilterChain::from_filters([filter])
  let chain_words = chain.encode_words()
  assert_true(
    decode_chain_words(mutate_word(chain_words, 1, 2)) is Err(InvalidEncoding),
  )
  assert_true(decode_chain_words([22, 1, 0]) is Err(InvalidEncoding))
  let sharded = ShardedFuseFilter::build([11, 13, 17, 19], 2).unwrap()
  let sharded_words = sharded.encode_words()
  assert_true(
    decode_sharded_words(mutate_word(sharded_words, 1, 3))
    is Err(InvalidEncoding),
  )
  assert_true(decode_sharded_words([21, 1, -1]) is Err(InvalidEncoding))
  let tagged = TaggedFuseFilter::build([{ tag: 2, hash: 11 }]).unwrap()
  let tagged_words = tagged.encode_words()
  assert_true(
    decode_tagged_words(mutate_word(tagged_words, 2, -2))
    is Err(InvalidEncoding),
  )
  let epoch = EpochFuseFilter::build([{ epoch: 2, hash: 11 }]).unwrap()
  let epoch_words = epoch.encode_words()
  assert_true(
    decode_epoch_words(mutate_word(epoch_words, 3, 0)) is Err(InvalidEncoding),
  )
}

///|
test "exact-storage codecs check their parallel source arrays" {
  let verified = VerifiedFuseFilter::build([7, 11, 13, 17]).unwrap()
  let verified_words = verified.encode_words()
  assert_true(
    decode_verified_words(mutate_word(verified_words, 1, 99))
    is Err(InvalidEncoding),
  )
  let map = StaticIntMap::build([
    { hash: 7, value: 70 },
    { hash: 11, value: 110 },
  ]).unwrap()
  let map_words = map.encode_words()
  assert_true(
    decode_static_map_words(mutate_word(map_words, 2, 3))
    is Err(InvalidEncoding),
  )
  let overlay = FuseOverlay::from_patch(verified, {
    additions: [23],
    removals: [7],
  }).unwrap()
  let overlay_words = overlay.encode_words()
  assert_true(
    decode_overlay_words(mutate_word(overlay_words, 1, 0))
    is Err(InvalidEncoding),
  )
}

///|
test "codecs are deterministic for immutable values" {
  let hashes = spaced_hashes(64, 43)
  let filter = BinaryFuseFilter::build(hashes).unwrap()
  assert_eq(filter.encode_words(), filter.encode_words())
  let verified = VerifiedFuseFilter::build(hashes).unwrap()
  assert_eq(verified.encode_words(), verified.encode_words())
  let map_entries : Array[FuseValue] = []
  for index in 0..<hashes.length() {
    map_entries.push({ hash: hashes[index], value: index * 2 })
  }
  let map = StaticIntMap::build(map_entries).unwrap()
  assert_eq(map.encode_words(), map.encode_words())
}
