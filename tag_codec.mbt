///|
let tagged_encoding_version = 42

///|
pub fn TaggedFuseFilter::encode_words(self : TaggedFuseFilter) -> Array[Int] {
  let words : Array[Int] = [tagged_encoding_version, self.tags.length()]
  for index in 0..<self.tags.length() {
    let encoded = self.filters[index].encode_words()
    words.push(self.tags[index])
    words.push(encoded.length())
    for word in encoded {
      words.push(word)
    }
  }
  words
}

///|
pub fn decode_tagged_words(
  words : Array[Int],
) -> Result[TaggedFuseFilter, FuseError] {
  if words.length() < 2 || words[0] != tagged_encoding_version || words[1] <= 0 {
    return Err(InvalidEncoding)
  }
  let count = words[1]
  let mut cursor = 2
  let tags : Array[Int] = []
  let filters : Array[BinaryFuseFilter] = []
  let mut previous_tag : Int? = None
  for _ in 0..<count {
    if words.length() - cursor < 2 {
      return Err(InvalidEncoding)
    }
    let tag = words[cursor]
    let length = words[cursor + 1]
    cursor = cursor + 2
    if tag < 0 || length <= 0 || length > words.length() - cursor {
      return Err(InvalidEncoding)
    }
    match previous_tag {
      Some(previous) if previous >= tag => return Err(InvalidEncoding)
      _ => ()
    }
    let encoded = Array::make(length, 0)
    for index in 0..<length {
      encoded[index] = words[cursor + index]
    }
    cursor = cursor + length
    match decode_words(encoded) {
      Ok(filter) => {
        tags.push(tag)
        filters.push(filter)
        previous_tag = Some(tag)
      }
      Err(_) => return Err(InvalidEncoding)
    }
  }
  if cursor != words.length() {
    return Err(InvalidEncoding)
  }
  Ok({ tags, filters })
}
