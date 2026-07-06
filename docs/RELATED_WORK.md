# 相关工作与边界

## MoonBit 哈希库

Mooncakes 已提供 rapidhash、SHA 系列和标准库 `Hash`/`Hasher`。这些组件解决
摘要或容器键散列；MoonShardKit 不与其争夺“最快哈希函数”，而是使用稳定
分数完成节点排名、副本隔离、拓扑变更分析和安全迁移编排。

参考：

- https://mooncakes.io/docs/DzmingLi/rapidhash
- https://mooncakes.io/docs/moonbitlang/core/builtin

## loci

`zploc/loci` 包含确定性哈希与 Merkle tree sealing，面向内容寻址和运行时
场景。MoonShardKit 不实现 Merkle 封装，重点是集群节点上的加权键放置、
故障域隔离和迁移工作流。

参考：https://mooncakes.io/docs/zploc/loci

## 与框架内分片代码的差异

应用内部常见实现只返回哈希环所有者。MoonShardKit 同时提供两类放置算法、
节点状态、权重、区域/机架约束、移动量分析，以及五阶段、带预算、可验证的
迁移波次。网络发现、数据复制和分布式一致性仍由应用适配器负责。

截至 2026-07-06，使用 `consistent hashing`、`rendezvous`、`sharding` 和
`migration planning` 检索 Mooncakes，未发现覆盖上述完整范围的 MoonBit
通用库。
