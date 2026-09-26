///|
let verified_encoding_version = 31

///|
pub fn VerifiedFuseFilter::encode_words(
  self : VerifiedFuseFilter,
) -> Array[Int] {
  let encoded_filter = self.filter.encode_words()
  let words : Array[Int] = [
    verified_encoding_version,
    encoded_filter.length(),
    self.sorted_hashes.length(),
  ]
  for word in encoded_filter {
    words.push(word)
  }
  for hash in self.sorted_hashes {
    words.push(hash)
  }
  words
}

///|
pub fn decode_verified_words(
  words : Array[Int],
) -> Result[VerifiedFuseFilter, FuseError] {
  if words.length() < 3 || words[0] != verified_encoding_version {
    return Err(InvalidEncoding)
  }
  let filter_length = words[1]
  let hash_count = words[2]
  if filter_length <= 0 || hash_count <= 0 || filter_length > words.length() - 3 {
    return Err(InvalidEncoding)
  }
  if hash_count != words.length() - 3 - filter_length {
    return Err(InvalidEncoding)
  }
  let encoded_filter = Array::make(filter_length, 0)
  for index in 0..<filter_length {
    encoded_filter[index] = words[index + 3]
  }
  let sorted_hashes = Array::make(hash_count, 0)
  for index in 0..<hash_count {
    let hash = words[index + 3 + filter_length]
    if hash < 0 || (index > 0 && sorted_hashes[index - 1] >= hash) {
      return Err(InvalidEncoding)
    }
    sorted_hashes[index] = hash
  }
  match decode_words(encoded_filter) {
    Err(_) => Err(InvalidEncoding)
    Ok(filter) => {
      let result = { filter, sorted_hashes }
      if result.validate() {
        Ok(result)
      } else {
        Err(InvalidEncoding)
      }
    }
  }
}
