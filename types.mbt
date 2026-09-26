///|
pub(all) enum FuseError {
  EmptyInput
  NegativeHash(Int)
  DuplicateHash(Int)
  InvalidFingerprintBits(Int)
  InvalidAttempts(Int)
  InvalidShardCount(Int)
  InvalidTag(Int)
  ConflictingValue(Int)
  DuplicateString(String)
  ConstructionFailed(Int)
  InvalidEncoding
  UnsupportedVersion(Int)
}

///|
pub(all) struct BuildOptions {
  fingerprint_bits : Int
  max_attempts : Int
  initial_seed : Int
}

///|
pub(all) struct BuildStats {
  key_count : Int
  array_length : Int
  segment_length : Int
  segment_count : Int
  seed : Int
  attempts : Int
  fingerprint_bits : Int
}

///|
pub struct BinaryFuseFilter {
  key_count : Int
  segment_length : Int
  segment_count : Int
  seed : Int
  attempts : Int
  fingerprint_bits : Int
  fingerprints : Array[Int]
}

///|
pub struct StringFuseFilter {
  filter : BinaryFuseFilter
}

///|
pub(all) struct QuerySummary {
  query_count : Int
  positive_count : Int
  negative_count : Int
}

///|
pub struct ShardedFuseFilter {
  shard_count : Int
  shards : Array[BinaryFuseFilter?]
}

///|
pub struct FuseFilterChain {
  filters : Array[BinaryFuseFilter]
}

///|
pub(all) struct ShardStats {
  shard_count : Int
  key_count : Int
  populated_shards : Int
  smallest_shard : Int
  largest_shard : Int
}

///|
pub(all) struct QualityReport {
  source_count : Int
  probe_count : Int
  false_negative_count : Int
  false_positive_count : Int
  negative_probe_count : Int
}

///|
pub struct FuseBuilder {
  hashes : Array[Int]
}

///|
pub struct VerifiedFuseFilter {
  filter : BinaryFuseFilter
  sorted_hashes : Array[Int]
}

///|
pub(all) struct FusePatch {
  additions : Array[Int]
  removals : Array[Int]
}

///|
pub(all) struct EpochHash {
  epoch : Int
  hash : Int
}

///|
pub struct FuseEpoch {
  epoch : Int
  filter : BinaryFuseFilter
}

///|
pub struct EpochFuseFilter {
  epochs : Array[FuseEpoch]
}

///|
pub(all) struct EpochStats {
  epoch_count : Int
  key_count : Int
  first_epoch : Int
  last_epoch : Int
}

///|
pub(all) struct TaggedHash {
  tag : Int
  hash : Int
}

///|
pub(all) struct TagStats {
  tag_count : Int
  key_count : Int
  smallest_tag : Int
  largest_tag : Int
}

///|
pub struct TaggedFuseFilter {
  tags : Array[Int]
  filters : Array[BinaryFuseFilter]
}

///|
pub(all) struct FuseValue {
  hash : Int
  value : Int
}

///|
pub(all) struct MapStats {
  entry_count : Int
  smallest_key : Int
  largest_key : Int
}

///|
pub struct StaticIntMap {
  index : VerifiedFuseFilter
  values : Array[Int]
}

///|
pub(all) struct OverlayStats {
  base_key_count : Int
  addition_count : Int
  removal_count : Int
}

///|
pub struct FuseOverlay {
  base : VerifiedFuseFilter
  additions : VerifiedFuseFilter?
  removals : VerifiedFuseFilter?
}

///|
pub(all) struct FuseLocations {
  first : Int
  second : Int
  third : Int
}

///|
pub(all) struct FingerprintStats {
  slot_count : Int
  occupied_slots : Int
  empty_slots : Int
  maximum_fingerprint : Int
  fingerprint_sum : Int
}

///|
pub(all) struct EpochFuseValue {
  epoch : Int
  hash : Int
  value : Int
}

///|
pub struct FuseMapEpoch {
  epoch : Int
  map : StaticIntMap
}

///|
pub struct EpochStaticIntMap {
  epochs : Array[FuseMapEpoch]
}

///|
pub(all) struct EpochMapStats {
  epoch_count : Int
  entry_count : Int
  first_epoch : Int
  last_epoch : Int
}

///|
pub(all) enum MapMergePolicy {
  PreferLeft
  PreferRight
  RejectConflicts
}

///|
pub(all) struct MapMergeStats {
  left_only_count : Int
  right_only_count : Int
  shared_count : Int
  conflicting_count : Int
}

///|
pub(all) struct SnapshotDiff {
  additions : Array[Int]
  removals : Array[Int]
  shared_count : Int
}

///|
pub(all) struct MembershipResult {
  hash : Int
  might_contain : Bool
}

///|
pub(all) struct ExactMembershipResult {
  hash : Int
  contains : Bool
}

///|
pub(all) struct StringFuseValue {
  key : String
  value : Int
}

///|
pub(all) struct StringMapStats {
  entry_count : Int
  shortest_key_length : Int
  longest_key_length : Int
}

///|
pub struct StaticStringMap {
  filter : StringFuseFilter
  entries : Array[StringFuseValue]
}
