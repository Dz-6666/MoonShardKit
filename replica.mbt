fn find_node(nodes : Array[ShardNode], id : String) -> ShardNode? {
  for node in nodes {
    if node.id == id {
      return Some(node)
    }
  }
  None
}

fn selected_has_zone(
  nodes : Array[ShardNode],
  selected : Array[String],
  zone : String,
) -> Bool {
  for id in selected {
    match find_node(nodes, id) {
      Some(node) => if node.zone == zone { return true }
      None => ()
    }
  }
  false
}

fn selected_has_rack(
  nodes : Array[ShardNode],
  selected : Array[String],
  zone : String,
  rack : String,
) -> Bool {
  for id in selected {
    match find_node(nodes, id) {
      Some(node) =>
        if node.zone == zone && node.rack == rack {
          return true
        }
      None => ()
    }
  }
  false
}

/// Places ordered replicas while preferring zone and rack diversity.
pub fn place_replicas(
  nodes : Array[ShardNode],
  key : String,
  replicas : Int,
  salt? : String = "moonshardkit",
) -> KeyPlacement {
  if replicas <= 0 {
    return {
      key,
      owners: [],
      complete: true,
      message: "no replicas requested",
    }
  }
  let ranked = rendezvous_owners(nodes, key, nodes.length(), salt~)
  let selected : Array[String] = []

  // First pass: both zone and rack are new.
  for id in ranked {
    if selected.length() >= replicas {
      break
    }
    match find_node(nodes, id) {
      Some(node) =>
        if !selected_has_zone(nodes, selected, node.zone) &&
          !selected_has_rack(nodes, selected, node.zone, node.rack) {
          selected.push(id)
        }
      None => ()
    }
  }

  // Second pass: allow a repeated zone, but avoid the same rack in that zone.
  for id in ranked {
    if selected.length() >= replicas {
      break
    }
    if !selected.contains(id) {
      match find_node(nodes, id) {
        Some(node) =>
          if !selected_has_rack(nodes, selected, node.zone, node.rack) {
            selected.push(id)
          }
        None => ()
      }
    }
  }

  // Final pass: topology cannot satisfy diversity, retain availability.
  for id in ranked {
    if selected.length() >= replicas {
      break
    }
    if !selected.contains(id) {
      selected.push(id)
    }
  }
  let complete = selected.length() == replicas
  {
    key,
    owners: selected,
    complete,
    message: if complete {
      "placement complete"
    } else {
      "insufficient eligible nodes"
    },
  }
}
