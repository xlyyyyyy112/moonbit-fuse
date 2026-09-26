///|
pub fn FuseBuilder::new() -> FuseBuilder {
  { hashes: [] }
}

///|
pub fn FuseBuilder::with_capacity(_capacity : Int) -> FuseBuilder {
  // ponytail: MoonBit Array has no reserve API; keep one allocation path.
  let hashes : Array[Int] = []
  { hashes, }
}

///|
pub fn FuseBuilder::add(
  self : FuseBuilder,
  hash : Int,
) -> Result[Unit, FuseError] {
  if hash < 0 {
    return Err(NegativeHash(hash))
  }
  self.hashes.push(hash)
  Ok(())
}

///|
pub fn FuseBuilder::add_all(
  self : FuseBuilder,
  hashes : Array[Int],
) -> Result[Unit, FuseError] {
  for hash in hashes {
    match self.add(hash) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(())
}

///|
pub fn FuseBuilder::len(self : FuseBuilder) -> Int {
  self.hashes.length()
}

///|
pub fn FuseBuilder::build(
  self : FuseBuilder,
) -> Result[BinaryFuseFilter, FuseError] {
  BinaryFuseFilter::build(self.hashes)
}

///|
pub fn FuseBuilder::build16(
  self : FuseBuilder,
) -> Result[BinaryFuseFilter, FuseError] {
  BinaryFuseFilter::build16(self.hashes)
}

///|
pub fn FuseBuilder::clear(self : FuseBuilder) -> Unit {
  self.hashes.clear()
}
