///|
fn topology_nodes() -> Array[@moonshardkit.ShardNode] {
  [
    @moonshardkit.ShardNode::new("a", zone="z1", rack="r1"),
    @moonshardkit.ShardNode::new("b", zone="z1", rack="r2"),
    @moonshardkit.ShardNode::new("c", zone="z2", rack="r1"),
    @moonshardkit.ShardNode::new("d", zone="z3", rack="r1"),
  ]
}

///|
fn zone_for(id : String) -> String {
  match id {
    "a" | "b" => "z1"
    "c" => "z2"
    "d" => "z3"
    _ => ""
  }
}

///|
test "replica placement prefers three distinct zones" {
  let placement = @moonshardkit.place_replicas(
    topology_nodes(),
    "order-1",
    3,
  )
  assert_true(placement.complete)
  assert_eq(placement.owners.length(), 3)
  assert_true(zone_for(placement.owners[0]) != zone_for(placement.owners[1]))
  assert_true(zone_for(placement.owners[1]) != zone_for(placement.owners[2]))
  assert_true(zone_for(placement.owners[0]) != zone_for(placement.owners[2]))
}

///|
test "replica placement falls back to distinct racks in one zone" {
  let nodes = [
    @moonshardkit.ShardNode::new("a", zone="z1", rack="r1"),
    @moonshardkit.ShardNode::new("b", zone="z1", rack="r2"),
  ]
  let placement = @moonshardkit.place_replicas(nodes, "key", 2)
  assert_true(placement.complete)
  assert_eq(placement.owners.length(), 2)
}

///|
test "replica placement reports insufficient eligible nodes" {
  let nodes = [
    @moonshardkit.ShardNode::new("a"),
    @moonshardkit.ShardNode::new("b").with_status(
      @moonshardkit.NodeStatus::Offline,
    ),
  ]
  let placement = @moonshardkit.place_replicas(nodes, "key", 2)
  assert_false(placement.complete)
  assert_eq(placement.owners.length(), 1)
  assert_eq(placement.message, "insufficient eligible nodes")
}

///|
test "replica placement is deterministic" {
  let first = @moonshardkit.place_replicas(topology_nodes(), "key-9", 3)
  let second = @moonshardkit.place_replicas(topology_nodes(), "key-9", 3)
  assert_true(first == second)
}

///|
test "zero replica request is complete and empty" {
  let placement = @moonshardkit.place_replicas(topology_nodes(), "key", 0)
  assert_true(placement.complete)
  assert_eq(placement.owners.length(), 0)
}
