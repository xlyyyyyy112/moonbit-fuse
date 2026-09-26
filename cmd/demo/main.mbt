///|
fn main {
  let hashes = [101, 202, 303, 404, 505]
  let filter = @fuse.BinaryFuseFilter::build(hashes).unwrap()
  println("contains 303=\{filter.contains(303)}")
  println("contains 999=\{filter.contains(999)}")
  println("slots=\{filter.stats().array_length}")
}
