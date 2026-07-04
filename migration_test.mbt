///|
fn migration_keys(count : Int) -> Array[String] {
  let keys : Array[String] = []
  for index = 0; index < count; index = index + 1 {
    keys.push("key-\{index}")
  }
  keys
}

///|
fn base_cluster() -> Array[@moonshardkit.ShardNode] {
  [
    @moonshardkit.ShardNode::new("a", zone="z1"),
    @moonshardkit.ShardNode::new("b", zone="z2"),
    @moonshardkit.ShardNode::new("c", zone="z3"),
  ]
}

///|
test "identical snapshots require no movement" {
  let plan = @moonshardkit.plan_migration(
    migration_keys(100),
    base_cluster(),
    base_cluster(),
  )
  assert_eq(plan.keys, 100)
  assert_eq(plan.moved_keys, 0)
  assert_eq(plan.unchanged_keys, 100)
  assert_eq(plan.moves.length(), 0)
  assert_eq(@moonshardkit.movement_ratio(plan), 0.0)
}

///|
test "adding a node moves a strict subset of keys" {
  let after = base_cluster()
  after.push(@moonshardkit.ShardNode::new("d", zone="z4"))
  let plan = @moonshardkit.plan_migration(
    migration_keys(1000),
    base_cluster(),
    after,
  )
  assert_true(plan.moved_keys > 0)
  assert_true(plan.moved_keys < plan.keys)
  assert_true(@moonshardkit.movement_ratio(plan) < 0.6)
}

///|
test "taking a node offline produces repair moves" {
  let before = base_cluster()
  let after = [
    before[0],
    before[1].with_status(@moonshardkit.NodeStatus::Offline),
    before[2],
  ]
  let plan = @moonshardkit.plan_migration(
    migration_keys(300),
    before,
    after,
    replicas=2,
  )
  assert_true(plan.moved_keys > 0)
  assert_true(plan.moves.length() > 0)
}

///|
test "replica count changes are visible in move details" {
  let keys = ["one"]
  let before = base_cluster()
  let old_plan = @moonshardkit.plan_migration(keys, before, before, replicas=1)
  assert_eq(old_plan.moves.length(), 0)
  let empty : Array[@moonshardkit.ShardNode] = []
  let remove_plan = @moonshardkit.plan_migration(
    keys,
    before,
    empty,
    replicas=2,
  )
  assert_true(remove_plan.moves.length() >= 2)
}

///|
test "empty key set has zero movement ratio" {
  let keys : Array[String] = []
  let plan = @moonshardkit.plan_migration(keys, base_cluster(), base_cluster())
  assert_eq(plan.keys, 0)
  assert_eq(@moonshardkit.movement_ratio(plan), 0.0)
}
