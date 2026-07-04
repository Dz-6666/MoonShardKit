///|
fn ring_nodes() -> Array[@moonshardkit.ShardNode] {
  [
    @moonshardkit.ShardNode::new("a", virtual_nodes=32),
    @moonshardkit.ShardNode::new("b", virtual_nodes=32),
    @moonshardkit.ShardNode::new("c", virtual_nodes=32),
  ]
}

///|
test "ring has weighted virtual point count" {
  let nodes = [
    @moonshardkit.ShardNode::new("a", weight=1, virtual_nodes=10),
    @moonshardkit.ShardNode::new("b", weight=3, virtual_nodes=10),
  ]
  let ring = @moonshardkit.ConsistentHashRing::build(nodes)
  assert_eq(ring.node_count(), 2)
  assert_eq(ring.point_count(), 40)
}

///|
test "ring owner is deterministic" {
  let first = @moonshardkit.ConsistentHashRing::build(ring_nodes(), seed=7U)
  let second = @moonshardkit.ConsistentHashRing::build(ring_nodes(), seed=7U)
  assert_true(first.owner("customer-42") == second.owner("customer-42"))
  assert_true(first.owner("customer-42") is Some(_))
}

///|
test "ring replicas contain distinct real nodes" {
  let ring = @moonshardkit.ConsistentHashRing::build(ring_nodes())
  let owners = ring.owners("order-7", 3)
  assert_eq(owners.length(), 3)
  assert_true(owners[0] != owners[1])
  assert_true(owners[1] != owners[2])
  assert_true(owners[0] != owners[2])
}

///|
test "ring caps replica count at eligible nodes" {
  let ring = @moonshardkit.ConsistentHashRing::build(ring_nodes())
  assert_eq(ring.owners("key", 99).length(), 3)
}

///|
test "ring excludes draining and offline nodes" {
  let nodes = [
    @moonshardkit.ShardNode::new("active"),
    @moonshardkit.ShardNode::new("draining").with_status(
      @moonshardkit.NodeStatus::Draining,
    ),
    @moonshardkit.ShardNode::new("offline").with_status(
      @moonshardkit.NodeStatus::Offline,
    ),
  ]
  let ring = @moonshardkit.ConsistentHashRing::build(nodes)
  assert_eq(ring.node_count(), 1)
  assert_true(ring.owner("any") == Some("active"))
}

///|
test "empty ring has no owner" {
  let nodes : Array[@moonshardkit.ShardNode] = []
  let ring = @moonshardkit.ConsistentHashRing::build(nodes)
  assert_true(ring.owner("key") is None)
  assert_eq(ring.owners("key", 3).length(), 0)
}
