/// Stable FNV-1a style 32-bit hash over MoonBit UTF-16 code units.
pub fn stable_hash(text : String, seed? : UInt = 2166136261U) -> UInt {
  let mut value = seed
  for index = 0; index < text.length(); index = index + 1 {
    let unit = text.unsafe_get(index).to_uint()
    value = (value ^ (unit & 255U)) * 16777619U
    value = (value ^ (unit >> 8)) * 16777619U
  }
  value
}

/// Deterministically mixes a key, node identity, and namespace salt.
pub fn placement_score(key : String, node_id : String, salt : String) -> UInt {
  stable_hash("\{salt.length()}:\{salt}|\{key.length()}:\{key}|\{node_id}")
}

/// Creates a virtual-node position without ambiguous string concatenation.
pub fn virtual_position(node_id : String, replica : Int, seed : UInt) -> UInt {
  stable_hash("\{node_id.length()}:\{node_id}#\{replica}", seed~)
}
