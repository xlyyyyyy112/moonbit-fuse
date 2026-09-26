///|
pub fn VerifiedFuseFilter::build(
  hashes : Array[Int],
) -> Result[VerifiedFuseFilter, FuseError] {
  VerifiedFuseFilter::build_with_options(hashes, default_build_options())
}

///|
pub fn VerifiedFuseFilter::build_with_options(
  hashes : Array[Int],
  options : BuildOptions,
) -> Result[VerifiedFuseFilter, FuseError] {
  match BinaryFuseFilter::build_with_options(hashes, options) {
    Err(error) => Err(error)
    Ok(filter) => {
      let sorted_hashes = hashes.copy()
      sorted_hashes.sort()
      Ok({ filter, sorted_hashes })
    }
  }
}

///|
pub fn VerifiedFuseFilter::may_contain(
  self : VerifiedFuseFilter,
  hash : Int,
) -> Bool {
  self.filter.contains(hash)
}

///|
pub fn VerifiedFuseFilter::contains_exact(
  self : VerifiedFuseFilter,
  hash : Int,
) -> Bool {
  if !self.filter.contains(hash) {
    return false
  }
  let mut low = 0
  let mut high = self.sorted_hashes.length()
  while low < high {
    let middle = low + (high - low) / 2
    let value = self.sorted_hashes[middle]
    if value == hash {
      return true
    }
    if value < hash {
      low = middle + 1
    } else {
      high = middle
    }
  }
  false
}

///|
pub fn VerifiedFuseFilter::len(self : VerifiedFuseFilter) -> Int {
  self.sorted_hashes.length()
}

///|
pub fn VerifiedFuseFilter::hashes(self : VerifiedFuseFilter) -> Array[Int] {
  self.sorted_hashes.copy()
}

///|
pub fn VerifiedFuseFilter::validate(self : VerifiedFuseFilter) -> Bool {
  if self.filter.len() != self.sorted_hashes.length() ||
    self.sorted_hashes.length() == 0 {
    return false
  }
  for index in 0..<self.sorted_hashes.length() {
    if index > 0 && self.sorted_hashes[index - 1] >= self.sorted_hashes[index] {
      return false
    }
    if !self.filter.contains(self.sorted_hashes[index]) {
      return false
    }
  }
  true
}

///|
pub fn VerifiedFuseFilter::apply_patch(
  self : VerifiedFuseFilter,
  patch : FusePatch,
) -> Result[VerifiedFuseFilter, FuseError] {
  match validate_input(patch.additions, default_build_options()) {
    Err(EmptyInput) => ()
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match validate_input(patch.removals, default_build_options()) {
    Err(EmptyInput) => ()
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let source = self.hashes()
  let additions = patch.additions.copy()
  let removals = patch.removals.copy()
  additions.sort()
  removals.sort()
  let next : Array[Int] = []
  for hash in source {
    if !sorted_contains(removals, hash) {
      next.push(hash)
    }
  }
  for hash in additions {
    if sorted_contains(next, hash) {
      return Err(DuplicateHash(hash))
    }
    next.push(hash)
  }
  VerifiedFuseFilter::build(next)
}

///|
pub fn empty_patch() -> FusePatch {
  { additions: [], removals: [] }
}

///|
fn sorted_contains(values : Array[Int], needle : Int) -> Bool {
  let mut low = 0
  let mut high = values.length()
  while low < high {
    let middle = low + (high - low) / 2
    if values[middle] == needle {
      return true
    }
    if values[middle] < needle {
      low = middle + 1
    } else {
      high = middle
    }
  }
  false
}
