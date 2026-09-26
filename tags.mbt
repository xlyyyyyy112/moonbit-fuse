///|
pub fn TaggedFuseFilter::build(
  entries : Array[TaggedHash],
) -> Result[TaggedFuseFilter, FuseError] {
  if entries.length() == 0 {
    return Err(EmptyInput)
  }
  let sorted = entries.copy()
  sorted.sort_by((left, right) => {
    let order = left.tag.compare(right.tag)
    if order == 0 {
      left.hash.compare(right.hash)
    } else {
      order
    }
  })
  let tags : Array[Int] = []
  let filters : Array[BinaryFuseFilter] = []
  let mut cursor = 0
  while cursor < sorted.length() {
    let tag = sorted[cursor].tag
    if tag < 0 {
      return Err(InvalidTag(tag))
    }
    let hashes : Array[Int] = []
    while cursor < sorted.length() && sorted[cursor].tag == tag {
      hashes.push(sorted[cursor].hash)
      cursor = cursor + 1
    }
    match BinaryFuseFilter::build(hashes) {
      Ok(filter) => {
        tags.push(tag)
        filters.push(filter)
      }
      Err(error) => return Err(error)
    }
  }
  Ok({ tags, filters })
}

///|
pub fn TaggedFuseFilter::contains(
  self : TaggedFuseFilter,
  tag : Int,
  hash : Int,
) -> Bool {
  if tag < 0 || hash < 0 {
    return false
  }
  match self.find_filter(tag) {
    Some(filter) => filter.contains(hash)
    None => false
  }
}

///|
pub fn TaggedFuseFilter::tag_count(self : TaggedFuseFilter) -> Int {
  self.tags.length()
}

///|
pub fn TaggedFuseFilter::key_count(self : TaggedFuseFilter) -> Int {
  let mut total = 0
  for filter in self.filters {
    total = total + filter.len()
  }
  total
}

///|
pub fn TaggedFuseFilter::stats(self : TaggedFuseFilter) -> TagStats {
  let mut smallest_tag = 0
  let mut largest_tag = 0
  for tag in self.tags {
    if smallest_tag == 0 || tag < smallest_tag {
      smallest_tag = tag
    }
    if tag > largest_tag {
      largest_tag = tag
    }
  }
  {
    tag_count: self.tag_count(),
    key_count: self.key_count(),
    smallest_tag,
    largest_tag,
  }
}

///|
pub fn TaggedFuseFilter::validate(
  self : TaggedFuseFilter,
  entries : Array[TaggedHash],
) -> Bool {
  if self.tags.length() == 0 ||
    self.tags.length() != self.filters.length() ||
    entries.length() != self.key_count() {
    return false
  }
  for index in 1..<self.tags.length() {
    if self.tags[index - 1] >= self.tags[index] {
      return false
    }
  }
  for entry in entries {
    if entry.tag < 0 || entry.hash < 0 || !self.contains(entry.tag, entry.hash) {
      return false
    }
  }
  true
}

///|
fn TaggedFuseFilter::find_filter(
  self : TaggedFuseFilter,
  tag : Int,
) -> BinaryFuseFilter? {
  let mut low = 0
  let mut high = self.tags.length()
  while low < high {
    let middle = low + (high - low) / 2
    let candidate = self.tags[middle]
    if candidate == tag {
      return Some(self.filters[middle])
    }
    if candidate < tag {
      low = middle + 1
    } else {
      high = middle
    }
  }
  None
}
