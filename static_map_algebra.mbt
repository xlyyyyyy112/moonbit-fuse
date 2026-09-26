///|
pub fn StaticIntMap::merge(
  self : StaticIntMap,
  other : StaticIntMap,
  policy : MapMergePolicy,
) -> Result[StaticIntMap, FuseError] {
  let entries : Array[FuseValue] = []
  let mut left = 0
  let mut right = 0
  while left < self.len() || right < other.len() {
    if right == other.len() ||
      (
        left < self.len() &&
        self.index.sorted_hashes[left] < other.index.sorted_hashes[right]
      ) {
      entries.push({
        hash: self.index.sorted_hashes[left],
        value: self.values[left],
      })
      left = left + 1
    } else if left == self.len() ||
      other.index.sorted_hashes[right] < self.index.sorted_hashes[left] {
      entries.push({
        hash: other.index.sorted_hashes[right],
        value: other.values[right],
      })
      right = right + 1
    } else {
      let hash = self.index.sorted_hashes[left]
      let left_value = self.values[left]
      let right_value = other.values[right]
      match resolve_value(hash, left_value, right_value, policy) {
        Ok(value) => entries.push({ hash, value })
        Err(error) => return Err(error)
      }
      left = left + 1
      right = right + 1
    }
  }
  StaticIntMap::build(entries)
}

///|
pub fn StaticIntMap::intersection(
  self : StaticIntMap,
  other : StaticIntMap,
  policy : MapMergePolicy,
) -> Result[StaticIntMap, FuseError] {
  let entries : Array[FuseValue] = []
  let mut left = 0
  let mut right = 0
  while left < self.len() && right < other.len() {
    let left_hash = self.index.sorted_hashes[left]
    let right_hash = other.index.sorted_hashes[right]
    if left_hash < right_hash {
      left = left + 1
    } else if right_hash < left_hash {
      right = right + 1
    } else {
      let left_value = self.values[left]
      let right_value = other.values[right]
      match resolve_value(left_hash, left_value, right_value, policy) {
        Ok(value) => entries.push({ hash: left_hash, value })
        Err(error) => return Err(error)
      }
      left = left + 1
      right = right + 1
    }
  }
  StaticIntMap::build(entries)
}

///|
pub fn StaticIntMap::difference(
  self : StaticIntMap,
  other : StaticIntMap,
) -> Result[StaticIntMap, FuseError] {
  let entries : Array[FuseValue] = []
  let mut left = 0
  let mut right = 0
  while left < self.len() {
    if right == other.len() {
      entries.push({
        hash: self.index.sorted_hashes[left],
        value: self.values[left],
      })
      left = left + 1
    } else if self.index.sorted_hashes[left] < other.index.sorted_hashes[right] {
      entries.push({
        hash: self.index.sorted_hashes[left],
        value: self.values[left],
      })
      left = left + 1
    } else if self.index.sorted_hashes[left] == other.index.sorted_hashes[right] {
      left = left + 1
      right = right + 1
    } else {
      right = right + 1
    }
  }
  StaticIntMap::build(entries)
}

///|
pub fn StaticIntMap::merge_stats(
  self : StaticIntMap,
  other : StaticIntMap,
) -> MapMergeStats {
  let mut left = 0
  let mut right = 0
  let mut left_only_count = 0
  let mut right_only_count = 0
  let mut shared_count = 0
  let mut conflicting_count = 0
  while left < self.len() || right < other.len() {
    if right == other.len() ||
      (
        left < self.len() &&
        self.index.sorted_hashes[left] < other.index.sorted_hashes[right]
      ) {
      left_only_count = left_only_count + 1
      left = left + 1
    } else if left == self.len() ||
      other.index.sorted_hashes[right] < self.index.sorted_hashes[left] {
      right_only_count = right_only_count + 1
      right = right + 1
    } else {
      shared_count = shared_count + 1
      if self.values[left] != other.values[right] {
        conflicting_count = conflicting_count + 1
      }
      left = left + 1
      right = right + 1
    }
  }
  { left_only_count, right_only_count, shared_count, conflicting_count }
}

///|
fn resolve_value(
  hash : Int,
  left : Int,
  right : Int,
  policy : MapMergePolicy,
) -> Result[Int, FuseError] {
  if left == right {
    return Ok(left)
  }
  match policy {
    PreferLeft => Ok(left)
    PreferRight => Ok(right)
    RejectConflicts => Err(ConflictingValue(hash))
  }
}
