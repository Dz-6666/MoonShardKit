///|
test "placement JSON escapes identifiers" {
  let placement : @moonshardkit.KeyPlacement = {
    key: "a\"b",
    owners: ["x", "y"],
    complete: true,
    message: "ok",
  }
  let json = placement.to_json()
  assert_true(json.contains("\"key\":\"a\\\"b\""))
  assert_true(json.contains("\"owners\":[\"x\",\"y\"]"))
}

///|
test "migration JSON preserves null endpoints" {
  let plan : @moonshardkit.MigrationPlan = {
    keys: 1,
    moved_keys: 1,
    unchanged_keys: 0,
    moves: [
      {
        key: "k",
        from_node: None,
        to_node: Some("n"),
        kind: @moonshardkit.MoveKind::ReplicaAdded,
      },
    ],
  }
  let json = plan.to_json()
  assert_true(json.contains("\"from\":null"))
  assert_true(json.contains("\"to\":\"n\""))
  assert_true(json.contains("\"kind\":\"replica_added\""))
}

///|
test "distribution JSON includes node load evidence" {
  let report : @moonshardkit.DistributionReport = {
    keys: 2,
    replicas: 1,
    nodes: [{ node_id: "a", primary_keys: 2, replica_keys: 0 }],
    min_primary: 2,
    max_primary: 2,
    spread: 0,
    incomplete_placements: 0,
    zone_violations: 0,
    rack_violations: 0,
  }
  let json = report.to_json()
  assert_true(json.contains("\"keys\":2"))
  assert_true(json.contains("\"node_id\":\"a\""))
  assert_true(json.contains("\"primary_keys\":2"))
}

///|
test "safe migration JSON exposes budgets and phases" {
  let before = [
    @moonshardkit.ShardNode::new("a"),
    @moonshardkit.ShardNode::new("b"),
  ]
  let after = [
    @moonshardkit.ShardNode::new("a"),
    @moonshardkit.ShardNode::new("b"),
    @moonshardkit.ShardNode::new("c"),
  ]
  let plan = @moonshardkit.plan_safe_migration(
    ["one", "two"],
    before,
    after,
    max_actions_per_wave=1,
    max_actions_per_node=1,
  )
  let json = plan.to_json()
  assert_true(json.contains("\"max_actions_per_wave\":1"))
  assert_true(json.contains("\"max_actions_per_node\":1"))
  assert_true(json.contains("\"waves\":["))
  assert_true(json.contains("\"phase\":"))
}
