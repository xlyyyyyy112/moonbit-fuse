///|
pub fn StaticStringMap::keys(self : StaticStringMap) -> Array[String] {
  let keys : Array[String] = []
  for entry in self.entries {
    keys.push(entry.key)
  }
  keys
}

///|
/// Uses MoonBit's `String::compare` shortlex ordering (length, then charcode).
pub fn StaticStringMap::get_floor(
  self : StaticStringMap,
  key : String,
) -> StringFuseValue? {
  let index = self.lower_bound(key)
  if index < self.len() && self.entries[index].key == key {
    Some(self.entries[index])
  } else if index == 0 {
    None
  } else {
    Some(self.entries[index - 1])
  }
}

///|
/// Uses MoonBit's `String::compare` shortlex ordering (length, then charcode).
pub fn StaticStringMap::get_ceiling(
  self : StaticStringMap,
  key : String,
) -> StringFuseValue? {
  let index = self.lower_bound(key)
  if index == self.len() {
    None
  } else {
    Some(self.entries[index])
  }
}

///|
/// Returns entries in MoonBit `String::compare` shortlex order.
pub fn StaticStringMap::entries_between(
  self : StaticStringMap,
  first_key : String,
  last_key : String,
) -> Array[StringFuseValue] {
  if first_key.compare(last_key) > 0 {
    return []
  }
  let entries : Array[StringFuseValue] = []
  let mut index = self.lower_bound(first_key)
  while index < self.len() && self.entries[index].key.compare(last_key) <= 0 {
    entries.push(self.entries[index])
    index = index + 1
  }
  entries
}

///|
/// Returns a shortlex-ordered page beginning at the first matching key.
pub fn StaticStringMap::entries_from(
  self : StaticStringMap,
  first_key : String,
  limit : Int,
) -> Array[StringFuseValue] {
  if limit <= 0 {
    return []
  }
  let entries : Array[StringFuseValue] = []
  let mut index = self.lower_bound(first_key)
  while index < self.len() && entries.length() < limit {
    entries.push(self.entries[index])
    index = index + 1
  }
  entries
}

///|
/// Returns up to `limit` shortlex-ordered entries strictly before `first_key`.
pub fn StaticStringMap::entries_before(
  self : StaticStringMap,
  first_key : String,
  limit : Int,
) -> Array[StringFuseValue] {
  if limit <= 0 {
    return []
  }
  let end = self.lower_bound(first_key)
  let start = if end > limit { end - limit } else { 0 }
  let entries : Array[StringFuseValue] = []
  for index in start..<end {
    entries.push(self.entries[index])
  }
  entries
}

///|
/// Returns the insertion rank under MoonBit `String::compare` shortlex order.
pub fn StaticStringMap::rank(self : StaticStringMap, key : String) -> Int {
  self.lower_bound(key)
}

///|
fn StaticStringMap::lower_bound(self : StaticStringMap, key : String) -> Int {
  let mut low = 0
  let mut high = self.len()
  while low < high {
    let middle = low + (high - low) / 2
    if self.entries[middle].key.compare(key) < 0 {
      low = middle + 1
    } else {
      high = middle
    }
  }
  low
}
