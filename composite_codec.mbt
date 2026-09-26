///|
let sharded_encoding_version = 21

///|
let chain_encoding_version = 22

///|
pub fn ShardedFuseFilter::encode_words(self : ShardedFuseFilter) -> Array[Int] {
  let words : Array[Int] = [sharded_encoding_version, self.shard_count]
  for shard in self.shards {
    match shard {
      None => words.push(0)
      Some(filter) => {
        let encoded = filter.encode_words()
        words.push(encoded.length())
        for word in encoded {
          words.push(word)
        }
      }
    }
  }
  words
}

///|
pub fn decode_sharded_words(
  words : Array[Int],
) -> Result[ShardedFuseFilter, FuseError] {
  if words.length() < 2 || words[0] != sharded_encoding_version || words[1] <= 0 {
    return Err(InvalidEncoding)
  }
  let shard_count = words[1]
  let mut cursor = 2
  let shards : Array[BinaryFuseFilter?] = []
  for _ in 0..<shard_count {
    if cursor >= words.length() {
      return Err(InvalidEncoding)
    }
    let length = words[cursor]
    cursor = cursor + 1
    if length == 0 {
      shards.push(None)
    } else {
      if length < 0 || length > words.length() - cursor {
        return Err(InvalidEncoding)
      }
      let encoded = Array::make(length, 0)
      for index in 0..<length {
        encoded[index] = words[cursor + index]
      }
      cursor = cursor + length
      match decode_words(encoded) {
        Ok(filter) => shards.push(Some(filter))
        Err(_) => return Err(InvalidEncoding)
      }
    }
  }
  if cursor != words.length() {
    return Err(InvalidEncoding)
  }
  Ok({ shard_count, shards })
}

///|
pub fn FuseFilterChain::encode_words(self : FuseFilterChain) -> Array[Int] {
  let words : Array[Int] = [chain_encoding_version, self.filters.length()]
  for filter in self.filters {
    let encoded = filter.encode_words()
    words.push(encoded.length())
    for word in encoded {
      words.push(word)
    }
  }
  words
}

///|
pub fn decode_chain_words(
  words : Array[Int],
) -> Result[FuseFilterChain, FuseError] {
  if words.length() < 2 || words[0] != chain_encoding_version || words[1] < 0 {
    return Err(InvalidEncoding)
  }
  let filter_count = words[1]
  let mut cursor = 2
  let filters : Array[BinaryFuseFilter] = []
  for _ in 0..<filter_count {
    if cursor >= words.length() {
      return Err(InvalidEncoding)
    }
    let length = words[cursor]
    cursor = cursor + 1
    if length <= 0 || length > words.length() - cursor {
      return Err(InvalidEncoding)
    }
    let encoded = Array::make(length, 0)
    for index in 0..<length {
      encoded[index] = words[cursor + index]
    }
    cursor = cursor + length
    match decode_words(encoded) {
      Ok(filter) => filters.push(filter)
      Err(_) => return Err(InvalidEncoding)
    }
  }
  if cursor != words.length() {
    return Err(InvalidEncoding)
  }
  Ok(FuseFilterChain::from_filters(filters))
}
