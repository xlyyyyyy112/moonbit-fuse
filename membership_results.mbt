///|
pub fn BinaryFuseFilter::classify(
  self : BinaryFuseFilter,
  hashes : Array[Int],
) -> Array[MembershipResult] {
  let results : Array[MembershipResult] = []
  for hash in hashes {
    results.push({ hash, might_contain: self.contains(hash) })
  }
  results
}

///|
pub fn VerifiedFuseFilter::classify_exact(
  self : VerifiedFuseFilter,
  hashes : Array[Int],
) -> Array[ExactMembershipResult] {
  let results : Array[ExactMembershipResult] = []
  for hash in hashes {
    results.push({ hash, contains: self.contains_exact(hash) })
  }
  results
}

///|
pub fn BinaryFuseFilter::count_matches(
  self : BinaryFuseFilter,
  hashes : Array[Int],
) -> Int {
  let mut count = 0
  for hash in hashes {
    if self.contains(hash) {
      count = count + 1
    }
  }
  count
}

///|
pub fn VerifiedFuseFilter::count_exact_matches(
  self : VerifiedFuseFilter,
  hashes : Array[Int],
) -> Int {
  let mut count = 0
  for hash in hashes {
    if self.contains_exact(hash) {
      count = count + 1
    }
  }
  count
}
