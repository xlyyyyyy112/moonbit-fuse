///|
fn main {
  let hashes = [101, 202, 303, 404, 505]
  let filter = @fuse.BinaryFuseFilter::build(hashes).unwrap()
  println("contains 303=\{filter.contains(303)}")
  println("contains 999=\{filter.contains(999)}")
  println("slots=\{filter.stats().array_length}")

  let options : @fuse.BuildOptions = {
    fingerprint_bits: 16,
    max_attempts: 96,
    initial_seed: 7,
  }
  let headers = @fuse.StaticStringMap::build_with_options(
    [{ key: "content-type", value: 1 }, { key: "etag", value: 2 }],
    options,
  ).unwrap()
  println("etag present=\{headers.contains_key("etag")}")
  println(
    "string-map fingerprint bits=\{headers.filter_stats().fingerprint_bits}",
  )
}
