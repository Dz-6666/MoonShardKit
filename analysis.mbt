///|
fn node_index(loads : Array[NodeLoad], id : String) -> Int {
  for index = 0; index < loads.length(); index = index + 1 {
    if loads[index].node_id == id {
      return index
    }
  }
  -1
}

///|
fn placement_zone_violations(
  nodes : Array[ShardNode],
  owners : Array[String],
) -> Int {
  let zones : Array[String] = []
  let mut violations = 0
  for owner in owners {
    match find_node(nodes, owner) {
      Some(node) =>
        if zones.contains(node.zone) {
          violations = violations + 1
        } else {
          zones.push(node.zone)
        }
      None => ()
    }
  }
  violations
}

///|
fn placement_rack_violations(
  nodes : Array[ShardNode],
  owners : Array[String],
) -> Int {
  let locations : Array[String] = []
  let mut violations = 0
  for owner in owners {
    match find_node(nodes, owner) {
      Some(node) => {
        let location = "\{node.zone}/\{node.rack}"
        if locations.contains(location) {
          violations = violations + 1
        } else {
          locations.push(location)
        }
      }
      None => ()
    }
  }
  violations
}

///|
/// Measures placement balance and topology constraint outcomes.
pub fn analyze_distribution(
  keys : Array[String],
  nodes : Array[ShardNode],
  replicas? : Int = 1,
  salt? : String = "moonshardkit",
) -> DistributionReport {
  let loads : Array[NodeLoad] = []
  for node in nodes {
    if node.is_eligible() {
      loads.push({ node_id: node.id, primary_keys: 0, replica_keys: 0 })
    }
  }
  let mut incomplete = 0
  let mut zone_violations = 0
  let mut rack_violations = 0
  for key in keys {
    let placement = place_replicas(nodes, key, replicas, salt~)
    if !placement.complete {
      incomplete = incomplete + 1
    }
    zone_violations = zone_violations +
      placement_zone_violations(nodes, placement.owners)
    rack_violations = rack_violations +
      placement_rack_violations(nodes, placement.owners)
    for owner_index = 0
        owner_index < placement.owners.length()
        owner_index = owner_index + 1 {
      let index = node_index(loads, placement.owners[owner_index])
      if index >= 0 {
        let current = loads[index]
        loads[index] = if owner_index == 0 {
          { ..current, primary_keys: current.primary_keys + 1 }
        } else {
          { ..current, replica_keys: current.replica_keys + 1 }
        }
      }
    }
  }
  let mut min_primary = 0
  let mut max_primary = 0
  if loads.length() > 0 {
    min_primary = loads[0].primary_keys
    max_primary = loads[0].primary_keys
    for load in loads {
      if load.primary_keys < min_primary {
        min_primary = load.primary_keys
      }
      if load.primary_keys > max_primary {
        max_primary = load.primary_keys
      }
    }
  }
  {
    keys: keys.length(),
    replicas,
    nodes: loads,
    min_primary,
    max_primary,
    spread: max_primary - min_primary,
    incomplete_placements: incomplete,
    zone_violations,
    rack_violations,
  }
}
