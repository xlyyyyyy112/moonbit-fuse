///|
pub fn BinaryFuseFilter::query_all(
  self : BinaryFuseFilter,
  hashes : Array[Int],
) -> QuerySummary {
  let mut positive_count = 0
  for hash in hashes {
    if self.contains(hash) {
      positive_count = positive_count + 1
    }
  }
  {
    query_count: hashes.length(),
    positive_count,
    negative_count: hashes.length() - positive_count,
  }
}

///|
pub fn BinaryFuseFilter::contains_all(
  self : BinaryFuseFilter,
  hashes : Array[Int],
) -> Bool {
  for hash in hashes {
    if !self.contains(hash) {
      return false
    }
  }
  true
}

///|
pub fn BinaryFuseFilter::fingerprint_denominator(
  self : BinaryFuseFilter,
) -> Int {
  if self.fingerprint_bits == 8 {
    256
  } else {
    65_536
  }
}
