///|
test "capacity adjustments clamp budgets and ignore stale nodes" {
  let updated = @moonshardkit.adjust_capacities(
    [@moonshardkit.NodeCapacity::new("a", 2, 3)],
    [
      @moonshardkit.CapacityAdjustment::new("a", -5, 4),
      @moonshardkit.CapacityAdjustment::new("missing", 9, 9),
    ],
  )
  assert_eq(updated[0].max_primary, 0)
  assert_eq(updated[0].max_replicas, 7)
}

///|
test "failure domains and region isolation exclude placements" {
  let nodes = [
    @moonshardkit.ShardNode::new("a", zone="east", rack="r1"),
    @moonshardkit.ShardNode::new("b", zone="west", rack="r2"),
    @moonshardkit.ShardNode::new("c", zone="north", rack="r3"),
  ]
  let failed = @moonshardkit.exclude_failure_domains(nodes, ["east"], ["r3"])
  assert_false(failed[0].is_eligible())
  assert_true(failed[1].is_eligible())
  assert_false(failed[2].is_eligible())
  let isolated = @moonshardkit.isolate_regions(nodes, ["west"])
  assert_false(isolated[0].is_eligible())
  assert_true(isolated[1].is_eligible())
}

///|
test "migration resume renumbers and validates remaining waves" {
  let nodes = [
    @moonshardkit.ShardNode::new("a", zone="east"),
    @moonshardkit.ShardNode::new("b", zone="west"),
  ]
  let expanded : Array[@moonshardkit.ShardNode] = []
  for node in nodes {
    expanded.push(node)
  }
  expanded.push(@moonshardkit.ShardNode::new("c", zone="north"))
  let plan = @moonshardkit.plan_safe_migration(
    ["k1", "k2", "k3"],
    nodes,
    expanded,
    replicas=1,
    max_actions_per_wave=1,
  )
  let resumed = @moonshardkit.resume_safe_migration(
    plan,
    @moonshardkit.MigrationCheckpoint::new(1),
  )
  assert_eq(@moonshardkit.validate_safe_migration(resumed).length(), 0)
  assert_true(resumed.waves.length() <= plan.waves.length())
}
