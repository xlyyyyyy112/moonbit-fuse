///|
let byte_magic = 0x4d465331

///|
let byte_encoding_version = 1

///|
let byte_header_length = 32

///|
pub fn BinaryFuseFilter::encoded_byte_length(self : BinaryFuseFilter) -> Int {
  let width = if self.fingerprint_bits == 8 { 1 } else { 2 }
  byte_header_length + self.fingerprints.length() * width
}

///|
pub fn BinaryFuseFilter::encode_bytes(self : BinaryFuseFilter) -> Bytes {
  let width = if self.fingerprint_bits == 8 { 1 } else { 2 }
  let bytes = Array::make(self.encoded_byte_length(), (0).to_byte())
  write_u32(bytes, 0, byte_magic)
  bytes[4] = byte_encoding_version.to_byte()
  bytes[5] = self.fingerprint_bits.to_byte()
  bytes[6] = (0).to_byte()
  bytes[7] = (0).to_byte()
  write_u32(bytes, 8, self.key_count)
  write_u32(bytes, 12, self.segment_length)
  write_u32(bytes, 16, self.segment_count)
  write_u32(bytes, 20, self.seed)
  write_u32(bytes, 24, self.attempts)
  write_u32(bytes, 28, self.fingerprints.length())
  let mut cursor = byte_header_length
  for value in self.fingerprints {
    bytes[cursor] = (value & 0xff).to_byte()
    cursor = cursor + 1
    if width == 2 {
      bytes[cursor] = (value / 256).to_byte()
      cursor = cursor + 1
    }
  }
  Bytes::from_array(bytes)
}

///|
pub fn decode_bytes(bytes : Bytes) -> Result[BinaryFuseFilter, FuseError] {
  if bytes.length() < byte_header_length ||
    read_u32(bytes, 0) != byte_magic ||
    bytes[4].to_int() != byte_encoding_version ||
    (bytes[5].to_int() != 8 && bytes[5].to_int() != 16) ||
    bytes[6].to_int() != 0 ||
    bytes[7].to_int() != 0 {
    return Err(InvalidEncoding)
  }
  let key_count = read_u32(bytes, 8)
  let segment_length = read_u32(bytes, 12)
  let segment_count = read_u32(bytes, 16)
  let seed = read_u32(bytes, 20)
  let attempts = read_u32(bytes, 24)
  let fingerprint_count = read_u32(bytes, 28)
  let bits = bytes[5].to_int()
  let width = if bits == 8 { 1 } else { 2 }
  if key_count <= 0 ||
    segment_length <= 0 ||
    segment_count <= 0 ||
    seed < 0 ||
    attempts <= 0 ||
    fingerprint_count < 0 ||
    bytes.length() != byte_header_length + fingerprint_count * width {
    return Err(InvalidEncoding)
  }
  let words = Array::make(8 + fingerprint_count, 0)
  words[0] = encoding_version
  words[1] = key_count
  words[2] = segment_length
  words[3] = segment_count
  words[4] = seed
  words[5] = attempts
  words[6] = bits
  words[7] = fingerprint_count
  let mut cursor = byte_header_length
  for index in 0..<fingerprint_count {
    let low = bytes[cursor].to_int()
    cursor = cursor + 1
    let high = if width == 2 {
      let value = bytes[cursor].to_int()
      cursor = cursor + 1
      value
    } else {
      0
    }
    words[8 + index] = low + high * 256
  }
  match decode_words(words) {
    Ok(filter) => Ok(filter)
    Err(_) => Err(InvalidEncoding)
  }
}

///|
fn write_u32(bytes : Array[Byte], offset : Int, value : Int) -> Unit {
  bytes[offset] = (value & 0xff).to_byte()
  bytes[offset + 1] = ((value / 256) & 0xff).to_byte()
  bytes[offset + 2] = ((value / 65_536) & 0xff).to_byte()
  bytes[offset + 3] = ((value / 16_777_216) & 0xff).to_byte()
}

///|
fn read_u32(bytes : Bytes, offset : Int) -> Int {
  bytes[offset].to_int() +
  bytes[offset + 1].to_int() * 256 +
  bytes[offset + 2].to_int() * 65_536 +
  bytes[offset + 3].to_int() * 16_777_216
}
