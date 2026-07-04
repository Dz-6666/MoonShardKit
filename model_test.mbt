///|
test "node constructor normalizes invalid capacity settings" {
  let node = @moonshardkit.ShardNode::new(
    "a",
    weight=0,
    virtual_nodes=-1,
  )
  assert_eq(node.weight, 1)
  assert_eq(node.virtual_nodes, 1)
  assert_true(node.is_eligible())
}

///|
test "draining and offline nodes are ineligible for new placement" {
  let node = @moonshardkit.ShardNode::new("a")
  assert_false(
    node.with_status(@moonshardkit.NodeStatus::Draining).is_eligible(),
  )
  assert_false(
    node.with_status(@moonshardkit.NodeStatus::Offline).is_eligible(),
  )
}

///|
test "node topology fields remain explicit" {
  let node = @moonshardkit.ShardNode::new(
    "store-7",
    zone="cn-east-1",
    rack="rack-b",
    weight=3,
    virtual_nodes=96,
  )
  assert_eq(node.id, "store-7")
  assert_eq(node.zone, "cn-east-1")
  assert_eq(node.rack, "rack-b")
  assert_eq(node.weight, 3)
  assert_eq(node.virtual_nodes, 96)
}
