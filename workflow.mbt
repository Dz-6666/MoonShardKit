///|
fn migration_phase_rank(phase : MigrationPhase) -> Int {
  match phase {
    AddTarget => 0
    Backfill => 1
    Verify => 2
    SwitchPrimary => 3
    RemoveSource => 4
  }
}

///|
fn action_touches_node(action : MigrationAction, node_id : String) -> Bool {
  action.from_node == Some(node_id) || action.to_node == Some(node_id)
}

///|
fn node_pressure(actions : Array[MigrationAction], node_id : String) -> Int {
  let mut count = 0
  for action in actions {
    if action_touches_node(action, node_id) {
      count = count + 1
    }
  }
  count
}

///|
fn exceeds_node_budget(
  wave : Array[MigrationAction],
  action : MigrationAction,
  max_actions_per_node : Int,
) -> Bool {
  match action.from_node {
    Some(node_id) =>
      if node_pressure(wave, node_id) >= max_actions_per_node {
        return true
      }
    None => ()
  }
  match action.to_node {
    Some(node_id) =>
      if action.from_node != Some(node_id) &&
        node_pressure(wave, node_id) >= max_actions_per_node {
        return true
      }
    None => ()
  }
  false
}

///|
fn append_phase_waves(
  waves : Array[MigrationWave],
  phase : MigrationPhase,
  actions : Array[MigrationAction],
  max_actions_per_wave : Int,
  max_actions_per_node : Int,
) -> Unit {
  let current : Array[MigrationAction] = []
  for action in actions {
    if current.length() >= max_actions_per_wave ||
      exceeds_node_budget(current, action, max_actions_per_node) {
      waves.push({ index: waves.length(), phase, actions: current.copy() })
      current.clear()
    }
    current.push(action)
  }
  if current.length() > 0 {
    waves.push({ index: waves.length(), phase, actions: current.copy() })
  }
}

///|
fn add_action(
  phase_actions : Array[MigrationAction],
  key : String,
  phase : MigrationPhase,
  from_node : String?,
  to_node : String?,
) -> Unit {
  let action = { key, phase, from_node, to_node }
  phase_actions.push(action)
}

///|
fn append_actions(
  target : Array[MigrationAction],
  source : Array[MigrationAction],
) -> Unit {
  for action in source {
    target.push(action)
  }
}

///|
/// Builds a five-phase, budgeted migration workflow.
///
/// All target replicas are added, backfilled, and verified before any primary
/// switch or source cleanup is emitted. Keys without a readable source are
/// reported as blocked instead of receiving unsafe actions.
pub fn plan_safe_migration(
  keys : Array[String],
  before : Array[ShardNode],
  after : Array[ShardNode],
  replicas? : Int = 1,
  max_actions_per_wave? : Int = 64,
  max_actions_per_node? : Int = 8,
  salt? : String = "moonshardkit",
) -> SafeMigrationPlan {
  let wave_budget = if max_actions_per_wave < 1 {
    1
  } else {
    max_actions_per_wave
  }
  let node_budget = if max_actions_per_node < 1 {
    1
  } else {
    max_actions_per_node
  }
  let all : Array[MigrationAction] = []
  let additions : Array[MigrationAction] = []
  let backfills : Array[MigrationAction] = []
  let verifications : Array[MigrationAction] = []
  let switches : Array[MigrationAction] = []
  let removals : Array[MigrationAction] = []
  let blocked_keys : Array[String] = []
  let mut migrating_keys = 0

  for key in keys {
    let old_placement = place_replicas(before, key, replicas, salt~)
    let new_placement = place_replicas(after, key, replicas, salt~)
    if old_placement.owners == new_placement.owners {
      continue
    }
    if old_placement.owners.length() == 0 && new_placement.owners.length() > 0 {
      blocked_keys.push(key)
      continue
    }
    migrating_keys = migrating_keys + 1
    let source = first_owner(old_placement.owners)
    for owner in new_placement.owners {
      if !old_placement.owners.contains(owner) {
        add_action(additions, key, AddTarget, source, Some(owner))
        add_action(backfills, key, Backfill, source, Some(owner))
        add_action(verifications, key, Verify, source, Some(owner))
      }
    }
    let old_primary = first_owner(old_placement.owners)
    let new_primary = first_owner(new_placement.owners)
    if old_primary != new_primary {
      add_action(switches, key, SwitchPrimary, old_primary, new_primary)
    }
    for owner in old_placement.owners {
      if !new_placement.owners.contains(owner) {
        add_action(removals, key, RemoveSource, Some(owner), None)
      }
    }
  }

  append_actions(all, additions)
  append_actions(all, backfills)
  append_actions(all, verifications)
  append_actions(all, switches)
  append_actions(all, removals)
  let waves : Array[MigrationWave] = []
  append_phase_waves(waves, AddTarget, additions, wave_budget, node_budget)
  append_phase_waves(waves, Backfill, backfills, wave_budget, node_budget)
  append_phase_waves(waves, Verify, verifications, wave_budget, node_budget)
  append_phase_waves(waves, SwitchPrimary, switches, wave_budget, node_budget)
  append_phase_waves(waves, RemoveSource, removals, wave_budget, node_budget)
  {
    keys: keys.length(),
    migrating_keys,
    blocked_keys,
    actions: all,
    waves,
    max_actions_per_wave: wave_budget,
    max_actions_per_node: node_budget,
  }
}

///|
/// Checks phase ordering, wave indexes, and both concurrency budgets.
pub fn validate_safe_migration(plan : SafeMigrationPlan) -> Array[String] {
  let issues : Array[String] = []
  let mut previous_rank = -1
  for index = 0; index < plan.waves.length(); index = index + 1 {
    let wave = plan.waves[index]
    let rank = migration_phase_rank(wave.phase)
    if wave.index != index {
      issues.push("wave index mismatch at \{index}")
    }
    if rank < previous_rank {
      issues.push("phase order regressed at wave \{index}")
    }
    previous_rank = rank
    if wave.actions.length() > plan.max_actions_per_wave {
      issues.push("wave \{index} exceeds action budget")
    }
    for action in wave.actions {
      if action.phase != wave.phase {
        issues.push("wave \{index} mixes migration phases")
      }
      match action.from_node {
        Some(node_id) =>
          if node_pressure(wave.actions, node_id) > plan.max_actions_per_node {
            issues.push("wave \{index} overloads node \{node_id}")
          }
        None => ()
      }
      match action.to_node {
        Some(node_id) =>
          if node_pressure(wave.actions, node_id) > plan.max_actions_per_node {
            issues.push("wave \{index} overloads node \{node_id}")
          }
        None => ()
      }
    }
  }
  issues
}
