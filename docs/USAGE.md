# 使用手册

## 节点模型

`ShardNode.id` 在单个拓扑快照中必须唯一。`weight` 表示相对容量，
`virtual_nodes` 控制一致性哈希环密度，`zone` 和 `rack` 用于副本隔离。
只有 `Active` 节点接收新放置，`Draining` 和 `Offline` 节点会被排除。

## 放置算法

`ConsistentHashRing::build(nodes)` 构建稳定哈希环，适合需要传统一致性哈希
语义和批量查询的应用。

`rendezvous_owners` 对所有节点进行确定性排名。MoonShardKit 使用整数票据
表达权重，避免浮点对数在不同后端产生舍入差异。

`place_replicas` 在排名基础上优先选择不同区域和机架。拓扑无法满足隔离时，
会保留可用性并在分析报告中暴露违例。

## 影响分析

`plan_migration(keys, before, after)` 比较两个不可变拓扑快照，给出主节点
变化、副本增加、副本移除、移动键数和移动比例。它适合容量评估和变更审查。

## 安全迁移工作流

`plan_safe_migration` 将变化展开为五阶段动作：

1. `AddTarget`：建立目标副本元数据；
2. `Backfill`：从旧副本复制数据；
3. `Verify`：验证目标副本完整性；
4. `SwitchPrimary`：必要时切换主节点；
5. `RemoveSource`：确认安全后清理旧副本。

`max_actions_per_wave` 限制单波总动作数，`max_actions_per_node` 限制同一节点
在一波中的压力。所有阶段严格有序；`validate_safe_migration` 可在执行前
复核波次索引、阶段和预算。

若旧拓扑中没有可读源而新拓扑要求已有数据，键会进入 `blocked_keys`，不会
生成危险动作。真实系统可由人工修复、备份恢复或专用引导流程处理。

## 执行边界

MoonShardKit 不复制数据。调用方应为动作提供幂等执行、持久化检查点、重试、
指标和审批，并只在前一阶段完成后推进下一波。
