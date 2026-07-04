///|
fn engine_nodes() -> Array[@moonshardkit.ShardNode] {
  [
    @moonshardkit.ShardNode::new("a", zone="z1"),
    @moonshardkit.ShardNode::new("b", zone="z2"),
    @moonshardkit.ShardNode::new("c", zone="z3"),
  ]
}

///|
test "unified entry supports all placement algorithms" {
  for
    algorithm in [
      @moonshardkit.PlacementAlgorithm::ConsistentRing,
      @moonshardkit.PlacementAlgorithm::Rendezvous,
      @moonshardkit.PlacementAlgorithm::TopologyAware,
    ] {
    let placement = @moonshardkit.place_key(
      engine_nodes(),
      "key",
      2,
      algorithm~,
    )
    assert_true(placement.complete)
    assert_eq(placement.owners.length(), 2)
  }
}

///|
test "unified entry preserves insufficient-node evidence" {
  let placement = @moonshardkit.place_key(
    [@moonshardkit.ShardNode::new("only")],
    "key",
    3,
  )
  assert_false(placement.complete)
  assert_eq(placement.owners.length(), 1)
}

///|
test "batch placement preserves input key order" {
  let placements = @moonshardkit.place_keys(
    engine_nodes(),
    ["third", "first", "second"],
    1,
  )
  assert_eq(placements.length(), 3)
  assert_eq(placements[0].key, "third")
  assert_eq(placements[1].key, "first")
  assert_eq(placements[2].key, "second")
}
