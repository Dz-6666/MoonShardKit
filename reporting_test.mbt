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
