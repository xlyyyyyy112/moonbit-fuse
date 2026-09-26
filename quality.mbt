///|
pub fn BinaryFuseFilter::bit_cost(self : BinaryFuseFilter) -> Int {
  self.fingerprints.length() * self.fingerprint_bits
}

///|
pub fn BinaryFuseFilter::bits_per_key_milli(self : BinaryFuseFilter) -> Int {
  if self.key_count == 0 {
    return 0
  }
  self.bit_cost() * 1000 / self.key_count
}

///|
pub fn BinaryFuseFilter::evaluate(
  self : BinaryFuseFilter,
  source_hashes : Array[Int],
  probes : Array[Int],
) -> Result[QualityReport, FuseError] {
  match
    validate_input(source_hashes, {
      fingerprint_bits: self.fingerprint_bits,
      max_attempts: 1,
      initial_seed: 0,
    }) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if source_hashes.length() != self.key_count {
    return Err(InvalidEncoding)
  }
  let sources : Map[Int, Bool] = Map([], capacity=source_hashes.length())
  let mut false_negative_count = 0
  for hash in source_hashes {
    sources[hash] = true
    if !self.contains(hash) {
      false_negative_count = false_negative_count + 1
    }
  }
  let mut false_positive_count = 0
  let mut negative_probe_count = 0
  for probe in probes {
    if !sources.contains(probe) {
      negative_probe_count = negative_probe_count + 1
      if self.contains(probe) {
        false_positive_count = false_positive_count + 1
      }
    }
  }
  Ok({
    source_count: source_hashes.length(),
    probe_count: probes.length(),
    false_negative_count,
    false_positive_count,
    negative_probe_count,
  })
}

///|
pub fn BinaryFuseFilter::expected_false_positive_denominator(
  self : BinaryFuseFilter,
) -> Int {
  self.fingerprint_denominator()
}
