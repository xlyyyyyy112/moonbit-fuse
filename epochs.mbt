///|
pub fn EpochFuseFilter::build(
  entries : Array[EpochHash],
) -> Result[EpochFuseFilter, FuseError] {
  if entries.length() == 0 {
    return Err(EmptyInput)
  }
  let sorted = entries.copy()
  sorted.sort_by((left, right) => {
    let order = left.epoch.compare(right.epoch)
    if order == 0 {
      left.hash.compare(right.hash)
    } else {
      order
    }
  })
  let epochs : Array[FuseEpoch] = []
  let mut cursor = 0
  while cursor < sorted.length() {
    let epoch = sorted[cursor].epoch
    let hashes : Array[Int] = []
    while cursor < sorted.length() && sorted[cursor].epoch == epoch {
      hashes.push(sorted[cursor].hash)
      cursor = cursor + 1
    }
    match BinaryFuseFilter::build(hashes) {
      Ok(filter) => epochs.push({ epoch, filter })
      Err(error) => return Err(error)
    }
  }
  Ok({ epochs, })
}

///|
pub fn EpochFuseFilter::contains_at(
  self : EpochFuseFilter,
  epoch : Int,
  hash : Int,
) -> Bool {
  match self.find_epoch(epoch) {
    Some(filter) => filter.contains(hash)
    None => false
  }
}

///|
pub fn EpochFuseFilter::contains_any(
  self : EpochFuseFilter,
  hash : Int,
) -> Bool {
  for item in self.epochs {
    if item.filter.contains(hash) {
      return true
    }
  }
  false
}

///|
pub fn EpochFuseFilter::epoch_count(self : EpochFuseFilter) -> Int {
  self.epochs.length()
}

///|
pub fn EpochFuseFilter::stats(self : EpochFuseFilter) -> EpochStats {
  let mut key_count = 0
  for item in self.epochs {
    key_count = key_count + item.filter.len()
  }
  {
    epoch_count: self.epochs.length(),
    key_count,
    first_epoch: self.epochs[0].epoch,
    last_epoch: self.epochs[self.epochs.length() - 1].epoch,
  }
}

///|
pub fn EpochFuseFilter::keep_from(
  self : EpochFuseFilter,
  minimum_epoch : Int,
) -> EpochFuseFilter {
  let epochs : Array[FuseEpoch] = []
  for item in self.epochs {
    if item.epoch >= minimum_epoch {
      epochs.push(item)
    }
  }
  { epochs, }
}

///|
pub fn EpochFuseFilter::validate(
  self : EpochFuseFilter,
  entries : Array[EpochHash],
) -> Bool {
  if self.epochs.length() == 0 {
    return false
  }
  for index in 1..<self.epochs.length() {
    if self.epochs[index - 1].epoch >= self.epochs[index].epoch {
      return false
    }
  }
  for entry in entries {
    if entry.hash < 0 || !self.contains_at(entry.epoch, entry.hash) {
      return false
    }
  }
  true
}

///|
fn EpochFuseFilter::find_epoch(
  self : EpochFuseFilter,
  epoch : Int,
) -> BinaryFuseFilter? {
  let mut low = 0
  let mut high = self.epochs.length()
  while low < high {
    let middle = low + (high - low) / 2
    let item = self.epochs[middle]
    if item.epoch == epoch {
      return Some(item.filter)
    }
    if item.epoch < epoch {
      low = middle + 1
    } else {
      high = middle
    }
  }
  None
}
