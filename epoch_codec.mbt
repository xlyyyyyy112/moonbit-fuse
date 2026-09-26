///|
let epoch_encoding_version = 41

///|
pub fn EpochFuseFilter::encode_words(self : EpochFuseFilter) -> Array[Int] {
  let words : Array[Int] = [epoch_encoding_version, self.epochs.length()]
  for item in self.epochs {
    let encoded = item.filter.encode_words()
    words.push(item.epoch)
    words.push(encoded.length())
    for word in encoded {
      words.push(word)
    }
  }
  words
}

///|
pub fn decode_epoch_words(
  words : Array[Int],
) -> Result[EpochFuseFilter, FuseError] {
  if words.length() < 2 || words[0] != epoch_encoding_version || words[1] < 0 {
    return Err(InvalidEncoding)
  }
  let count = words[1]
  let mut cursor = 2
  let epochs : Array[FuseEpoch] = []
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
    let encoded = Array::make(length, 0)
    for index in 0..<length {
      encoded[index] = words[cursor + index]
    }
    cursor = cursor + length
    match decode_words(encoded) {
      Err(_) => return Err(InvalidEncoding)
      Ok(filter) => {
        epochs.push({ epoch, filter })
        previous_epoch = Some(epoch)
      }
    }
  }
  if cursor != words.length() {
    return Err(InvalidEncoding)
  }
  Ok({ epochs, })
}
