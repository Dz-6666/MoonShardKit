///|
/// Escapes a string for JSON output.
pub fn json_escape(value : String) -> String {
  let builder = StringBuilder(size_hint=value.length())
  for index = 0; index < value.length(); index = index + 1 {
    match value.unsafe_get(index) {
      '"' => builder.write_string("\\\"")
      '\\' => builder.write_string("\\\\")
      '\n' => builder.write_string("\\n")
      '\r' => builder.write_string("\\r")
      '\t' => builder.write_string("\\t")
      unit => builder.write_char(unit.to_int().unsafe_to_char())
    }
  }
  builder.to_string()
}

///|
fn optional_string_json(value : String?) -> String {
  match value {
    Some(text) => "\"\{json_escape(text)}\""
    None => "null"
  }
}

///|
/// Encodes one placement.
pub fn KeyPlacement::to_json(self : KeyPlacement) -> String {
  let builder = StringBuilder()
  builder.write_string("{\"key\":\"\{json_escape(self.key)}\",\"owners\":[")
  for index = 0; index < self.owners.length(); index = index + 1 {
    if index > 0 {
      builder.write_char(',')
    }
    builder.write_string("\"\{json_escape(self.owners[index])}\"")
  }
  builder.write_string(
    "],\"complete\":\{self.complete},\"message\":\"\{json_escape(self.message)}\"}",
  )
  builder.to_string()
}

///|
/// Returns a stable name for one migration action.
pub fn move_kind_name(kind : MoveKind) -> String {
  match kind {
    PrimaryChanged => "primary_changed"
    ReplicaAdded => "replica_added"
    ReplicaRemoved => "replica_removed"
  }
}

///|
/// Returns the stable machine-readable name of a workflow phase.
pub fn migration_phase_name(phase : MigrationPhase) -> String {
  match phase {
    AddTarget => "add_target"
    Backfill => "backfill"
    Verify => "verify"
    SwitchPrimary => "switch_primary"
    RemoveSource => "remove_source"
  }
}

///|
fn write_migration_action(
  builder : StringBuilder,
  action : MigrationAction,
) -> Unit {
  builder.write_string(
    "{\"key\":\"\{json_escape(action.key)}\",\"phase\":\"\{migration_phase_name(action.phase)}\",\"from\":\{optional_string_json(action.from_node)},\"to\":\{optional_string_json(action.to_node)}}",
  )
}

///|
/// Encodes a safe migration workflow for audit logs and control planes.
pub fn SafeMigrationPlan::to_json(self : SafeMigrationPlan) -> String {
  let builder = StringBuilder()
  builder.write_string(
    "{\"keys\":\{self.keys},\"migrating_keys\":\{self.migrating_keys},\"blocked_keys\":[",
  )
  for index = 0; index < self.blocked_keys.length(); index = index + 1 {
    if index > 0 {
      builder.write_char(',')
    }
    builder.write_string("\"\{json_escape(self.blocked_keys[index])}\"")
  }
  builder.write_string(
    "],\"max_actions_per_wave\":\{self.max_actions_per_wave},\"max_actions_per_node\":\{self.max_actions_per_node},\"waves\":[",
  )
  for wave_index = 0
      wave_index < self.waves.length()
      wave_index = wave_index + 1 {
    if wave_index > 0 {
      builder.write_char(',')
    }
    let wave = self.waves[wave_index]
    builder.write_string(
      "{\"index\":\{wave.index},\"phase\":\"\{migration_phase_name(wave.phase)}\",\"actions\":[",
    )
    for action_index = 0
        action_index < wave.actions.length()
        action_index = action_index + 1 {
      if action_index > 0 {
        builder.write_char(',')
      }
      write_migration_action(builder, wave.actions[action_index])
    }
    builder.write_string("]}")
  }
  builder.write_string("]}")
  builder.to_string()
}

///|
/// Encodes one migration plan.
pub fn MigrationPlan::to_json(self : MigrationPlan) -> String {
  let builder = StringBuilder()
  builder.write_string(
    "{\"keys\":\{self.keys},\"moved_keys\":\{self.moved_keys},\"unchanged_keys\":\{self.unchanged_keys},\"moves\":[",
  )
  for index = 0; index < self.moves.length(); index = index + 1 {
    if index > 0 {
      builder.write_char(',')
    }
    let item = self.moves[index]
    builder.write_string(
      "{\"key\":\"\{json_escape(item.key)}\",\"from\":\{optional_string_json(item.from_node)},\"to\":\{optional_string_json(item.to_node)},\"kind\":\"\{move_kind_name(item.kind)}\"}",
    )
  }
  builder.write_string("]}")
  builder.to_string()
}

///|
/// Encodes distribution evidence.
pub fn DistributionReport::to_json(self : DistributionReport) -> String {
  let builder = StringBuilder()
  builder.write_string(
    "{\"keys\":\{self.keys},\"replicas\":\{self.replicas},\"min_primary\":\{self.min_primary},\"max_primary\":\{self.max_primary},\"spread\":\{self.spread},\"incomplete_placements\":\{self.incomplete_placements},\"zone_violations\":\{self.zone_violations},\"rack_violations\":\{self.rack_violations},\"nodes\":[",
  )
  for index = 0; index < self.nodes.length(); index = index + 1 {
    if index > 0 {
      builder.write_char(',')
    }
    let load = self.nodes[index]
    builder.write_string(
      "{\"node_id\":\"\{json_escape(load.node_id)}\",\"primary_keys\":\{load.primary_keys},\"replica_keys\":\{load.replica_keys}}",
    )
  }
  builder.write_string("]}")
  builder.to_string()
}

///|
/// Encodes capacity-admitted placement evidence for control-plane logs.
pub fn CapacityPlan::to_json(self : CapacityPlan) -> String {
  let builder = StringBuilder()
  builder.write_string(
    "{\"replicas\":\{self.replicas},\"accepted_keys\":\{self.accepted_keys()},\"rejected_keys\":[",
  )
  for index = 0; index < self.rejected_keys.length(); index = index + 1 {
    if index > 0 {
      builder.write_char(',')
    }
    builder.write_string("\"\{json_escape(self.rejected_keys[index])}\"")
  }
  builder.write_string("],\"loads\":[")
  for index = 0; index < self.loads.length(); index = index + 1 {
    if index > 0 {
      builder.write_char(',')
    }
    let load = self.loads[index]
    builder.write_string(
      "{\"node_id\":\"\{json_escape(load.node_id)}\",\"primary_keys\":\{load.primary_keys},\"replica_keys\":\{load.replica_keys},\"max_primary\":\{load.max_primary},\"max_replicas\":\{load.max_replicas}}",
    )
  }
  builder.write_string("],\"within_capacity\":\{self.is_within_capacity()}}")
  builder.to_string()
}
