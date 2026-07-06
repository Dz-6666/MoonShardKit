///|
fn workflow_keys(count : Int) -> Array[String] {
  Array::makei(count, fn(index) { "workflow-\{index}" })
}

///|
fn workflow_before() -> Array[@moonshardkit.ShardNode] {
  [
    @moonshardkit.ShardNode::new("a", zone="z1", rack="r1"),
    @moonshardkit.ShardNode::new("b", zone="z2", rack="r2"),
    @moonshardkit.ShardNode::new("c", zone="z3", rack="r3"),
  ]
}

///|
fn workflow_after() -> Array[@moonshardkit.ShardNode] {
  let nodes = workflow_before()
  nodes.push(@moonshardkit.ShardNode::new("d", zone="z4", rack="r4"))
  nodes
}

///|
test "safe workflow preserves five phase ordering" {
  let plan = @moonshardkit.plan_safe_migration(
    workflow_keys(100),
    workflow_before(),
    workflow_after(),
    replicas=2,
    max_actions_per_wave=7,
    max_actions_per_node=2,
  )
  assert_true(plan.migrating_keys > 0)
  assert_true(plan.actions.length() > 0)
  assert_eq(@moonshardkit.validate_safe_migration(plan).length(), 0)
  let mut last_rank = -1
  for wave in plan.waves {
    let rank = match wave.phase {
      @moonshardkit.MigrationPhase::AddTarget => 0
      @moonshardkit.MigrationPhase::Backfill => 1
      @moonshardkit.MigrationPhase::Verify => 2
      @moonshardkit.MigrationPhase::SwitchPrimary => 3
      @moonshardkit.MigrationPhase::RemoveSource => 4
    }
    assert_true(rank >= last_rank)
    last_rank = rank
  }
  last_rank = -1
  for action in plan.actions {
    let rank = match action.phase {
      @moonshardkit.MigrationPhase::AddTarget => 0
      @moonshardkit.MigrationPhase::Backfill => 1
      @moonshardkit.MigrationPhase::Verify => 2
      @moonshardkit.MigrationPhase::SwitchPrimary => 3
      @moonshardkit.MigrationPhase::RemoveSource => 4
    }
    assert_true(rank >= last_rank)
    last_rank = rank
  }
}

///|
test "safe workflow enforces wave and node budgets" {
  let plan = @moonshardkit.plan_safe_migration(
    workflow_keys(300),
    workflow_before(),
    workflow_after(),
    replicas=3,
    max_actions_per_wave=5,
    max_actions_per_node=1,
  )
  assert_eq(plan.max_actions_per_wave, 5)
  assert_eq(plan.max_actions_per_node, 1)
  assert_eq(@moonshardkit.validate_safe_migration(plan).length(), 0)
  for wave in plan.waves {
    assert_true(wave.actions.length() <= 5)
  }
}

///|
test "safe workflow blocks keys without readable source" {
  let empty : Array[@moonshardkit.ShardNode] = []
  let after = [@moonshardkit.ShardNode::new("new")]
  let plan = @moonshardkit.plan_safe_migration(["important"], empty, after)
  assert_eq(plan.migrating_keys, 0)
  assert_eq(plan.blocked_keys.length(), 1)
  assert_eq(plan.blocked_keys[0], "important")
  assert_eq(plan.actions.length(), 0)
  assert_eq(plan.waves.length(), 0)
}

///|
test "safe workflow is deterministic" {
  let first = @moonshardkit.plan_safe_migration(
    workflow_keys(50),
    workflow_before(),
    workflow_after(),
    replicas=2,
    max_actions_per_wave=4,
  )
  let second = @moonshardkit.plan_safe_migration(
    workflow_keys(50),
    workflow_before(),
    workflow_after(),
    replicas=2,
    max_actions_per_wave=4,
  )
  assert_true(first == second)
}

///|
test "unchanged topology produces empty safe workflow" {
  let nodes = workflow_before()
  let plan = @moonshardkit.plan_safe_migration(
    workflow_keys(20),
    nodes,
    nodes,
    replicas=2,
  )
  assert_eq(plan.migrating_keys, 0)
  assert_eq(plan.blocked_keys.length(), 0)
  assert_eq(plan.actions.length(), 0)
  assert_eq(plan.waves.length(), 0)
}

///|
test "validator rejects a tampered over-budget wave" {
  let action : @moonshardkit.MigrationAction = {
    key: "one",
    phase: @moonshardkit.MigrationPhase::Backfill,
    from_node: Some("a"),
    to_node: Some("b"),
  }
  let plan : @moonshardkit.SafeMigrationPlan = {
    keys: 1,
    migrating_keys: 1,
    blocked_keys: [],
    actions: [action, action],
    waves: [
      {
        index: 0,
        phase: @moonshardkit.MigrationPhase::Backfill,
        actions: [action, action],
      },
    ],
    max_actions_per_wave: 1,
    max_actions_per_node: 1,
  }
  assert_true(@moonshardkit.validate_safe_migration(plan).length() > 0)
}

///|
test "validator rejects phase regression" {
  let remove : @moonshardkit.MigrationAction = {
    key: "one",
    phase: @moonshardkit.MigrationPhase::RemoveSource,
    from_node: Some("a"),
    to_node: None,
  }
  let verify : @moonshardkit.MigrationAction = {
    key: "one",
    phase: @moonshardkit.MigrationPhase::Verify,
    from_node: Some("a"),
    to_node: Some("b"),
  }
  let plan : @moonshardkit.SafeMigrationPlan = {
    keys: 1,
    migrating_keys: 1,
    blocked_keys: [],
    actions: [remove, verify],
    waves: [
      {
        index: 0,
        phase: @moonshardkit.MigrationPhase::RemoveSource,
        actions: [remove],
      },
      {
        index: 1,
        phase: @moonshardkit.MigrationPhase::Verify,
        actions: [verify],
      },
    ],
    max_actions_per_wave: 1,
    max_actions_per_node: 1,
  }
  assert_true(@moonshardkit.validate_safe_migration(plan).length() > 0)
}
