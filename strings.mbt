///|
pub fn stable_string_hash(value : String) -> Int {
  let mut state = 1_469_598_103
  for character in value.to_array() {
    state = ((state ^ character.to_int()) * 16_777_619) & positive_mask
  }
  mix_hash(state, 0x4a7c15)
}

///|
pub fn StringFuseFilter::build(
  values : Array[String],
) -> Result[StringFuseFilter, FuseError] {
  StringFuseFilter::build_with_options(values, default_build_options())
}

///|
pub fn StringFuseFilter::build_with_options(
  values : Array[String],
  options : BuildOptions,
) -> Result[StringFuseFilter, FuseError] {
  let hashes : Array[Int] = []
  for value in values {
    hashes.push(stable_string_hash(value))
  }
  match BinaryFuseFilter::build_with_options(hashes, options) {
    Ok(filter) => Ok({ filter, })
    Err(error) => Err(error)
  }
}

///|
pub fn StringFuseFilter::build16(
  values : Array[String],
) -> Result[StringFuseFilter, FuseError] {
  let hashes : Array[Int] = []
  for value in values {
    hashes.push(stable_string_hash(value))
  }
  match BinaryFuseFilter::build16(hashes) {
    Ok(filter) => Ok({ filter, })
    Err(error) => Err(error)
  }
}

///|
pub fn StringFuseFilter::contains(
  self : StringFuseFilter,
  value : String,
) -> Bool {
  self.filter.contains(stable_string_hash(value))
}

///|
pub fn StringFuseFilter::len(self : StringFuseFilter) -> Int {
  self.filter.len()
}

///|
pub fn StringFuseFilter::stats(self : StringFuseFilter) -> BuildStats {
  self.filter.stats()
}
