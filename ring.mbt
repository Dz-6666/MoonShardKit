/// One virtual point on a consistent hash ring.
struct RingPoint {
  position : UInt
  node_id : String
}

/// Immutable consistent hash ring.
pub struct ConsistentHashRing {
  points : Array[RingPoint]
  eligible_nodes : Int
  seed : UInt
}

/// Builds a ring from active nodes.
pub fn ConsistentHashRing::build(
  nodes : Array[ShardNode],
  seed? : UInt = 2166136261U,
) -> ConsistentHashRing {
  let points : Array[RingPoint] = []
  let mut eligible = 0
  for node in nodes {
    if node.is_eligible() {
      eligible = eligible + 1
      let count = node.virtual_nodes * node.weight
      for replica = 0; replica < count; replica = replica + 1 {
        points.push({
          position: virtual_position(node.id, replica, seed),
          node_id: node.id,
        })
      }
    }
  }
  points.sort_by(fn(left, right) {
    let by_position = left.position.compare(right.position)
    if by_position != 0 {
      by_position
    } else {
      left.node_id.lexical_compare(right.node_id)
    }
  })
  { points, eligible_nodes: eligible, seed }
}

/// Returns the number of virtual points.
pub fn ConsistentHashRing::point_count(self : ConsistentHashRing) -> Int {
  self.points.length()
}

/// Returns the number of active real nodes.
pub fn ConsistentHashRing::node_count(self : ConsistentHashRing) -> Int {
  self.eligible_nodes
}

/// Finds the first ring point at or clockwise from a key hash.
fn ConsistentHashRing::start_index(
  self : ConsistentHashRing,
  key : String,
) -> Int {
  if self.points.length() == 0 {
    return 0
  }
  let target = stable_hash(key, seed=self.seed)
  let mut low = 0
  let mut high = self.points.length()
  while low < high {
    let middle = low + (high - low) / 2
    if self.points[middle].position < target {
      low = middle + 1
    } else {
      high = middle
    }
  }
  if low == self.points.length() { 0 } else { low }
}

/// Returns the primary owner for a key.
pub fn ConsistentHashRing::owner(
  self : ConsistentHashRing,
  key : String,
) -> String? {
  if self.points.length() == 0 {
    None
  } else {
    Some(self.points[self.start_index(key)].node_id)
  }
}

/// Returns distinct clockwise owners, primary first.
pub fn ConsistentHashRing::owners(
  self : ConsistentHashRing,
  key : String,
  replicas : Int,
) -> Array[String] {
  let result : Array[String] = []
  if replicas <= 0 || self.points.length() == 0 {
    return result
  }
  let wanted = if replicas < self.eligible_nodes {
    replicas
  } else {
    self.eligible_nodes
  }
  let start = self.start_index(key)
  let mut scanned = 0
  while result.length() < wanted && scanned < self.points.length() {
    let point = self.points[(start + scanned) % self.points.length()]
    if !result.contains(point.node_id) {
      result.push(point.node_id)
    }
    scanned = scanned + 1
  }
  result
}
