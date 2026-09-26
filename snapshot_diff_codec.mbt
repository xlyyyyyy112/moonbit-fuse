///|
let snapshot_diff_encoding_version = 81

///|
pub fn SnapshotDiff::encode_words(self : SnapshotDiff) -> Array[Int] {
  let words : Array[Int] = [
    snapshot_diff_encoding_version,
    self.additions.length(),
    self.removals.length(),
    self.shared_count,
  ]
  for hash in self.additions {
    words.push(hash)
  }
  for hash in self.removals {
    words.push(hash)
  }
  words
}

///|
pub fn decode_snapshot_diff_words(
  words : Array[Int],
) -> Result[SnapshotDiff, FuseError] {
  if words.length() < 4 ||
    words[0] != snapshot_diff_encoding_version ||
    words[1] < 0 ||
    words[2] < 0 ||
    words[3] < 0 ||
    words.length() != 4 + words[1] + words[2] {
    return Err(InvalidEncoding)
  }
  let additions = Array::make(words[1], 0)
  let removals = Array::make(words[2], 0)
  for index in 0..<additions.length() {
    additions[index] = words[4 + index]
  }
  for index in 0..<removals.length() {
    removals[index] = words[4 + additions.length() + index]
  }
  let result = { additions, removals, shared_count: words[3] }
  if result.validate() {
    Ok(result)
  } else {
    Err(InvalidEncoding)
  }
}
