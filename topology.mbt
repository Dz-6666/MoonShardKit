///|
/// Validates identifiers and failure-domain metadata in one snapshot.
pub fn validate_topology(nodes : Array[ShardNode]) -> Array[TopologyIssue] {
  let issues : Array[TopologyIssue] = []
  let ids : Array[String] = []
  for index = 0; index < nodes.length(); index = index + 1 {
    let node = nodes[index]
    if node.id == "" {
      issues.push(EmptyNodeId(index))
    } else if ids.contains(node.id) {
      issues.push(DuplicateNodeId(node.id))
    } else {
      ids.push(node.id)
    }
    if node.zone == "" {
      issues.push(EmptyZone(node.id))
    }
    if node.rack == "" {
      issues.push(EmptyRack(node.id))
    }
  }
  issues
}

///|
/// Returns true when the topology has no structural issues.
pub fn topology_is_valid(nodes : Array[ShardNode]) -> Bool {
  validate_topology(nodes).length() == 0
}
