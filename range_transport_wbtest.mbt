///|
test "integer maps support ordered lookup and bounded pages" {
  let map = StaticIntMap::build([
    { hash: 10, value: 1 },
    { hash: 20, value: 2 },
    { hash: 30, value: 3 },
    { hash: 40, value: 4 },
  ]).unwrap()
  assert_eq(map.keys(), [10, 20, 30, 40])
  assert_eq(map.rank(5), 0)
  assert_eq(map.rank(20), 1)
  assert_eq(map.rank(21), 2)
  assert_true(map.get_floor(5) is None)
  assert_eq(map.get_floor(21).unwrap().hash, 20)
  assert_eq(map.get_ceiling(21).unwrap().hash, 30)
  assert_true(map.get_ceiling(41) is None)
  let range = map.entries_inclusive(15, 35)
  assert_eq(range.length(), 2)
  assert_eq(range[0].hash, 20)
  assert_eq(range[1].value, 3)
  assert_eq(map.entries_from(20, 2).length(), 2)
  assert_eq(map.entries_from(20, 0).length(), 0)
  let before = map.entries_before(40, 2)
  assert_eq(before.length(), 2)
  assert_eq(before[0].hash, 20)
  assert_eq(before[1].hash, 30)
}

///|
test "string maps expose MoonBit shortlex range queries" {
  let map = StaticStringMap::build([
    { key: "ant", value: 1 },
    { key: "bee", value: 2 },
    { key: "cat", value: 3 },
    { key: "dog", value: 4 },
  ]).unwrap()
  assert_eq(map.keys(), ["ant", "bee", "cat", "dog"])
  assert_eq(map.rank("bird"), 4)
  assert_eq(map.get_floor("bird").unwrap().key, "dog")
  assert_true(map.get_ceiling("bird") is None)
  let range = map.entries_between("bee", "cat")
  assert_eq(range.length(), 2)
  assert_eq(range[0].value, 2)
  assert_eq(range[1].key, "cat")
  assert_eq(map.entries_from("cat", 1)[0].key, "cat")
  assert_eq(map.entries_from("cat", 0).length(), 0)
  let before = map.entries_before("bird", 2)
  assert_eq(before.length(), 2)
  assert_eq(before[0].key, "cat")
  assert_eq(before[1].key, "dog")
}

///|
test "transport adapters preserve container-specific validation" {
  let sharded = ShardedFuseFilter::build([1, 2, 3, 4, 5], 2).unwrap()
  assert_true(
    decode_sharded_transport(sharded.encode_transport().unwrap())
    .unwrap()
    .validate([1, 2, 3, 4, 5]),
  )
  let map = StaticIntMap::build([{ hash: 7, value: 70 }]).unwrap()
  let loaded = decode_static_map_transport(map.encode_transport().unwrap()).unwrap()
  assert_eq(loaded.get(7), Some(70))
  let diff = VerifiedFuseFilter::build([1, 2])
    .unwrap()
    .diff(VerifiedFuseFilter::build([2, 3]).unwrap())
  assert_eq(
    decode_snapshot_diff_transport(diff.encode_transport().unwrap())
    .unwrap()
    .change_count(),
    2,
  )
}
