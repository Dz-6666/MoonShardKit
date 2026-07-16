///|
fn keys(count : Int) -> Array[String] {
  let values : Array[String] = []
  for index = 0; index < count; index = index + 1 {
    values.push("tenant-\{index}")
  }
  values
}

///|
fn topology() -> Array[@shard.ShardNode] {
  [
    @shard.ShardNode::new("edge-east-a", zone="east", rack="a"),
    @shard.ShardNode::new("edge-west-a", zone="west", rack="a"),
    @shard.ShardNode::new("edge-south-a", zone="south", rack="a"),
    @shard.ShardNode::new("edge-north-a", zone="north", rack="a"),
  ]
}

///|
fn main {
  let plan = @shard.plan_capacity_placement(
    keys(24),
    topology(),
    [
      @shard.NodeCapacity::new("edge-east-a", 8, 12),
      @shard.NodeCapacity::new("edge-west-a", 8, 12),
      @shard.NodeCapacity::new("edge-south-a", 8, 12),
      @shard.NodeCapacity::new("edge-north-a", 8, 12),
    ],
    3,
  )
  println(plan.to_json())
  println("accepted_keys=\{plan.accepted_keys()}")
  println("rejected_keys=\{plan.rejected_keys.length()}")
  println("within_capacity=\{plan.is_within_capacity()}")
}
