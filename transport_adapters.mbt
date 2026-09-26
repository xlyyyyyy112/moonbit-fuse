///|
pub fn ShardedFuseFilter::encode_transport(
  self : ShardedFuseFilter,
) -> Result[Bytes, FuseError] {
  encode_word_transport(self.encode_words())
}

///|
pub fn decode_sharded_transport(
  bytes : Bytes,
) -> Result[ShardedFuseFilter, FuseError] {
  match decode_word_transport(bytes) {
    Ok(words) => decode_sharded_words(words)
    Err(error) => Err(error)
  }
}

///|
pub fn FuseFilterChain::encode_transport(
  self : FuseFilterChain,
) -> Result[Bytes, FuseError] {
  encode_word_transport(self.encode_words())
}

///|
pub fn decode_chain_transport(
  bytes : Bytes,
) -> Result[FuseFilterChain, FuseError] {
  match decode_word_transport(bytes) {
    Ok(words) => decode_chain_words(words)
    Err(error) => Err(error)
  }
}

///|
pub fn EpochFuseFilter::encode_transport(
  self : EpochFuseFilter,
) -> Result[Bytes, FuseError] {
  encode_word_transport(self.encode_words())
}

///|
pub fn decode_epoch_transport(
  bytes : Bytes,
) -> Result[EpochFuseFilter, FuseError] {
  match decode_word_transport(bytes) {
    Ok(words) => decode_epoch_words(words)
    Err(error) => Err(error)
  }
}

///|
pub fn TaggedFuseFilter::encode_transport(
  self : TaggedFuseFilter,
) -> Result[Bytes, FuseError] {
  encode_word_transport(self.encode_words())
}

///|
pub fn decode_tagged_transport(
  bytes : Bytes,
) -> Result[TaggedFuseFilter, FuseError] {
  match decode_word_transport(bytes) {
    Ok(words) => decode_tagged_words(words)
    Err(error) => Err(error)
  }
}

///|
pub fn VerifiedFuseFilter::encode_transport(
  self : VerifiedFuseFilter,
) -> Result[Bytes, FuseError] {
  encode_word_transport(self.encode_words())
}

///|
pub fn decode_verified_transport(
  bytes : Bytes,
) -> Result[VerifiedFuseFilter, FuseError] {
  match decode_word_transport(bytes) {
    Ok(words) => decode_verified_words(words)
    Err(error) => Err(error)
  }
}

///|
pub fn StaticIntMap::encode_transport(
  self : StaticIntMap,
) -> Result[Bytes, FuseError] {
  encode_word_transport(self.encode_words())
}

///|
pub fn decode_static_map_transport(
  bytes : Bytes,
) -> Result[StaticIntMap, FuseError] {
  match decode_word_transport(bytes) {
    Ok(words) => decode_static_map_words(words)
    Err(error) => Err(error)
  }
}

///|
pub fn FuseOverlay::encode_transport(
  self : FuseOverlay,
) -> Result[Bytes, FuseError] {
  encode_word_transport(self.encode_words())
}

///|
pub fn decode_overlay_transport(
  bytes : Bytes,
) -> Result[FuseOverlay, FuseError] {
  match decode_word_transport(bytes) {
    Ok(words) => decode_overlay_words(words)
    Err(error) => Err(error)
  }
}

///|
pub fn EpochStaticIntMap::encode_transport(
  self : EpochStaticIntMap,
) -> Result[Bytes, FuseError] {
  encode_word_transport(self.encode_words())
}

///|
pub fn decode_epoch_map_transport(
  bytes : Bytes,
) -> Result[EpochStaticIntMap, FuseError] {
  match decode_word_transport(bytes) {
    Ok(words) => decode_epoch_map_words(words)
    Err(error) => Err(error)
  }
}

///|
pub fn SnapshotDiff::encode_transport(
  self : SnapshotDiff,
) -> Result[Bytes, FuseError] {
  encode_word_transport(self.encode_words())
}

///|
pub fn decode_snapshot_diff_transport(
  bytes : Bytes,
) -> Result[SnapshotDiff, FuseError] {
  match decode_word_transport(bytes) {
    Ok(words) => decode_snapshot_diff_words(words)
    Err(error) => Err(error)
  }
}
