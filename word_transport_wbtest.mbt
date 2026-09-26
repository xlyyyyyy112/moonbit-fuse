///|
test "word transport is deterministic and preserves generic codec payloads" {
  let filter = BinaryFuseFilter::build16(spaced_hashes(73, 17)).unwrap()
  let words = filter.encode_words()
  let first = encode_word_transport(words).unwrap()
  let second = encode_word_transport(words).unwrap()
  assert_eq(first, second)
  assert_eq(decode_word_transport(first).unwrap(), words)
  let loaded = decode_filter_transport(filter.encode_transport().unwrap()).unwrap()
  assert_eq(loaded.encode_words(), words)
  let map = StaticIntMap::build([
    { hash: 7, value: 70 },
    { hash: 11, value: 110 },
  ]).unwrap()
  let map_words = map.encode_words()
  assert_eq(
    decode_word_transport(encode_word_transport(map_words).unwrap()).unwrap(),
    map_words,
  )
}

///|
test "word transport rejects nonportable values and byte corruption" {
  assert_true(encode_word_transport([1, -1]) is Err(InvalidEncoding))
  let encoded = encode_word_transport([1, 2, 3, 4]).unwrap()
  let wrong_magic = encoded.to_array()
  wrong_magic[0] = (0).to_byte()
  assert_true(
    decode_word_transport(Bytes::from_array(wrong_magic))
    is Err(InvalidEncoding),
  )
  let wrong_checksum = encoded.to_array()
  wrong_checksum[12] = wrong_checksum[12].to_int().lxor(1).to_byte()
  assert_true(
    decode_word_transport(Bytes::from_array(wrong_checksum))
    is Err(InvalidEncoding),
  )
  let wrong_payload = encoded.to_array()
  wrong_payload[16] = wrong_payload[16].to_int().lxor(1).to_byte()
  assert_true(
    decode_word_transport(Bytes::from_array(wrong_payload))
    is Err(InvalidEncoding),
  )
  assert_true(decode_word_transport(b"short") is Err(InvalidEncoding))
}
