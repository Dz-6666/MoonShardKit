///|
fn rendezvous_nodes() -> Array[@moonshardkit.ShardNode] {
  [
    @moonshardkit.ShardNode::new("a", weight=1),
    @moonshardkit.ShardNode::new("b", weight=1),
    @moonshardkit.ShardNode::new("c", weight=1),
  ]
}

///|
test "rendezvous ranking is deterministic" {
  let first = @moonshardkit.rendezvous_owners(
    rendezvous_nodes(),
    "customer-7",
    3,
  )
  let second = @moonshardkit.rendezvous_owners(
    rendezvous_nodes(),
    "customer-7",
    3,
  )
  assert_true(first == second)
}

///|
test "rendezvous returns distinct owners in score order" {
  let owners = @moonshardkit.rendezvous_owners(rendezvous_nodes(), "order-9", 3)
  assert_eq(owners.length(), 3)
  assert_true(owners[0] != owners[1])
  assert_true(owners[1] != owners[2])
}

///|
test "rendezvous excludes non-active nodes" {
  let nodes = [
    @moonshardkit.ShardNode::new("active"),
    @moonshardkit.ShardNode::new("offline").with_status(
      @moonshardkit.NodeStatus::Offline,
    ),
  ]
  assert_true(@moonshardkit.rendezvous_owner(nodes, "key") == Some("active"))
}

///|
test "rendezvous caps requested replicas" {
  assert_eq(
    @moonshardkit.rendezvous_owners(rendezvous_nodes(), "key", 99).length(),
    3,
  )
  assert_eq(
    @moonshardkit.rendezvous_owners(rendezvous_nodes(), "key", 0).length(),
    0,
  )
}

///|
test "weighted rendezvous gives heavier node more primary keys" {
  let nodes = [
    @moonshardkit.ShardNode::new("light", weight=1),
    @moonshardkit.ShardNode::new("heavy", weight=4),
  ]
  let mut light = 0
  let mut heavy = 0
  for index = 0; index < 1000; index = index + 1 {
    match @moonshardkit.rendezvous_owner(nodes, "key-\{index}") {
      Some("light") => light = light + 1
      Some("heavy") => heavy = heavy + 1
      _ => ()
    }
  }
  assert_true(heavy > light)
  assert_eq(light + heavy, 1000)
}

///|
test "salt creates independent placement namespaces" {
  let nodes = rendezvous_nodes()
  let default_score = @moonshardkit.rendezvous_node_score("key", nodes[0])
  let other_score = @moonshardkit.rendezvous_node_score(
    "key",
    nodes[0],
    salt="other",
  )
  assert_true(default_score != other_score)
}
