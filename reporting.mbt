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

fn optional_string_json(value : String?) -> String {
  match value {
    Some(text) => "\"\{json_escape(text)}\""
    None => "null"
  }
}

/// Encodes one placement.
pub fn KeyPlacement::to_json(self : KeyPlacement) -> String {
  let builder = StringBuilder()
  builder.write_string(
    "{\"key\":\"\{json_escape(self.key)}\",\"owners\":[",
  )
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

/// Returns a stable name for one migration action.
pub fn move_kind_name(kind : MoveKind) -> String {
  match kind {
    PrimaryChanged => "primary_changed"
    ReplicaAdded => "replica_added"
    ReplicaRemoved => "replica_removed"
  }
}

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
