///|
pub fn VerifiedFuseFilter::diff(
  self : VerifiedFuseFilter,
  target : VerifiedFuseFilter,
) -> SnapshotDiff {
  let additions : Array[Int] = []
  let removals : Array[Int] = []
  let mut shared_count = 0
  let mut source_index = 0
  let mut target_index = 0
  while source_index < self.len() || target_index < target.len() {
    if target_index == target.len() ||
      (
        source_index < self.len() &&
        self.sorted_hashes[source_index] < target.sorted_hashes[target_index]
      ) {
      removals.push(self.sorted_hashes[source_index])
      source_index = source_index + 1
    } else if source_index == self.len() ||
      target.sorted_hashes[target_index] < self.sorted_hashes[source_index] {
      additions.push(target.sorted_hashes[target_index])
      target_index = target_index + 1
    } else {
      shared_count = shared_count + 1
      source_index = source_index + 1
      target_index = target_index + 1
    }
  }
  { additions, removals, shared_count }
}

///|
pub fn SnapshotDiff::is_empty(self : SnapshotDiff) -> Bool {
  self.additions.length() == 0 && self.removals.length() == 0
}

///|
pub fn SnapshotDiff::change_count(self : SnapshotDiff) -> Int {
  self.additions.length() + self.removals.length()
}

///|
pub fn SnapshotDiff::to_patch(self : SnapshotDiff) -> FusePatch {
  { additions: self.additions.copy(), removals: self.removals.copy() }
}

///|
pub fn SnapshotDiff::apply_to(
  self : SnapshotDiff,
  source : VerifiedFuseFilter,
) -> Result[VerifiedFuseFilter, FuseError] {
  source.apply_patch(self.to_patch())
}

///|
pub fn SnapshotDiff::validate(self : SnapshotDiff) -> Bool {
  if !strictly_increasing(self.additions) || !strictly_increasing(self.removals) {
    return false
  }
  for hash in self.additions {
    if sorted_contains(self.removals, hash) {
      return false
    }
  }
  true
}

///|
fn strictly_increasing(values : Array[Int]) -> Bool {
  for index in 0..<values.length() {
    if values[index] < 0 || (index > 0 && values[index - 1] >= values[index]) {
      return false
    }
  }
  true
}
