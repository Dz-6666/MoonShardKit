/// Administrative state used by placement algorithms.
pub(all) enum NodeStatus {
  Active
  Draining
  Offline
} derive(Debug, Eq)

/// A storage or compute node participating in shard placement.
pub(all) struct ShardNode {
  id : String
  weight : Int
  virtual_nodes : Int
  zone : String
  rack : String
  status : NodeStatus
} derive(Debug, Eq)

/// One key and its ordered owner list.
pub(all) struct KeyPlacement {
  key : String
  owners : Array[String]
  complete : Bool
  message : String
} derive(Debug, Eq)

/// Why an ownership assignment changed.
pub(all) enum MoveKind {
  PrimaryChanged
  ReplicaAdded
  ReplicaRemoved
} derive(Debug, Eq)

/// One planned ownership change between topology snapshots.
pub(all) struct ShardMove {
  key : String
  from_node : String?
  to_node : String?
  kind : MoveKind
} derive(Debug, Eq)

/// Aggregate migration evidence.
pub(all) struct MigrationPlan {
  keys : Int
  moved_keys : Int
  unchanged_keys : Int
  moves : Array[ShardMove]
} derive(Debug, Eq)

/// Per-node ownership count.
pub(all) struct NodeLoad {
  node_id : String
  primary_keys : Int
  replica_keys : Int
} derive(Debug, Eq)

/// Distribution quality summary.
pub(all) struct DistributionReport {
  keys : Int
  replicas : Int
  nodes : Array[NodeLoad]
  min_primary : Int
  max_primary : Int
  spread : Int
  incomplete_placements : Int
  zone_violations : Int
  rack_violations : Int
} derive(Debug, Eq)

/// Creates a normalized active node.
pub fn ShardNode::new(
  id : String,
  zone? : String = "default-zone",
  rack? : String = "default-rack",
  weight? : Int = 1,
  virtual_nodes? : Int = 64,
) -> ShardNode {
  {
    id,
    weight: if weight < 1 { 1 } else { weight },
    virtual_nodes: if virtual_nodes < 1 { 1 } else { virtual_nodes },
    zone,
    rack,
    status: Active,
  }
}

/// Returns a copy with a new administrative state.
pub fn ShardNode::with_status(
  self : ShardNode,
  status : NodeStatus,
) -> ShardNode {
  { ..self, status }
}

/// Returns whether the node can receive new ownership.
pub fn ShardNode::is_eligible(self : ShardNode) -> Bool {
  self.status == Active
}
