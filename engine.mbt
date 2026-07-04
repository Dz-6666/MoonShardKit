///|
/// Places one key through a selected built-in algorithm.
pub fn place_key(
  nodes : Array[ShardNode],
  key : String,
  replicas : Int,
  algorithm? : PlacementAlgorithm = TopologyAware,
  seed? : UInt = 2166136261U,
  salt? : String = "moonshardkit",
) -> KeyPlacement {
  let owners = match algorithm {
    ConsistentRing =>
      ConsistentHashRing::build(nodes, seed~).owners(key, replicas)
    Rendezvous => rendezvous_owners(nodes, key, replicas, salt~)
    TopologyAware => return place_replicas(nodes, key, replicas, salt~)
  }
  let eligible = nodes.fold(init=0, fn(count, node) {
    if node.is_eligible() {
      count + 1
    } else {
      count
    }
  })
  let expected = if replicas < 0 {
    0
  } else if replicas < eligible {
    replicas
  } else {
    eligible
  }
  let complete = replicas <= eligible && owners.length() == expected
  {
    key,
    owners,
    complete,
    message: if complete {
      "placement complete"
    } else {
      "insufficient eligible nodes"
    },
  }
}

///|
/// Places a deterministic key batch with one algorithm.
pub fn place_keys(
  nodes : Array[ShardNode],
  keys : Array[String],
  replicas : Int,
  algorithm? : PlacementAlgorithm = TopologyAware,
  seed? : UInt = 2166136261U,
  salt? : String = "moonshardkit",
) -> Array[KeyPlacement] {
  keys.map(fn(key) { place_key(nodes, key, replicas, algorithm~, seed~, salt~) })
}
