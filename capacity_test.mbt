///|
fn capacity_nodes() -> Array[@moonshardkit.ShardNode] {
  [
    @moonshardkit.ShardNode::new("a", zone="east", rack="r1"),
    @moonshardkit.ShardNode::new("b", zone="west", rack="r1"),
    @moonshardkit.ShardNode::new("c", zone="south", rack="r1"),
  ]
}

///|
test "capacity plan keeps primary and replica budgets" {
  let plan = @moonshardkit.plan_capacity_placement(
    ["k1", "k2", "k3", "k4"],
    capacity_nodes(),
    [
      @moonshardkit.NodeCapacity::new("a", 2, 3),
      @moonshardkit.NodeCapacity::new("b", 2, 3),
      @moonshardkit.NodeCapacity::new("c", 2, 3),
    ],
    2,
  )
  assert_true(plan.is_within_capacity())
  assert_eq(plan.rejected_keys.length(), 0)
  assert_eq(plan.accepted_keys(), 4)
  for placement in plan.placements {
    assert_true(placement.complete)
    assert_eq(placement.owners.length(), 2)
  }
}

///|
test "capacity plan reports keys when admission is impossible" {
  let plan = @moonshardkit.plan_capacity_placement(
    ["k1", "k2", "k3"],
    capacity_nodes(),
    [
      @moonshardkit.NodeCapacity::new("a", 1, 0),
      @moonshardkit.NodeCapacity::new("b", 0, 0),
      @moonshardkit.NodeCapacity::new("c", 0, 0),
    ],
    1,
  )
  assert_true(plan.is_within_capacity())
  assert_true(plan.rejected_keys.length() >= 2)
  assert_true(plan.placements[0].complete)
  assert_false(plan.placements[2].complete)
}

///|
test "capacity plan is deterministic and normalizes negative limits" {
  let capacities = [
    @moonshardkit.NodeCapacity::new("a", -1, -1),
    @moonshardkit.NodeCapacity::new("b", 2, 2),
    @moonshardkit.NodeCapacity::new("c", 2, 2),
  ]
  assert_eq(capacities[0].max_primary, 0)
  let first = @moonshardkit.plan_capacity_placement(
    ["k1", "k2"],
    capacity_nodes(),
    capacities,
    1,
  )
  let second = @moonshardkit.plan_capacity_placement(
    ["k1", "k2"],
    capacity_nodes(),
    capacities,
    1,
  )
  assert_true(first == second)
  assert_true(first.to_json().contains("\"within_capacity\":true"))
}
