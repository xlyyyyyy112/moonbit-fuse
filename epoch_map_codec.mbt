///|
let epoch_map_encoding_version = 71

///|
pub fn EpochStaticIntMap::encode_words(self : EpochStaticIntMap) -> Array[Int] {
  let words : Array[Int] = [epoch_map_encoding_version, self.epochs.length()]
  for item in self.epochs {
    let encoded = item.map.encode_words()
    words.push(item.epoch)
    words.push(encoded.length())
    for word in encoded {
      words.push(word)
    }
  }
  words
}

///|
pub fn decode_epoch_map_words(
  words : Array[Int],
) -> Result[EpochStaticIntMap, FuseError] {
  if words.length() < 2 ||
    words[0] != epoch_map_encoding_version ||
    words[1] < 0 {
    return Err(InvalidEncoding)
  }
  let count = words[1]
  let mut cursor = 2
  let epochs : Array[FuseMapEpoch] = []
  let mut previous_epoch : Int? = None
  for _ in 0..<count {
    if words.length() - cursor < 2 {
      return Err(InvalidEncoding)
    }
    let epoch = words[cursor]
    let length = words[cursor + 1]
    cursor = cursor + 2
    if length <= 0 || length > words.length() - cursor {
      return Err(InvalidEncoding)
    }
    match previous_epoch {
      Some(previous) if previous >= epoch => return Err(InvalidEncoding)
      _ => ()
    }
    let encoded = copy_word_range(words, cursor, length)
    cursor = cursor + length
    match decode_static_map_words(encoded) {
      Ok(map) => {
        epochs.push({ epoch, map })
        previous_epoch = Some(epoch)
      }
      Err(_) => return Err(InvalidEncoding)
    }
  }
  if cursor != words.length() {
    return Err(InvalidEncoding)
  }
  let result : EpochStaticIntMap = { epochs, }
  if result.validate() {
    Ok(result)
  } else {
    Err(InvalidEncoding)
  }
}
