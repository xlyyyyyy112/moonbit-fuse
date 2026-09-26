///|
let overlay_encoding_version = 61

///|
pub fn FuseOverlay::encode_words(self : FuseOverlay) -> Array[Int] {
  let base_words = self.base.encode_words()
  let words : Array[Int] = [overlay_encoding_version, base_words.length()]
  for word in base_words {
    words.push(word)
  }
  append_optional_verified(words, self.additions)
  append_optional_verified(words, self.removals)
  words
}

///|
pub fn decode_overlay_words(
  words : Array[Int],
) -> Result[FuseOverlay, FuseError] {
  if words.length() < 3 || words[0] != overlay_encoding_version || words[1] <= 0 {
    return Err(InvalidEncoding)
  }
  let base_length = words[1]
  if base_length > words.length() - 2 {
    return Err(InvalidEncoding)
  }
  let encoded_base = copy_word_range(words, 2, base_length)
  let mut cursor = 2 + base_length
  let additions_result = read_optional_verified(words, cursor)
  let (additions, after_additions) = match additions_result {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  cursor = after_additions
  let removals_result = read_optional_verified(words, cursor)
  let (removals, after_removals) = match removals_result {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if after_removals != words.length() {
    return Err(InvalidEncoding)
  }
  match decode_verified_words(encoded_base) {
    Ok(base) => {
      let overlay = { base, additions, removals }
      if overlay.validate() {
        Ok(overlay)
      } else {
        Err(InvalidEncoding)
      }
    }
    Err(_) => Err(InvalidEncoding)
  }
}

///|
fn append_optional_verified(
  words : Array[Int],
  filter : VerifiedFuseFilter?,
) -> Unit {
  match filter {
    None => words.push(0)
    Some(value) => {
      let encoded = value.encode_words()
      words.push(encoded.length())
      for word in encoded {
        words.push(word)
      }
    }
  }
}

///|
fn read_optional_verified(
  words : Array[Int],
  cursor : Int,
) -> Result[(VerifiedFuseFilter?, Int), FuseError] {
  if cursor >= words.length() {
    return Err(InvalidEncoding)
  }
  let length = words[cursor]
  if length == 0 {
    return Ok((None, cursor + 1))
  }
  if length < 0 || length > words.length() - cursor - 1 {
    return Err(InvalidEncoding)
  }
  let encoded = copy_word_range(words, cursor + 1, length)
  match decode_verified_words(encoded) {
    Ok(filter) => Ok((Some(filter), cursor + 1 + length))
    Err(_) => Err(InvalidEncoding)
  }
}

///|
fn copy_word_range(words : Array[Int], start : Int, length : Int) -> Array[Int] {
  let copied = Array::make(length, 0)
  for index in 0..<length {
    copied[index] = words[start + index]
  }
  copied
}
