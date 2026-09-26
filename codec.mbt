///|
let encoding_version = 1

///|
pub fn BinaryFuseFilter::encode_words(self : BinaryFuseFilter) -> Array[Int] {
  let words = Array::make(8 + self.fingerprints.length(), 0)
  words[0] = encoding_version
  words[1] = self.key_count
  words[2] = self.segment_length
  words[3] = self.segment_count
  words[4] = self.seed
  words[5] = self.attempts
  words[6] = self.fingerprint_bits
  words[7] = self.fingerprints.length()
  for index in 0..<self.fingerprints.length() {
    words[index + 8] = self.fingerprints[index]
  }
  words
}

///|
pub fn decode_words(words : Array[Int]) -> Result[BinaryFuseFilter, FuseError] {
  if words.length() < 8 {
    return Err(InvalidEncoding)
  }
  if words[0] != encoding_version {
    return Err(UnsupportedVersion(words[0]))
  }
  let key_count = words[1]
  let segment_length = words[2]
  let segment_count = words[3]
  let seed = words[4]
  let attempts = words[5]
  let bits = words[6]
  let fingerprint_count = words[7]
  if key_count <= 0 ||
    segment_length <= 0 ||
    segment_count <= 0 ||
    attempts <= 0 {
    return Err(InvalidEncoding)
  }
  if bits != 8 && bits != 16 {
    return Err(InvalidEncoding)
  }
  if fingerprint_count < 0 || fingerprint_count != words.length() - 8 {
    return Err(InvalidEncoding)
  }
  if fingerprint_count < 3 || segment_count > fingerprint_count - 2 {
    return Err(InvalidEncoding)
  }
  let segment_total = segment_count + 2
  if fingerprint_count % segment_total != 0 ||
    fingerprint_count / segment_total != segment_length {
    return Err(InvalidEncoding)
  }
  let max_value = if bits == 8 { 0xff } else { 0xffff }
  let fingerprints = Array::make(fingerprint_count, 0)
  for index in 0..<fingerprint_count {
    let value = words[index + 8]
    if value < 0 || value > max_value {
      return Err(InvalidEncoding)
    }
    fingerprints[index] = value
  }
  Ok({
    key_count,
    segment_length,
    segment_count,
    seed,
    attempts,
    fingerprint_bits: bits,
    fingerprints,
  })
}
