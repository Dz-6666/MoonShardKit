///|
pub fn CapacityAdjustment::new(
  node_id : String,
  primary_delta : Int,
  replica_delta : Int,
) -> CapacityAdjustment {
  { node_id, primary_delta, replica_delta }
}

///|
/// Applies capacity changes without mutating the caller's policy array.
/// Unknown adjustment targets are ignored so stale control-plane updates are
/// safe to replay.
pub fn adjust_capacities(
  capacities : Array[NodeCapacity],
  adjustments : Array[CapacityAdjustment],
) -> Array[NodeCapacity] {
  let updated : Array[NodeCapacity] = []
  for capacity in capacities {
    let mut primary = capacity.max_primary
    let mut replicas = capacity.max_replicas
    for adjustment in adjustments {
      if adjustment.node_id == capacity.node_id {
        primary = primary + adjustment.primary_delta
        replicas = replicas + adjustment.replica_delta
      }
    }
    updated.push(NodeCapacity::new(capacity.node_id, primary, replicas))
  }
  updated
}

///|
/// Marks every node in an unavailable zone or rack as offline.
pub fn exclude_failure_domains(
  nodes : Array[ShardNode],
  unavailable_zones : Array[String],
  unavailable_racks : Array[String],
) -> Array[ShardNode] {
  nodes.map(fn(node) {
    if unavailable_zones.contains(node.zone) ||
      unavailable_racks.contains(node.rack) {
      node.with_status(Offline)
    } else {
      node
    }
  })
}

///|
/// Restricts new placement to an explicit regional allow-list.
pub fn isolate_regions(
  nodes : Array[ShardNode],
  allowed_zones : Array[String],
) -> Array[ShardNode] {
  nodes.map(fn(node) {
    if allowed_zones.contains(node.zone) {
      node
    } else {
      node.with_status(Offline)
    }
  })
}

///|
pub fn MigrationCheckpoint::new(completed_waves : Int) -> MigrationCheckpoint {
  { completed_waves: if completed_waves < 0 { 0 } else { completed_waves } }
}

///|
/// Returns a self-contained remaining workflow after a durable checkpoint.
/// Wave indexes are renumbered from zero so validation remains meaningful for
/// the resumed executor.
pub fn resume_safe_migration(
  plan : SafeMigrationPlan,
  checkpoint : MigrationCheckpoint,
) -> SafeMigrationPlan {
  let start = if checkpoint.completed_waves > plan.waves.length() {
    plan.waves.length()
  } else {
    checkpoint.completed_waves
  }
  let waves : Array[MigrationWave] = []
  let actions : Array[MigrationAction] = []
  for index = start; index < plan.waves.length(); index = index + 1 {
    let original = plan.waves[index]
    let resumed = { ..original, index: waves.length() }
    for action in resumed.actions {
      actions.push(action)
    }
    waves.push(resumed)
  }
  { ..plan, actions, waves }
}
