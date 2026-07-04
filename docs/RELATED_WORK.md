# 相关工作与差异化

## MoonBit 哈希实现

Mooncakes 已有 rapidhash、密码学组件和通用 `Hash` trait。这些项目解决摘要或
容器键散列。MoonShardKit 不重新定位为哈希算法集合，而是使用固定稳定哈希完成
节点排序、分片归属、拓扑隔离和迁移分析。

参考：

- https://mooncakes.io/docs/DzmingLi/rapidhash
- https://mooncakes.io/docs/moonbitlang/core/builtin

## loci

`zploc/loci` 包含 deterministic hashing 与 Merkle tree sealing，服务于其 runtime
和内容寻址场景。MoonShardKit 不实现 Merkle sealing，关注集群节点上的加权键
放置、多副本故障域隔离与拓扑变更计划。

参考：https://mooncakes.io/docs/zploc/loci

## 一致性哈希与 Rendezvous 的组合

两种算法分别适合维护排序环和直接全节点排名。本项目同时提供二者，并在其上统一
节点状态、权重、区域/机架、副本策略、迁移报告和质量指标。初步检索未发现
Mooncakes 上提供这一完整范围的通用库。
