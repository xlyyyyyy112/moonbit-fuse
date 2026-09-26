///|
fn benchmark_hashes() -> Array[Int] {
  let hashes = Array::make(4_000, 0)
  for index in 0..<hashes.length() {
    hashes[index] = index * 104_729 + 17
  }
  hashes
}

///|
test (b : @bench.T) {
  let hashes = benchmark_hashes()
  let filter = BinaryFuseFilter::build(hashes).unwrap()
  let wide_filter = BinaryFuseFilter::build16(hashes).unwrap()
  let verified = VerifiedFuseFilter::build(hashes).unwrap()
  let sharded = ShardedFuseFilter::build(hashes, 16).unwrap()
  let map_entries : Array[FuseValue] = []
  for index in 0..<hashes.length() {
    map_entries.push({ hash: hashes[index], value: index })
  }
  let map = StaticIntMap::build(map_entries).unwrap()
  let encoded = filter.encode_words()
  b.bench(name="build_4000_hash_filter", fn() {
    b.keep(BinaryFuseFilter::build(hashes).unwrap().stats().attempts)
  })
  b.bench(name="build_4000_hash_filter_16", fn() {
    b.keep(BinaryFuseFilter::build16(hashes).unwrap().stats().attempts)
  })
  b.bench(name="fuse_filter_hit", fn() { b.keep(filter.contains(1_257_748)) })
  b.bench(name="fuse_filter_16_hit", fn() {
    b.keep(wide_filter.contains(1_257_748))
  })
  b.bench(name="fuse_filter_miss", fn() { b.keep(filter.contains(1_257_749)) })
  b.bench(name="fuse_filter_word_encode", fn() {
    b.keep(filter.encode_words().length())
  })
  b.bench(name="fuse_filter_word_decode", fn() {
    b.keep(decode_words(encoded).unwrap().len())
  })
  b.bench(name="sharded_filter_hit", fn() {
    b.keep(sharded.contains(1_257_748))
  })
  b.bench(name="verified_filter_exact_hit", fn() {
    b.keep(verified.contains_exact(1_257_748))
  })
  b.bench(name="static_map_hit", fn() { b.keep(map.get(1_257_748)) })
}
