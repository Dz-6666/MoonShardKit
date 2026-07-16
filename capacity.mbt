///|
fn capacity_for(
  capacities : Array[NodeCapacity],
  node_id : String,
  key_count : Int,
) -> NodeCapacity {
  for capacity in capacities {
    if capacity.node_id == node_id {
      return capacity
    }
  }
  NodeCapacity::new(node_id, key_count, key_count)
}

///|
fn capacity_load_index(loads : Array[CapacityLoad], node_id : String) -> Int {
  for index = 0; index < loads.length(); index = index + 1 {
    if loads[index].node_id == node_id {
      return index
    }
  }
  -1
}

///|
fn capacity_allows(
  loads : Array[CapacityLoad],
  node_id : String,
  primary : Bool,
) -> Bool {
  let index = capacity_load_index(loads, node_id)
  if index < 0 {
    false
  } else {
    let load = loads[index]
    if primary {
      load.primary_keys < load.max_primary
    } else {
      load.replica_keys < load.max_replicas
    }
  }
}

///|
fn reserve_capacity(
  loads : Array[CapacityLoad],
  node_id : String,
  primary : Bool,
) -> Unit {
  let index = capacity_load_index(loads, node_id)
  if index >= 0 {
    let load = loads[index]
    loads[index] = if primary {
      { ..load, primary_keys: load.primary_keys + 1 }
    } else {
      { ..load, replica_keys: load.replica_keys + 1 }
    }
  }
}

///|
fn capacity_loads(
  nodes : Array[ShardNode],
  capacities : Array[NodeCapacity],
  key_count : Int,
) -> Array[CapacityLoad] {
  let loads : Array[CapacityLoad] = []
  for node in nodes {
    if node.is_eligible() {
      let capacity = capacity_for(capacities, node.id, key_count)
      loads.push({
        node_id: node.id,
        primary_keys: 0,
        replica_keys: 0,
        max_primary: capacity.max_primary,
        max_replicas: capacity.max_replicas,
      })
    }
  }
  loads
}

///|
fn topology_accepts(
  nodes : Array[ShardNode],
  selected : Array[String],
  candidate : String,
  pass : Int,
) -> Bool {
  match find_node(nodes, candidate) {
    None => false
    Some(node) =>
      if pass == 0 {
        !selected_has_zone(nodes, selected, node.zone) &&
        !selected_has_rack(nodes, selected, node.zone, node.rack)
      } else if pass == 1 {
        !selected_has_rack(nodes, selected, node.zone, node.rack)
      } else {
        true
      }
  }
}

///|
/// Plans a capacity-admitted, topology-aware placement for a key batch.
///
/// Candidate order is deterministic weighted Rendezvous order. The planner
/// never exceeds a configured budget: keys that cannot receive every requested
/// owner remain in `rejected_keys` with an incomplete placement record.
pub fn plan_capacity_placement(
  keys : Array[String],
  nodes : Array[ShardNode],
  capacities : Array[NodeCapacity],
  replicas : Int,
  salt? : String = "moonshardkit",
) -> CapacityPlan {
  let loads = capacity_loads(nodes, capacities, keys.length())
  let placements : Array[KeyPlacement] = []
  let rejected_keys : Array[String] = []
  let wanted = if replicas < 0 { 0 } else { replicas }
  for key in keys {
    let selected : Array[String] = []
    let ranked = rendezvous_owners(nodes, key, nodes.length(), salt~)
    for pass = 0; pass < 3 && selected.length() < wanted; pass = pass + 1 {
      for candidate in ranked {
        if selected.length() >= wanted {
          break
        }
        let primary = selected.length() == 0
        if !selected.contains(candidate) &&
          capacity_allows(loads, candidate, primary) &&
          topology_accepts(nodes, selected, candidate, pass) {
          selected.push(candidate)
          reserve_capacity(loads, candidate, primary)
        }
      }
    }
    let complete = selected.length() == wanted
    if !complete {
      rejected_keys.push(key)
    }
    placements.push({
      key,
      owners: selected,
      complete,
      message: if complete {
        "placement complete"
      } else {
        "capacity or topology budget exhausted"
      },
    })
  }
  { placements, rejected_keys, loads, replicas: wanted }
}

///|
pub fn CapacityPlan::accepted_keys(self : CapacityPlan) -> Int {
  self.placements.length() - self.rejected_keys.length()
}

///|
pub fn CapacityPlan::is_within_capacity(self : CapacityPlan) -> Bool {
  for load in self.loads {
    if load.primary_keys > load.max_primary ||
      load.replica_keys > load.max_replicas {
      return false
    }
  }
  true
}
