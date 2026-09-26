///|
pub fn StaticIntMap::keys(self : StaticIntMap) -> Array[Int] {
  self.index.hashes()
}

///|
pub fn StaticIntMap::get_floor(self : StaticIntMap, key : Int) -> FuseValue? {
  let index = self.lower_bound(key)
  if index < self.len() && self.index.sorted_hashes[index] == key {
    Some({ hash: key, value: self.values[index] })
  } else if index == 0 {
    None
  } else {
    let previous = index - 1
    Some({
      hash: self.index.sorted_hashes[previous],
      value: self.values[previous],
    })
  }
}

///|
pub fn StaticIntMap::get_ceiling(self : StaticIntMap, key : Int) -> FuseValue? {
  let index = self.lower_bound(key)
  if index == self.len() {
    None
  } else {
    Some({ hash: self.index.sorted_hashes[index], value: self.values[index] })
  }
}

///|
pub fn StaticIntMap::entries_inclusive(
  self : StaticIntMap,
  first_key : Int,
  last_key : Int,
) -> Array[FuseValue] {
  if first_key > last_key {
    return []
  }
  let entries : Array[FuseValue] = []
  let mut index = self.lower_bound(first_key)
  while index < self.len() && self.index.sorted_hashes[index] <= last_key {
    entries.push({
      hash: self.index.sorted_hashes[index],
      value: self.values[index],
    })
    index = index + 1
  }
  entries
}

///|
pub fn StaticIntMap::entries_from(
  self : StaticIntMap,
  first_key : Int,
  limit : Int,
) -> Array[FuseValue] {
  if limit <= 0 {
    return []
  }
  let entries : Array[FuseValue] = []
  let mut index = self.lower_bound(first_key)
  while index < self.len() && entries.length() < limit {
    entries.push({
      hash: self.index.sorted_hashes[index],
      value: self.values[index],
    })
    index = index + 1
  }
  entries
}

///|
pub fn StaticIntMap::entries_before(
  self : StaticIntMap,
  first_key : Int,
  limit : Int,
) -> Array[FuseValue] {
  if limit <= 0 {
    return []
  }
  let end = self.lower_bound(first_key)
  let start = if end > limit { end - limit } else { 0 }
  let entries : Array[FuseValue] = []
  for index in start..<end {
    entries.push({
      hash: self.index.sorted_hashes[index],
      value: self.values[index],
    })
  }
  entries
}

///|
pub fn StaticIntMap::rank(self : StaticIntMap, key : Int) -> Int {
  self.lower_bound(key)
}

///|
fn StaticIntMap::lower_bound(self : StaticIntMap, key : Int) -> Int {
  let mut low = 0
  let mut high = self.len()
  while low < high {
    let middle = low + (high - low) / 2
    if self.index.sorted_hashes[middle] < key {
      low = middle + 1
    } else {
      high = middle
    }
  }
  low
}
