///|
pub fn FuseFilterChain::from_filters(
  filters : Array[BinaryFuseFilter],
) -> FuseFilterChain {
  { filters: filters.copy() }
}

///|
pub fn FuseFilterChain::contains(self : FuseFilterChain, hash : Int) -> Bool {
  for filter in self.filters {
    if filter.contains(hash) {
      return true
    }
  }
  false
}

///|
pub fn FuseFilterChain::filter_count(self : FuseFilterChain) -> Int {
  self.filters.length()
}

///|
pub fn FuseFilterChain::key_count(self : FuseFilterChain) -> Int {
  let mut count = 0
  for filter in self.filters {
    count = count + filter.len()
  }
  count
}

///|
pub fn FuseFilterChain::query_all(
  self : FuseFilterChain,
  hashes : Array[Int],
) -> QuerySummary {
  let mut positive_count = 0
  for hash in hashes {
    if self.contains(hash) {
      positive_count = positive_count + 1
    }
  }
  {
    query_count: hashes.length(),
    positive_count,
    negative_count: hashes.length() - positive_count,
  }
}
