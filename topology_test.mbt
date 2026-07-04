///|
test "well formed topology is valid" {
  let nodes = [
    @moonshardkit.ShardNode::new("a", zone="z1", rack="r1"),
    @moonshardkit.ShardNode::new("b", zone="z2", rack="r1"),
  ]
  assert_true(@moonshardkit.topology_is_valid(nodes))
}

///|
test "topology rejects duplicate node IDs" {
  let nodes = [
    @moonshardkit.ShardNode::new("a"),
    @moonshardkit.ShardNode::new("a"),
  ]
  let issues = @moonshardkit.validate_topology(nodes)
  assert_true(
    issues.contains(@moonshardkit.TopologyIssue::DuplicateNodeId("a")),
  )
}

///|
test "topology reports empty identity with its index" {
  let nodes = [@moonshardkit.ShardNode::new("")]
  let issues = @moonshardkit.validate_topology(nodes)
  assert_true(issues.contains(@moonshardkit.TopologyIssue::EmptyNodeId(0)))
}

///|
test "topology requires explicit non-empty failure domains" {
  let nodes = [@moonshardkit.ShardNode::new("a", zone="", rack="")]
  let issues = @moonshardkit.validate_topology(nodes)
  assert_true(issues.contains(@moonshardkit.TopologyIssue::EmptyZone("a")))
  assert_true(issues.contains(@moonshardkit.TopologyIssue::EmptyRack("a")))
}
