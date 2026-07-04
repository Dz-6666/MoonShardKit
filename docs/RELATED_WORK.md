# Related Work

MoonShardKit is not a hash function collection. Hashing is an internal primitive
used to solve deterministic data placement and topology change planning.

The MoonBit ecosystem contains high-quality hash implementations and generic
collections, but the initial survey found no package combining:

- consistent hashing with virtual nodes;
- weighted rendezvous placement;
- topology-aware replica diversity;
- deterministic migration plans;
- movement and skew analysis.

Related-package links and detailed comparisons will be maintained as the public
API stabilizes.
