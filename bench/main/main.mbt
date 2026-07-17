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
  let before = nodes(8)
  let after = nodes(9)
  println("keys,moved,ratio,spread,waves,issues,evidence")
  for count in [1000, 10000, 100000] {
    let keys = workload(count)
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
    println(
      "\{count},\{plan.moved_keys},\{@shard.movement_ratio(plan)},\{report.spread},\{workflow.waves.length()},\{@shard.validate_safe_migration(workflow).length()},\{evidence}",
    )
  }
}
