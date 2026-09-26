///|
pub fn BinaryFuseFilter::candidate_locations(
  self : BinaryFuseFilter,
  hash : Int,
) -> FuseLocations? {
  if hash < 0 {
    return None
  }
  let mixed = mix_hash(hash, self.seed)
  let (first, second, third) = positions(
    mixed,
    self.segment_length,
    self.segment_count,
  )
  Some({ first, second, third })
}

///|
pub fn BinaryFuseFilter::slot_fingerprints(
  self : BinaryFuseFilter,
  hash : Int,
) -> Array[Int] {
  match self.candidate_locations(hash) {
    None => []
    Some(locations) =>
      [
        self.fingerprints[locations.first],
        self.fingerprints[locations.second],
        self.fingerprints[locations.third],
      ]
  }
}

///|
pub fn BinaryFuseFilter::fingerprint_stats(
  self : BinaryFuseFilter,
) -> FingerprintStats {
  let mut occupied_slots = 0
  let mut maximum_fingerprint = 0
  let mut fingerprint_sum = 0
  for value in self.fingerprints {
    if value != 0 {
      occupied_slots = occupied_slots + 1
    }
    if value > maximum_fingerprint {
      maximum_fingerprint = value
    }
    fingerprint_sum = fingerprint_sum + value
  }
  {
    slot_count: self.fingerprints.length(),
    occupied_slots,
    empty_slots: self.fingerprints.length() - occupied_slots,
    maximum_fingerprint,
    fingerprint_sum,
  }
}

///|
pub fn BinaryFuseFilter::has_valid_shape(self : BinaryFuseFilter) -> Bool {
  if self.key_count <= 0 ||
    self.segment_length <= 0 ||
    self.segment_count <= 0 ||
    self.fingerprints.length() < 3 ||
    self.segment_count > self.fingerprints.length() - 2 ||
    (self.fingerprint_bits != 8 && self.fingerprint_bits != 16) {
    return false
  }
  let segment_total = self.segment_count + 2
  if self.fingerprints.length() % segment_total != 0 ||
    self.fingerprints.length() / segment_total != self.segment_length {
    return false
  }
  let limit = if self.fingerprint_bits == 8 { 256 } else { 65_536 }
  for value in self.fingerprints {
    if value < 0 || value >= limit {
      return false
    }
  }
  true
}

///|
pub fn BinaryFuseFilter::candidate_xor(
  self : BinaryFuseFilter,
  hash : Int,
) -> Int? {
  match self.candidate_locations(hash) {
    None => None
    Some(locations) =>
      Some(
        self.fingerprints[locations.first] ^
        self.fingerprints[locations.second] ^
        self.fingerprints[locations.third],
      )
  }
}

///|
pub fn BinaryFuseFilter::matches_fingerprint(
  self : BinaryFuseFilter,
  hash : Int,
) -> Bool {
  match self.candidate_xor(hash) {
    Some(value) =>
      value == fingerprint(mix_hash(hash, self.seed), self.fingerprint_bits)
    None => false
  }
}
