///|
test "byte encoding round trips 8-bit and 16-bit filters" {
  let hashes = spaced_hashes(111, 31)
  let narrow = BinaryFuseFilter::build(hashes).unwrap()
  let wide = BinaryFuseFilter::build16(hashes).unwrap()
  let narrow_bytes = narrow.encode_bytes()
  let wide_bytes = wide.encode_bytes()
  assert_false(narrow.uses_16bit_fingerprints())
  assert_true(wide.uses_16bit_fingerprints())
  assert_eq(narrow_bytes.length(), narrow.encoded_byte_length())
  assert_eq(wide_bytes.length(), wide.encoded_byte_length())
  let narrow_loaded = decode_bytes(narrow_bytes).unwrap()
  let wide_loaded = decode_bytes(wide_bytes).unwrap()
  assert_true(narrow_loaded.validate(hashes))
  assert_true(wide_loaded.validate(hashes))
  assert_eq(narrow_loaded.encode_words(), narrow.encode_words())
  assert_eq(wide_loaded.encode_words(), wide.encode_words())
}

///|
test "byte decoding rejects damaged headers, lengths and fingerprints" {
  let filter = BinaryFuseFilter::build16([3, 5, 7, 11, 13]).unwrap()
  let bytes = filter.encode_bytes()
  let wrong_magic = bytes.to_array()
  wrong_magic[0] = 0
  assert_true(
    decode_bytes(Bytes::from_array(wrong_magic)) is Err(InvalidEncoding),
  )
  let wrong_version = bytes.to_array()
  wrong_version[4] = 9
  assert_true(
    decode_bytes(Bytes::from_array(wrong_version)) is Err(InvalidEncoding),
  )
  let wrong_reserved = bytes.to_array()
  wrong_reserved[7] = 1
  assert_true(
    decode_bytes(Bytes::from_array(wrong_reserved)) is Err(InvalidEncoding),
  )
  let truncated = Array::make(bytes.length() - 1, (0).to_byte())
  for index in 0..<truncated.length() {
    truncated[index] = bytes[index]
  }
  assert_true(
    decode_bytes(Bytes::from_array(truncated)) is Err(InvalidEncoding),
  )
  let damaged = bytes.to_array()
  damaged[28] = 0
  assert_true(decode_bytes(Bytes::from_array(damaged)) is Err(InvalidEncoding))
}
