///|
let static_map_encoding_version = 51

///|
pub fn StaticIntMap::encode_words(self : StaticIntMap) -> Array[Int] {
  let index_words = self.index.encode_words()
  let words : Array[Int] = [
    static_map_encoding_version,
    index_words.length(),
    self.values.length(),
  ]
  for word in index_words {
    words.push(word)
  }
  for value in self.values {
    words.push(value)
  }
  words
}

///|
pub fn decode_static_map_words(
  words : Array[Int],
) -> Result[StaticIntMap, FuseError] {
  if words.length() < 3 ||
    words[0] != static_map_encoding_version ||
    words[1] <= 0 ||
    words[2] <= 0 ||
    words.length() != 3 + words[1] + words[2] {
    return Err(InvalidEncoding)
  }
  let encoded_index = Array::make(words[1], 0)
  for offset in 0..<words[1] {
    encoded_index[offset] = words[3 + offset]
  }
  let values = Array::make(words[2], 0)
  for offset in 0..<words[2] {
    values[offset] = words[3 + words[1] + offset]
  }
  match decode_verified_words(encoded_index) {
    Ok(index) if index.len() == values.length() => Ok({ index, values })
    _ => Err(InvalidEncoding)
  }
}
