///|
pub fn StaticIntMap::build(
  entries : Array[FuseValue],
) -> Result[StaticIntMap, FuseError] {
  if entries.length() == 0 {
    return Err(EmptyInput)
  }
  let sorted = entries.copy()
  sorted.sort_by((left, right) => left.hash.compare(right.hash))
  let hashes : Array[Int] = []
  let values : Array[Int] = []
  for entry in sorted {
    hashes.push(entry.hash)
    values.push(entry.value)
  }
  match VerifiedFuseFilter::build(hashes) {
    Ok(index) => Ok({ index, values })
    Err(error) => Err(error)
  }
}

///|
pub fn StaticIntMap::get(self : StaticIntMap, hash : Int) -> Int? {
  if !self.index.may_contain(hash) {
    return None
  }
  match self.find_index(hash) {
    Some(index) => Some(self.values[index])
    None => None
  }
}

///|
pub fn StaticIntMap::contains_key(self : StaticIntMap, hash : Int) -> Bool {
  self.get(hash) is Some(_)
}

///|
pub fn StaticIntMap::len(self : StaticIntMap) -> Int {
  self.values.length()
}

///|
pub fn StaticIntMap::entries(self : StaticIntMap) -> Array[FuseValue] {
  let entries : Array[FuseValue] = []
  for index in 0..<self.values.length() {
    entries.push({
      hash: self.index.sorted_hashes[index],
      value: self.values[index],
    })
  }
  entries
}

///|
pub fn StaticIntMap::get_all(
  self : StaticIntMap,
  hashes : Array[Int],
) -> Array[Int?] {
  let results : Array[Int?] = []
  for hash in hashes {
    results.push(self.get(hash))
  }
  results
}

///|
pub fn StaticIntMap::with_updates(
  self : StaticIntMap,
  updates : Array[FuseValue],
) -> Result[StaticIntMap, FuseError] {
  if updates.length() == 0 {
    return Ok({ index: self.index, values: self.values.copy() })
  }
  let sorted_updates = updates.copy()
  sorted_updates.sort_by((left, right) => left.hash.compare(right.hash))
  for index in 1..<sorted_updates.length() {
    if sorted_updates[index - 1].hash == sorted_updates[index].hash {
      return Err(DuplicateHash(sorted_updates[index].hash))
    }
  }
  let combined : Array[FuseValue] = []
  let mut old_index = 0
  let mut update_index = 0
  while old_index < self.len() || update_index < sorted_updates.length() {
    if update_index == sorted_updates.length() ||
      (
        old_index < self.len() &&
        self.index.sorted_hashes[old_index] < sorted_updates[update_index].hash
      ) {
      combined.push({
        hash: self.index.sorted_hashes[old_index],
        value: self.values[old_index],
      })
      old_index = old_index + 1
    } else if old_index == self.len() ||
      sorted_updates[update_index].hash < self.index.sorted_hashes[old_index] {
      combined.push(sorted_updates[update_index])
      update_index = update_index + 1
    } else {
      combined.push(sorted_updates[update_index])
      old_index = old_index + 1
      update_index = update_index + 1
    }
  }
  StaticIntMap::build(combined)
}

///|
pub fn StaticIntMap::without_keys(
  self : StaticIntMap,
  hashes : Array[Int],
) -> Result[StaticIntMap, FuseError] {
  let removals = hashes.copy()
  removals.sort()
  let kept : Array[FuseValue] = []
  for entry in self.entries() {
    if !sorted_contains(removals, entry.hash) {
      kept.push(entry)
    }
  }
  StaticIntMap::build(kept)
}

///|
pub fn StaticIntMap::stats(self : StaticIntMap) -> MapStats {
  {
    entry_count: self.len(),
    smallest_key: self.index.sorted_hashes[0],
    largest_key: self.index.sorted_hashes[self.len() - 1],
  }
}

///|
pub fn StaticIntMap::validate(self : StaticIntMap) -> Bool {
  if self.values.length() == 0 ||
    self.values.length() != self.index.len() ||
    !self.index.validate() {
    return false
  }
  for index in 1..<self.index.sorted_hashes.length() {
    if self.index.sorted_hashes[index - 1] >= self.index.sorted_hashes[index] {
      return false
    }
  }
  true
}

///|
fn StaticIntMap::find_index(self : StaticIntMap, hash : Int) -> Int? {
  let mut low = 0
  let mut high = self.index.sorted_hashes.length()
  while low < high {
    let middle = low + (high - low) / 2
    let candidate = self.index.sorted_hashes[middle]
    if candidate == hash {
      return Some(middle)
    }
    if candidate < hash {
      low = middle + 1
    } else {
      high = middle
    }
  }
  None
}
