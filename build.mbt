///|
priv struct PeelStep {
  hash : Int
  slot : Int
}

///|
let positive_mask = 0x7fffffff

///|
let default_attempts = 96

///|
pub fn default_build_options() -> BuildOptions {
  { fingerprint_bits: 8, max_attempts: default_attempts, initial_seed: 0 }
}

///|
pub fn BinaryFuseFilter::build(
  hashes : Array[Int],
) -> Result[BinaryFuseFilter, FuseError] {
  BinaryFuseFilter::build_with_options(hashes, default_build_options())
}

///|
pub fn BinaryFuseFilter::build16(
  hashes : Array[Int],
) -> Result[BinaryFuseFilter, FuseError] {
  BinaryFuseFilter::build_with_options(hashes, {
    fingerprint_bits: 16,
    max_attempts: default_attempts,
    initial_seed: 0,
  })
}

///|
pub fn BinaryFuseFilter::build_with_options(
  hashes : Array[Int],
  options : BuildOptions,
) -> Result[BinaryFuseFilter, FuseError] {
  match validate_input(hashes, options) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let segment_length = segment_length_for(hashes.length())
  let segment_count = segment_count_for(hashes.length(), segment_length)
  for attempt in 0..<options.max_attempts {
    let seed = mix_seed(options.initial_seed, attempt)
    match
      build_attempt(
        hashes,
        segment_length,
        segment_count,
        seed,
        options.fingerprint_bits,
      ) {
      Some(fingerprints) =>
        return Ok({
          key_count: hashes.length(),
          segment_length,
          segment_count,
          seed,
          attempts: attempt + 1,
          fingerprint_bits: options.fingerprint_bits,
          fingerprints,
        })
      None => ()
    }
  }
  Err(ConstructionFailed(options.max_attempts))
}

///|
pub fn BinaryFuseFilter::contains(self : BinaryFuseFilter, hash : Int) -> Bool {
  if hash < 0 || self.key_count == 0 {
    return false
  }
  let mixed = mix_hash(hash, self.seed)
  let (first, second, third) = positions(
    mixed,
    self.segment_length,
    self.segment_count,
  )
  let value = self.fingerprints[first]
    .lxor(self.fingerprints[second])
    .lxor(self.fingerprints[third])
  value == fingerprint(mixed, self.fingerprint_bits)
}

///|
pub fn BinaryFuseFilter::len(self : BinaryFuseFilter) -> Int {
  self.key_count
}

///|
pub fn BinaryFuseFilter::uses_16bit_fingerprints(
  self : BinaryFuseFilter,
) -> Bool {
  self.fingerprint_bits == 16
}

///|
pub fn BinaryFuseFilter::stats(self : BinaryFuseFilter) -> BuildStats {
  {
    key_count: self.key_count,
    array_length: self.fingerprints.length(),
    segment_length: self.segment_length,
    segment_count: self.segment_count,
    seed: self.seed,
    attempts: self.attempts,
    fingerprint_bits: self.fingerprint_bits,
  }
}

///|
pub fn BinaryFuseFilter::validate(
  self : BinaryFuseFilter,
  hashes : Array[Int],
) -> Bool {
  if hashes.length() != self.key_count || !self.has_valid_shape() {
    return false
  }
  for hash in hashes {
    if hash < 0 || !self.contains(hash) {
      return false
    }
  }
  true
}

///|
fn validate_input(
  hashes : Array[Int],
  options : BuildOptions,
) -> Result[Unit, FuseError] {
  if hashes.length() == 0 {
    return Err(EmptyInput)
  }
  if options.fingerprint_bits != 8 && options.fingerprint_bits != 16 {
    return Err(InvalidFingerprintBits(options.fingerprint_bits))
  }
  if options.max_attempts <= 0 {
    return Err(InvalidAttempts(options.max_attempts))
  }
  let seen : Map[Int, Bool] = Map([], capacity=hashes.length())
  for hash in hashes {
    if hash < 0 {
      return Err(NegativeHash(hash))
    }
    if seen.contains(hash) {
      return Err(DuplicateHash(hash))
    }
    seen[hash] = true
  }
  Ok(())
}

///|
fn build_attempt(
  hashes : Array[Int],
  segment_length : Int,
  segment_count : Int,
  seed : Int,
  bits : Int,
) -> Array[Int]? {
  let length = (segment_count + 2) * segment_length
  let counts = Array::make(length, 0)
  let xors = Array::make(length, 0)
  for hash in hashes {
    let mixed = mix_hash(hash, seed)
    let (first, second, third) = positions(mixed, segment_length, segment_count)
    counts[first] = counts[first] + 1
    counts[second] = counts[second] + 1
    counts[third] = counts[third] + 1
    xors[first] = xors[first].lxor(mixed)
    xors[second] = xors[second].lxor(mixed)
    xors[third] = xors[third].lxor(mixed)
  }
  let queue = Array::make(length, 0)
  let mut head = 0
  let mut tail = 0
  for slot in 0..<length {
    if counts[slot] == 1 {
      queue[tail] = slot
      tail = tail + 1
    }
  }
  let steps = Array::make(hashes.length(), { hash: 0, slot: 0 })
  let mut step_count = 0
  while head < tail {
    let slot = queue[head]
    head = head + 1
    if counts[slot] != 1 {
      continue
    }
    let hash = xors[slot]
    steps[step_count] = { hash, slot }
    step_count = step_count + 1
    let (first, second, third) = positions(hash, segment_length, segment_count)
    for index in [first, second, third] {
      if counts[index] > 0 {
        counts[index] = counts[index] - 1
        xors[index] = xors[index].lxor(hash)
        if counts[index] == 1 {
          queue[tail] = index
          tail = tail + 1
        }
      }
    }
  }
  if step_count != hashes.length() {
    return None
  }
  let fingerprints = Array::make(length, 0)
  for offset in 0..<step_count {
    let step = steps[step_count - offset - 1]
    let (first, second, third) = positions(
      step.hash,
      segment_length,
      segment_count,
    )
    let value = fingerprint(step.hash, bits)
      .lxor(fingerprints[first])
      .lxor(fingerprints[second])
      .lxor(fingerprints[third])
    fingerprints[step.slot] = value
  }
  Some(fingerprints)
}

///|
fn segment_length_for(count : Int) -> Int {
  let mut length = 4
  while length * length < count && length < 65536 {
    length = length * 2
  }
  length
}

///|
fn segment_count_for(count : Int, segment_length : Int) -> Int {
  // ponytail: conservative density keeps bounded construction reliable;
  // tune toward the Binary Fuse packing limit only with measured regressions.
  let wanted = count * 2
  let count = (wanted + segment_length - 1) / segment_length
  if count < 1 {
    1
  } else {
    count
  }
}

///|
fn positions(
  hash : Int,
  segment_length : Int,
  segment_count : Int,
) -> (Int, Int, Int) {
  let base = hash % segment_count
  let first = base * segment_length + mix_hash(hash, 0x13579b) % segment_length
  let second = (base + 1) * segment_length +
    mix_hash(hash, 0x2468ad) % segment_length
  let third = (base + 2) * segment_length +
    mix_hash(hash, 0x5a5a5a) % segment_length
  (first, second, third)
}

///|
fn mix_seed(initial : Int, attempt : Int) -> Int {
  mix_hash(initial + attempt * 0x9e3779b, 0x85ebca6b)
}

///|
fn mix_hash(value : Int, seed : Int) -> Int {
  let mut hash = (value.lxor(seed) + 0x7f4a7c15) & positive_mask
  hash = hash.lxor(hash / 16)
  hash = (hash * 0x45d9f3b) & positive_mask
  hash = hash.lxor(hash / 13)
  hash = (hash * 0x27d4eb2d) & positive_mask
  hash.lxor(hash / 16) & positive_mask
}

///|
fn fingerprint(hash : Int, bits : Int) -> Int {
  let mask = if bits == 8 { 0xff } else { 0xffff }
  let value = hash.lxor(hash / 257) & mask
  if value == 0 {
    1
  } else {
    value
  }
}
