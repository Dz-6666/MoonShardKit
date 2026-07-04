fn first_owner(owners : Array[String]) -> String? {
  if owners.length() == 0 { None } else { Some(owners[0]) }
}

/// Compares two topology snapshots and emits deterministic ownership changes.
pub fn plan_migration(
  keys : Array[String],
  before : Array[ShardNode],
  after : Array[ShardNode],
  replicas? : Int = 1,
  salt? : String = "moonshardkit",
) -> MigrationPlan {
  let moves : Array[ShardMove] = []
  let mut moved_keys = 0
  for key in keys {
    let old_placement = place_replicas(before, key, replicas, salt~)
    let new_placement = place_replicas(after, key, replicas, salt~)
    if old_placement.owners != new_placement.owners {
      moved_keys = moved_keys + 1
    }
    let old_primary = first_owner(old_placement.owners)
    let new_primary = first_owner(new_placement.owners)
    if old_primary != new_primary {
      moves.push({
        key,
        from_node: old_primary,
        to_node: new_primary,
        kind: PrimaryChanged,
      })
    }
    for owner in old_placement.owners {
      if !new_placement.owners.contains(owner) {
        moves.push({
          key,
          from_node: Some(owner),
          to_node: None,
          kind: ReplicaRemoved,
        })
      }
    }
    for owner in new_placement.owners {
      if !old_placement.owners.contains(owner) {
        moves.push({
          key,
          from_node: None,
          to_node: Some(owner),
          kind: ReplicaAdded,
        })
      }
    }
  }
  {
    keys: keys.length(),
    moved_keys,
    unchanged_keys: keys.length() - moved_keys,
    moves,
  }
}

/// Returns the fraction of keys whose ordered owner set changed.
pub fn movement_ratio(plan : MigrationPlan) -> Double {
  if plan.keys == 0 {
    0.0
  } else {
    plan.moved_keys.to_double() / plan.keys.to_double()
  }
}
