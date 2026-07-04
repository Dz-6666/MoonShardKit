///|
fn analysis_keys(count : Int) -> Array[String] {
  let result : Array[String] = []
  for index = 0; index < count; index = index + 1 {
    result.push("analysis-\{index}")
  }
  result
}

///|
test "distribution report accounts for every primary key" {
  let nodes = [
    @moonshardkit.ShardNode::new("a", zone="z1"),
    @moonshardkit.ShardNode::new("b", zone="z2"),
    @moonshardkit.ShardNode::new("c", zone="z3"),
  ]
  let report = @moonshardkit.analyze_distribution(
    analysis_keys(600),
    nodes,
    replicas=2,
  )
  let mut primaries = 0
  let mut replicas = 0
  for load in report.nodes {
    primaries = primaries + load.primary_keys
    replicas = replicas + load.replica_keys
  }
  assert_eq(primaries, 600)
  assert_eq(replicas, 600)
  assert_eq(report.incomplete_placements, 0)
}

///|
test "distribution report exposes bounded skew" {
  let nodes = [
    @moonshardkit.ShardNode::new("a"),
    @moonshardkit.ShardNode::new("b"),
    @moonshardkit.ShardNode::new("c"),
  ]
  let report = @moonshardkit.analyze_distribution(analysis_keys(3000), nodes)
  assert_true(report.min_primary > 700)
  assert_true(report.max_primary < 1300)
  assert_true(report.spread < 600)
}

///|
test "distribution report counts incomplete placement" {
  let nodes = [@moonshardkit.ShardNode::new("only")]
  let report = @moonshardkit.analyze_distribution(
    analysis_keys(20),
    nodes,
    replicas=3,
  )
  assert_eq(report.incomplete_placements, 20)
}

///|
test "distribution report identifies repeated zones" {
  let nodes = [
    @moonshardkit.ShardNode::new("a", zone="z1", rack="r1"),
    @moonshardkit.ShardNode::new("b", zone="z1", rack="r2"),
  ]
  let report = @moonshardkit.analyze_distribution(
    analysis_keys(10),
    nodes,
    replicas=2,
  )
  assert_eq(report.zone_violations, 10)
  assert_eq(report.rack_violations, 0)
}

///|
test "empty topology produces explicit incomplete placements" {
  let nodes : Array[@moonshardkit.ShardNode] = []
  let report = @moonshardkit.analyze_distribution(
    analysis_keys(5),
    nodes,
    replicas=1,
  )
  assert_eq(report.nodes.length(), 0)
  assert_eq(report.incomplete_placements, 5)
}
