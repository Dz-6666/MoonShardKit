///|
fn workload(count : Int) -> Array[String] {
  let keys : Array[String] = []
  for index = 0; index < count; index = index + 1 {
    keys.push("workload-\{index}")
  }
  keys
}

///|
fn nodes(count : Int) -> Array[@shard.ShardNode] {
  let result : Array[@shard.ShardNode] = []
  for index = 0; index < count; index = index + 1 {
    result.push(
      @shard.ShardNode::new(
        "node-\{index}",
        zone="zone-\{index % 4}",
        rack="rack-\{index % 8}",
      ),
    )
  }
  result
}

///|
fn main {
  let keys = workload(10000)
  let before = nodes(8)
  let after = nodes(9)
  let report = @shard.analyze_distribution(keys, before, replicas=3)
  let plan = @shard.plan_migration(keys, before, after, replicas=3)
  let workflow = @shard.plan_safe_migration(
    keys,
    before,
    after,
    replicas=3,
    max_actions_per_wave=128,
    max_actions_per_node=16,
  )
  let evidence = @shard.stable_hash(
    "\{report.min_primary}|\{report.max_primary}|\{report.spread}|\{plan.moved_keys}",
  )
  println("keys=\{keys.length()}")
  println("nodes=\{before.length()}->\{after.length()}")
  println("primary_range=\{report.min_primary}..\{report.max_primary}")
  println("spread=\{report.spread}")
  println("incomplete=\{report.incomplete_placements}")
  println("moved_keys=\{plan.moved_keys}")
  println("movement_ratio=\{@shard.movement_ratio(plan)}")
  println("workflow_actions=\{workflow.actions.length()}")
  println("workflow_waves=\{workflow.waves.length()}")
  println("workflow_blocked=\{workflow.blocked_keys.length()}")
  println(
    "workflow_issues=\{@shard.validate_safe_migration(workflow).length()}",
  )
  println("evidence=\{evidence}")
}
