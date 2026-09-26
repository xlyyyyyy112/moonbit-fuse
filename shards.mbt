///|
pub fn ShardedFuseFilter::build(
  hashes : Array[Int],
  shard_count : Int,
) -> Result[ShardedFuseFilter, FuseError] {
  ShardedFuseFilter::build_with_options(
    hashes,
    shard_count,
    default_build_options(),
  )
}

///|
pub fn ShardedFuseFilter::build_with_options(
  hashes : Array[Int],
  shard_count : Int,
  options : BuildOptions,
) -> Result[ShardedFuseFilter, FuseError] {
  if shard_count <= 0 {
    return Err(InvalidShardCount(shard_count))
  }
  match validate_input(hashes, options) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let buckets : Array[Array[Int]] = []
  for _ in 0..<shard_count {
    buckets.push([])
  }
  for hash in hashes {
    buckets[hash % shard_count].push(hash)
  }
  let shards : Array[BinaryFuseFilter?] = []
  for bucket in buckets {
    if bucket.length() == 0 {
      shards.push(None)
    } else {
      match BinaryFuseFilter::build_with_options(bucket, options) {
        Ok(filter) => shards.push(Some(filter))
        Err(error) => return Err(error)
      }
    }
  }
  Ok({ shard_count, shards })
}

///|
pub fn ShardedFuseFilter::contains(
  self : ShardedFuseFilter,
  hash : Int,
) -> Bool {
  if hash < 0 {
    return false
  }
  match self.shards[hash % self.shard_count] {
    Some(filter) => filter.contains(hash)
    None => false
  }
}

///|
pub fn ShardedFuseFilter::len(self : ShardedFuseFilter) -> Int {
  let mut total = 0
  for shard in self.shards {
    match shard {
      Some(filter) => total = total + filter.len()
      None => ()
    }
  }
  total
}

///|
pub fn ShardedFuseFilter::stats(self : ShardedFuseFilter) -> ShardStats {
  let mut key_count = 0
  let mut populated_shards = 0
  let mut smallest_shard = 0
  let mut largest_shard = 0
  for shard in self.shards {
    match shard {
      None => ()
      Some(filter) => {
        let count = filter.len()
        key_count = key_count + count
        populated_shards = populated_shards + 1
        if smallest_shard == 0 || count < smallest_shard {
          smallest_shard = count
        }
        if count > largest_shard {
          largest_shard = count
        }
      }
    }
  }
  {
    shard_count: self.shard_count,
    key_count,
    populated_shards,
    smallest_shard,
    largest_shard,
  }
}

///|
pub fn ShardedFuseFilter::validate(
  self : ShardedFuseFilter,
  hashes : Array[Int],
) -> Bool {
  if self.shard_count <= 0 ||
    self.shards.length() != self.shard_count ||
    hashes.length() != self.len() {
    return false
  }
  for hash in hashes {
    if hash < 0 || !self.contains(hash) {
      return false
    }
  }
  true
}
