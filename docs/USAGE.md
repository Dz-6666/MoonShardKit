# 使用手册

## 节点模型

`ShardNode` 的 `id` 必须在一个拓扑快照内唯一。`weight` 表示相对容量，
`virtual_nodes` 控制一致性哈希环密度，`zone` 和 `rack` 用于副本隔离。
只有 `Active` 节点接收新放置；`Draining` 与 `Offline` 节点会被排除。

## 一致性哈希环

`ConsistentHashRing::build(nodes)` 构建不可变排序环。权重为 N 的节点获得
`virtual_nodes * N` 个点。`owner(key)` 返回主节点，`owners(key, replicas)`
沿顺时针选择不同真实节点。

适合需要长期维护环、批量查询和传统一致性哈希兼容语义的应用。

## Rendezvous 放置

`rendezvous_owners` 对每个节点计算独立最高随机权重分数。MoonShardKit 使用整数
票据表达权重，避免浮点对数在不同后端出现舍入差异。

适合节点数量中等、希望免维护哈希环并直接获得全节点排名的应用。

## 拓扑感知副本

`place_replicas` 使用 Rendezvous 排名并执行三轮选择：

1. 新区域且新机架；
2. 可重复区域，但同一区域内机架不同；
3. 拓扑无法满足隔离时选择剩余高分节点。

返回值中的 `complete` 区分副本是否达到请求数量。

## 迁移计划

`plan_migration(keys, before, after)` 对比两份拓扑快照，输出：

- 主节点变化；
- 副本增加；
- 副本移除；
- 移动键数、未变化键数和移动比例。

该函数不复制数据。应用应在验证计划后自行调度搬迁、限速和重试。

## 分布分析

`analyze_distribution` 汇总每节点主分片和副本数、最小/最大主负载、负载跨度、
不完整放置、区域重复和机架重复。建议在部署拓扑前用真实键样本运行。
