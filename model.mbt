///|
/// Administrative state used by placement algorithms.
pub(all) enum NodeStatus {
  Active
  Draining
  Offline
} derive(Debug, Eq)

///|
/// Structural problem in a topology snapshot.
pub(all) enum TopologyIssue {
  EmptyNodeId(Int)
  DuplicateNodeId(String)
  EmptyZone(String)
  EmptyRack(String)
} derive(Debug, Eq)

///|
/// Built-in owner-selection strategy.
pub(all) enum PlacementAlgorithm {
  ConsistentRing
  Rendezvous
  TopologyAware
} derive(Debug, Eq)

///|
/// A storage or compute node participating in shard placement.
pub(all) struct ShardNode {
  id : String
  weight : Int
  virtual_nodes : Int
  zone : String
  rack : String
  status : NodeStatus
} derive(Debug, Eq)

///|
/// One key and its ordered owner list.
pub(all) struct KeyPlacement {
  key : String
  owners : Array[String]
  complete : Bool
  message : String
} derive(Debug, Eq)

///|
/// Why an ownership assignment changed.
pub(all) enum MoveKind {
  PrimaryChanged
  ReplicaAdded
  ReplicaRemoved
} derive(Debug, Eq)

///|
/// One planned ownership change between topology snapshots.
pub(all) struct ShardMove {
  key : String
  from_node : String?
  to_node : String?
  kind : MoveKind
} derive(Debug, Eq)

///|
/// Aggregate migration evidence.
pub(all) struct MigrationPlan {
  keys : Int
  moved_keys : Int
  unchanged_keys : Int
  moves : Array[ShardMove]
} derive(Debug, Eq)

///|
/// Ordered safety phase for an executable shard migration.
pub(all) enum MigrationPhase {
  AddTarget
  Backfill
  Verify
  SwitchPrimary
  RemoveSource
} derive(Debug, Eq)

///|
/// One idempotent operation in a safe migration workflow.
pub(all) struct MigrationAction {
  key : String
  phase : MigrationPhase
  from_node : String?
  to_node : String?
} derive(Debug, Eq)

///|
/// A deterministic group of actions that may execute concurrently.
pub(all) struct MigrationWave {
  index : Int
  phase : MigrationPhase
  actions : Array[MigrationAction]
} derive(Debug, Eq)

///|
/// Executable migration workflow with explicit safety and pressure budgets.
pub(all) struct SafeMigrationPlan {
  keys : Int
  migrating_keys : Int
  blocked_keys : Array[String]
  actions : Array[MigrationAction]
  waves : Array[MigrationWave]
  max_actions_per_wave : Int
  max_actions_per_node : Int
} derive(Debug, Eq)

///|
/// Per-node ownership count.
pub(all) struct NodeLoad {
  node_id : String
  primary_keys : Int
  replica_keys : Int
} derive(Debug, Eq)

///|
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

///|
/// Hard ownership budgets for one node during a batch placement run.
/// A missing node from the capacity list is treated as unbounded.
pub(all) struct NodeCapacity {
  node_id : String
  max_primary : Int
  max_replicas : Int
} derive(Debug, Eq)

///|
/// Observed ownership and the configured budgets for one node.
pub(all) struct CapacityLoad {
  node_id : String
  primary_keys : Int
  replica_keys : Int
  max_primary : Int
  max_replicas : Int
} derive(Debug, Eq)

///|
/// Deterministic batch placement result with explicit admission failures.
pub(all) struct CapacityPlan {
  placements : Array[KeyPlacement]
  rejected_keys : Array[String]
  loads : Array[CapacityLoad]
  replicas : Int
} derive(Debug, Eq)

///|
/// A signed update to one node's ownership budgets.
pub(all) struct CapacityAdjustment {
  node_id : String
  primary_delta : Int
  replica_delta : Int
} derive(Debug, Eq)

///|
/// Durable progress marker for resuming a safe migration by wave.
pub(all) struct MigrationCheckpoint {
  completed_waves : Int
} derive(Debug, Eq)

///|
pub fn NodeCapacity::new(
  node_id : String,
  max_primary : Int,
  max_replicas : Int,
) -> NodeCapacity {
  {
    node_id,
    max_primary: if max_primary < 0 {
      0
    } else {
      max_primary
    },
    max_replicas: if max_replicas < 0 {
      0
    } else {
      max_replicas
    },
  }
}

///|
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
    weight: if weight < 1 {
      1
    } else {
      weight
    },
    virtual_nodes: if virtual_nodes < 1 {
      1
    } else {
      virtual_nodes
    },
    zone,
    rack,
    status: Active,
  }
}

///|
/// Returns a copy with a new administrative state.
pub fn ShardNode::with_status(
  self : ShardNode,
  status : NodeStatus,
) -> ShardNode {
  { ..self, status, }
}

///|
/// Returns whether the node can receive new ownership.
pub fn ShardNode::is_eligible(self : ShardNode) -> Bool {
  self.status == Active
}
