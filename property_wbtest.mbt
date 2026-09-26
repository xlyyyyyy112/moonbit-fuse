///|
fn property_hashes(size : Int, salt : Int) -> Array[Int] {
  let values = Array::make(size, 0)
  for index in 0..<size {
    // Keep the generated corpus in the public non-negative hash domain and
    // inject the index so property inputs cannot collide.
    values[index] = index * 104_729 + salt % 997 + 1
  }
  values
}

///|
test "construction property covers varied corpus sizes" {
  for size in [1, 2, 3, 4, 5, 8, 16, 31, 64, 127, 256, 511] {
    let hashes = property_hashes(size, size * 97)
    let filter = BinaryFuseFilter::build(hashes).unwrap()
    assert_true(filter.validate(hashes))
    assert_true(filter.contains_all(hashes))
    let decoded = decode_words(filter.encode_words()).unwrap()
    assert_true(decoded.validate(hashes))
  }
}

///|
test "construction property is deterministic across repeat builds" {
  for salt in [1, 17, 91, 777, 12_345] {
    let hashes = property_hashes(129, salt)
    let first = BinaryFuseFilter::build_with_options(hashes, {
      fingerprint_bits: 8,
      max_attempts: 96,
      initial_seed: salt,
    }).unwrap()
    let second = BinaryFuseFilter::build_with_options(hashes, {
      fingerprint_bits: 8,
      max_attempts: 96,
      initial_seed: salt,
    }).unwrap()
    assert_eq(first.encode_words(), second.encode_words())
  }
}
