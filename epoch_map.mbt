///|
pub fn EpochStaticIntMap::build(
  entries : Array[EpochFuseValue],
) -> Result[EpochStaticIntMap, FuseError] {
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
  let epochs : Array[FuseMapEpoch] = []
  let mut cursor = 0
  while cursor < sorted.length() {
    let epoch = sorted[cursor].epoch
    let values : Array[FuseValue] = []
    while cursor < sorted.length() && sorted[cursor].epoch == epoch {
      values.push({ hash: sorted[cursor].hash, value: sorted[cursor].value })
      cursor = cursor + 1
    }
    match StaticIntMap::build(values) {
      Ok(map) => epochs.push({ epoch, map })
      Err(error) => return Err(error)
    }
  }
  Ok({ epochs, })
}

///|
pub fn EpochStaticIntMap::get_at(
  self : EpochStaticIntMap,
  epoch : Int,
  hash : Int,
) -> Int? {
  match self.find_epoch(epoch) {
    Some(map) => map.get(hash)
    None => None
  }
}

///|
pub fn EpochStaticIntMap::get_at_or_before(
  self : EpochStaticIntMap,
  epoch : Int,
  hash : Int,
) -> Int? {
  let mut low = 0
  let mut high = self.epochs.length()
  while low < high {
    let middle = low + (high - low) / 2
    if self.epochs[middle].epoch <= epoch {
      low = middle + 1
    } else {
      high = middle
    }
  }
  if low == 0 {
    None
  } else {
    self.epochs[low - 1].map.get(hash)
  }
}

///|
pub fn EpochStaticIntMap::epoch_count(self : EpochStaticIntMap) -> Int {
  self.epochs.length()
}

///|
pub fn EpochStaticIntMap::entry_count(self : EpochStaticIntMap) -> Int {
  let mut count = 0
  for item in self.epochs {
    count = count + item.map.len()
  }
  count
}

///|
pub fn EpochStaticIntMap::keep_from(
  self : EpochStaticIntMap,
  minimum_epoch : Int,
) -> EpochStaticIntMap {
  let epochs : Array[FuseMapEpoch] = []
  for item in self.epochs {
    if item.epoch >= minimum_epoch {
      epochs.push(item)
    }
  }
  { epochs, }
}

///|
pub fn EpochStaticIntMap::stats(self : EpochStaticIntMap) -> EpochMapStats {
  let epoch_count = self.epochs.length()
  {
    epoch_count,
    entry_count: self.entry_count(),
    first_epoch: if epoch_count == 0 {
      0
    } else {
      self.epochs[0].epoch
    },
    last_epoch: if epoch_count == 0 {
      0
    } else {
      self.epochs[epoch_count - 1].epoch
    },
  }
}

///|
pub fn EpochStaticIntMap::validate(self : EpochStaticIntMap) -> Bool {
  if self.epochs.length() == 0 {
    return true
  }
  for index in 0..<self.epochs.length() {
    if !self.epochs[index].map.validate() ||
      (index > 0 && self.epochs[index - 1].epoch >= self.epochs[index].epoch) {
      return false
    }
  }
  true
}

///|
fn EpochStaticIntMap::find_epoch(
  self : EpochStaticIntMap,
  epoch : Int,
) -> StaticIntMap? {
  let mut low = 0
  let mut high = self.epochs.length()
  while low < high {
    let middle = low + (high - low) / 2
    let candidate = self.epochs[middle]
    if candidate.epoch == epoch {
      return Some(candidate.map)
    }
    if candidate.epoch < epoch {
      low = middle + 1
    } else {
      high = middle
    }
  }
  None
}
