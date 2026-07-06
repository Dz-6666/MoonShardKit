///|
fn keys(count : Int) -> Array[String] {
  let result : Array[String] = []
  for index = 0; index < count; index = index + 1 {
    result.push("customer-\{index}")
  }
  result
}

///|
fn base_nodes() -> Array[@shard.ShardNode] {
  [
    @shard.ShardNode::new("store-a", zone="east", rack="rack-1"),
    @shard.ShardNode::new("store-b", zone="west", rack="rack-1"),
    @shard.ShardNode::new("store-c", zone="south", rack="rack-2"),
  ]
}

///|
fn show_node(value : String?) -> String {
  match value {
    Some(id) => id
    None => "<none>"
  }
}

///|
fn main {
  let cluster = base_nodes()
  let placement = @shard.place_replicas(cluster, "customer-42", 3)
  println("placement=" + placement.to_json())

  let ring = @shard.ConsistentHashRing::build(cluster)
  println("ring_points=\{ring.point_count()}")
  println("ring_owner=\{show_node(ring.owner("customer-42"))}")
  println(
    "rendezvous_owner=\{show_node(@shard.rendezvous_owner(cluster, "customer-42"))}",
  )

  let workload = keys(1000)
  let distribution = @shard.analyze_distribution(workload, cluster, replicas=3)
  println("distribution=" + distribution.to_json())

  let expanded = base_nodes()
  expanded.push(@shard.ShardNode::new("store-d", zone="north", rack="rack-3"))
  let migration = @shard.plan_migration(workload, cluster, expanded, replicas=3)
  println(
    "migration_summary={\"keys\":\{migration.keys},\"moved_keys\":\{migration.moved_keys},\"ratio\":\{@shard.movement_ratio(migration)}}",
  )
  for index = 0
      index < migration.moves.length() && index < 5
      index = index + 1 {
    let item = migration.moves[index]
    println(
      "move=\{item.key}:\{@shard.move_kind_name(item.kind)}:\{show_node(item.from_node)}->\{show_node(item.to_node)}",
    )
  }
  let workflow = @shard.plan_safe_migration(
    workload,
    cluster,
    expanded,
    replicas=3,
    max_actions_per_wave=32,
    max_actions_per_node=4,
  )
  println(
    "safe_workflow={\"migrating_keys\":\{workflow.migrating_keys},\"actions\":\{workflow.actions.length()},\"waves\":\{workflow.waves.length()},\"blocked\":\{workflow.blocked_keys.length()},\"issues\":\{@shard.validate_safe_migration(workflow).length()}}",
  )
}
