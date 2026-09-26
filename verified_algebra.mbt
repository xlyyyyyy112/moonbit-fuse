///|
pub fn VerifiedFuseFilter::union(
  self : VerifiedFuseFilter,
  other : VerifiedFuseFilter,
) -> Result[VerifiedFuseFilter, FuseError] {
  let values : Array[Int] = []
  let mut left = 0
  let mut right = 0
  while left < self.sorted_hashes.length() ||
        right < other.sorted_hashes.length() {
    if right == other.sorted_hashes.length() ||
      (
        left < self.sorted_hashes.length() &&
        self.sorted_hashes[left] < other.sorted_hashes[right]
      ) {
      values.push(self.sorted_hashes[left])
      left = left + 1
    } else if left == self.sorted_hashes.length() ||
      other.sorted_hashes[right] < self.sorted_hashes[left] {
      values.push(other.sorted_hashes[right])
      right = right + 1
    } else {
      values.push(self.sorted_hashes[left])
      left = left + 1
      right = right + 1
    }
  }
  VerifiedFuseFilter::build(values)
}

///|
pub fn VerifiedFuseFilter::intersection(
  self : VerifiedFuseFilter,
  other : VerifiedFuseFilter,
) -> Result[VerifiedFuseFilter, FuseError] {
  let values : Array[Int] = []
  let mut left = 0
  let mut right = 0
  while left < self.sorted_hashes.length() &&
        right < other.sorted_hashes.length() {
    let left_value = self.sorted_hashes[left]
    let right_value = other.sorted_hashes[right]
    if left_value == right_value {
      values.push(left_value)
      left = left + 1
      right = right + 1
    } else if left_value < right_value {
      left = left + 1
    } else {
      right = right + 1
    }
  }
  VerifiedFuseFilter::build(values)
}

///|
pub fn VerifiedFuseFilter::difference(
  self : VerifiedFuseFilter,
  other : VerifiedFuseFilter,
) -> Result[VerifiedFuseFilter, FuseError] {
  let values : Array[Int] = []
  let mut left = 0
  let mut right = 0
  while left < self.sorted_hashes.length() {
    if right == other.sorted_hashes.length() {
      values.push(self.sorted_hashes[left])
      left = left + 1
    } else if self.sorted_hashes[left] == other.sorted_hashes[right] {
      left = left + 1
      right = right + 1
    } else if self.sorted_hashes[left] < other.sorted_hashes[right] {
      values.push(self.sorted_hashes[left])
      left = left + 1
    } else {
      right = right + 1
    }
  }
  VerifiedFuseFilter::build(values)
}

///|
pub fn VerifiedFuseFilter::symmetric_difference(
  self : VerifiedFuseFilter,
  other : VerifiedFuseFilter,
) -> Result[VerifiedFuseFilter, FuseError] {
  let values : Array[Int] = []
  let mut left = 0
  let mut right = 0
  while left < self.sorted_hashes.length() ||
        right < other.sorted_hashes.length() {
    if right == other.sorted_hashes.length() ||
      (
        left < self.sorted_hashes.length() &&
        self.sorted_hashes[left] < other.sorted_hashes[right]
      ) {
      values.push(self.sorted_hashes[left])
      left = left + 1
    } else if left == self.sorted_hashes.length() ||
      other.sorted_hashes[right] < self.sorted_hashes[left] {
      values.push(other.sorted_hashes[right])
      right = right + 1
    } else {
      left = left + 1
      right = right + 1
    }
  }
  VerifiedFuseFilter::build(values)
}
