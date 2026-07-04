# Security Policy

MoonShardKit's stable hash is designed for reproducible placement, not
cryptographic authenticity or adversarial collision resistance.

Do not use the built-in score as a signature, password hash, or integrity proof.
Applications exposed to untrusted keys should provide admission controls or a
keyed cryptographic pre-hash before placement.

Report sensitive issues privately to the repository owner. Correctness and
distribution bugs without sensitive details may use the public issue template.
