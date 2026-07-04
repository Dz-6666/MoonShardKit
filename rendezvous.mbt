priv struct RendezvousRank {
  node_id : String
  score : UInt
}

/// Computes a deterministic weighted score for one node.
///
/// Integer tickets avoid backend-dependent floating-point logarithms. A node
/// with weight N receives N independent score opportunities and keeps its best.
pub fn rendezvous_node_score(
  key : String,
  node : ShardNode,
  salt? : String = "moonshardkit",
) -> UInt {
  let mut best = 0U
  for ticket = 0; ticket < node.weight; ticket = ticket + 1 {
    let score = placement_score(key, "\{node.id}#\{ticket}", salt)
    if ticket == 0 || score > best {
      best = score
    }
  }
  best
}

/// Ranks all active nodes using weighted highest-random-weight placement.
pub fn rendezvous_owners(
  nodes : Array[ShardNode],
  key : String,
  replicas : Int,
  salt? : String = "moonshardkit",
) -> Array[String] {
  let ranks : Array[RendezvousRank] = []
  for node in nodes {
    if node.is_eligible() {
      ranks.push({
        node_id: node.id,
        score: rendezvous_node_score(key, node, salt~),
      })
    }
  }
  ranks.sort_by(fn(left, right) {
    let by_score = right.score.compare(left.score)
    if by_score != 0 {
      by_score
    } else {
      left.node_id.lexical_compare(right.node_id)
    }
  })
  let result : Array[String] = []
  let wanted = if replicas < 0 {
    0
  } else if replicas < ranks.length() {
    replicas
  } else {
    ranks.length()
  }
  for index = 0; index < wanted; index = index + 1 {
    result.push(ranks[index].node_id)
  }
  result
}

/// Returns the highest-ranked active node.
pub fn rendezvous_owner(
  nodes : Array[ShardNode],
  key : String,
  salt? : String = "moonshardkit",
) -> String? {
  let owners = rendezvous_owners(nodes, key, 1, salt~)
  if owners.length() == 0 { None } else { Some(owners[0]) }
}
