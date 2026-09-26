///|
let word_transport_magic = 0x4d465457

///|
let word_transport_version = 1

///|
let word_transport_header_length = 16

///|
pub fn encode_word_transport(words : Array[Int]) -> Result[Bytes, FuseError] {
  for word in words {
    if word < 0 {
      return Err(InvalidEncoding)
    }
  }
  let bytes = Array::make(
    word_transport_header_length + words.length() * 4,
    (0).to_byte(),
  )
  write_u32(bytes, 0, word_transport_magic)
  bytes[4] = word_transport_version.to_byte()
  bytes[5] = (0).to_byte()
  bytes[6] = (0).to_byte()
  bytes[7] = (0).to_byte()
  write_u32(bytes, 8, words.length())
  write_u32(bytes, 12, word_transport_checksum(words))
  for index in 0..<words.length() {
    write_u32(bytes, word_transport_header_length + index * 4, words[index])
  }
  Ok(Bytes::from_array(bytes))
}

///|
pub fn decode_word_transport(bytes : Bytes) -> Result[Array[Int], FuseError] {
  if bytes.length() < word_transport_header_length ||
    read_u32(bytes, 0) != word_transport_magic ||
    bytes[4].to_int() != word_transport_version ||
    bytes[5].to_int() != 0 ||
    bytes[6].to_int() != 0 ||
    bytes[7].to_int() != 0 {
    return Err(InvalidEncoding)
  }
  let count = read_u32(bytes, 8)
  let expected_checksum = read_u32(bytes, 12)
  if count < 0 ||
    expected_checksum < 0 ||
    bytes.length() != word_transport_header_length + count * 4 {
    return Err(InvalidEncoding)
  }
  let words = Array::make(count, 0)
  for index in 0..<count {
    let word = read_u32(bytes, word_transport_header_length + index * 4)
    if word < 0 {
      return Err(InvalidEncoding)
    }
    words[index] = word
  }
  if word_transport_checksum(words) != expected_checksum {
    return Err(InvalidEncoding)
  }
  Ok(words)
}

///|
pub fn BinaryFuseFilter::encode_transport(
  self : BinaryFuseFilter,
) -> Result[Bytes, FuseError] {
  encode_word_transport(self.encode_words())
}

///|
pub fn decode_filter_transport(
  bytes : Bytes,
) -> Result[BinaryFuseFilter, FuseError] {
  match decode_word_transport(bytes) {
    Ok(words) => decode_words(words)
    Err(error) => Err(error)
  }
}

///|
pub fn word_transport_checksum(words : Array[Int]) -> Int {
  let mut state = 0x13579b
  for index in 0..<words.length() {
    state = mix_hash(state.lxor(words[index]), index * 0x45d9f3b)
  }
  state
}
