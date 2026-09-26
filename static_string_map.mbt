///|
pub fn StaticStringMap::build(
  entries : Array[StringFuseValue],
) -> Result[StaticStringMap, FuseError] {
  if entries.length() == 0 {
    return Err(EmptyInput)
  }
  let sorted = entries.copy()
  sorted.sort_by((left, right) => left.key.compare(right.key))
  for index in 1..<sorted.length() {
    if sorted[index - 1].key == sorted[index].key {
      return Err(DuplicateString(sorted[index].key))
    }
  }
  let keys : Array[String] = []
  for entry in sorted {
    keys.push(entry.key)
  }
  match StringFuseFilter::build(keys) {
    Ok(filter) => Ok({ filter, entries: sorted })
    Err(error) => Err(error)
  }
}

///|
pub fn StaticStringMap::get(self : StaticStringMap, key : String) -> Int? {
  if !self.filter.contains(key) {
    return None
  }
  match self.find_index(key) {
    Some(index) => Some(self.entries[index].value)
    None => None
  }
}

///|
pub fn StaticStringMap::contains_key(
  self : StaticStringMap,
  key : String,
) -> Bool {
  self.get(key) is Some(_)
}

///|
pub fn StaticStringMap::len(self : StaticStringMap) -> Int {
  self.entries.length()
}

///|
pub fn StaticStringMap::entries(
  self : StaticStringMap,
) -> Array[StringFuseValue] {
  self.entries.copy()
}

///|
pub fn StaticStringMap::get_all(
  self : StaticStringMap,
  keys : Array[String],
) -> Array[Int?] {
  let results : Array[Int?] = []
  for key in keys {
    results.push(self.get(key))
  }
  results
}

///|
pub fn StaticStringMap::with_updates(
  self : StaticStringMap,
  updates : Array[StringFuseValue],
) -> Result[StaticStringMap, FuseError] {
  if updates.length() == 0 {
    return Ok({ filter: self.filter, entries: self.entries.copy() })
  }
  let sorted_updates = updates.copy()
  sorted_updates.sort_by((left, right) => left.key.compare(right.key))
  for index in 1..<sorted_updates.length() {
    if sorted_updates[index - 1].key == sorted_updates[index].key {
      return Err(DuplicateString(sorted_updates[index].key))
    }
  }
  let combined : Array[StringFuseValue] = []
  let mut old_index = 0
  let mut update_index = 0
  while old_index < self.len() || update_index < sorted_updates.length() {
    if update_index == sorted_updates.length() ||
      (
        old_index < self.len() &&
        self.entries[old_index].key.compare(sorted_updates[update_index].key) <
        0
      ) {
      combined.push(self.entries[old_index])
      old_index = old_index + 1
    } else if old_index == self.len() ||
      sorted_updates[update_index].key.compare(self.entries[old_index].key) < 0 {
      combined.push(sorted_updates[update_index])
      update_index = update_index + 1
    } else {
      combined.push(sorted_updates[update_index])
      old_index = old_index + 1
      update_index = update_index + 1
    }
  }
  StaticStringMap::build(combined)
}

///|
pub fn StaticStringMap::without_keys(
  self : StaticStringMap,
  keys : Array[String],
) -> Result[StaticStringMap, FuseError] {
  let sorted_keys = keys.copy()
  sorted_keys.sort_by((left, right) => left.compare(right))
  let kept : Array[StringFuseValue] = []
  for entry in self.entries {
    if !sorted_string_contains(sorted_keys, entry.key) {
      kept.push(entry)
    }
  }
  StaticStringMap::build(kept)
}

///|
pub fn StaticStringMap::stats(self : StaticStringMap) -> StringMapStats {
  let mut shortest_key_length = self.entries[0].key.length()
  let mut longest_key_length = shortest_key_length
  for entry in self.entries {
    let length = entry.key.length()
    if length < shortest_key_length {
      shortest_key_length = length
    }
    if length > longest_key_length {
      longest_key_length = length
    }
  }
  { entry_count: self.len(), shortest_key_length, longest_key_length }
}

///|
pub fn StaticStringMap::validate(self : StaticStringMap) -> Bool {
  if self.entries.length() == 0 {
    return false
  }
  let hashes : Array[Int] = []
  for index in 0..<self.entries.length() {
    if index > 0 &&
      self.entries[index - 1].key.compare(self.entries[index].key) >= 0 {
      return false
    }
    hashes.push(stable_string_hash(self.entries[index].key))
  }
  self.filter.filter.validate(hashes)
}

///|
fn StaticStringMap::find_index(self : StaticStringMap, key : String) -> Int? {
  let mut low = 0
  let mut high = self.entries.length()
  while low < high {
    let middle = low + (high - low) / 2
    let candidate = self.entries[middle].key
    if candidate == key {
      return Some(middle)
    }
    if candidate < key {
      low = middle + 1
    } else {
      high = middle
    }
  }
  None
}

///|
fn sorted_string_contains(values : Array[String], needle : String) -> Bool {
  let mut low = 0
  let mut high = values.length()
  while low < high {
    let middle = low + (high - low) / 2
    if values[middle] == needle {
      return true
    }
    if values[middle].compare(needle) < 0 {
      low = middle + 1
    } else {
      high = middle
    }
  }
  false
}
