# MoonShardKit

面向 MoonBit 的确定性分片放置与迁移规划基础库。

MoonShardKit 为缓存、对象存储、任务队列、分布式索引和无状态路由提供一致性
哈希、加权 Rendezvous、多副本拓扑隔离、扩缩容迁移计划和分布质量分析。

## 核心价值

- 同一拓扑和键集在 Native、JavaScript、Wasm、Wasm-GC 上得到一致结果；
- 节点加入、退出或变权时只计算必要移动，不操作真实数据；
- 副本优先跨可用区、跨机架，无法满足时明确降级；
- 输出每节点负载、偏斜、约束违例和移动比例；
- 核心不绑定网络、服务发现、数据库或云平台。

## 已实现

- 稳定 32 位跨后端哈希与命名空间盐；
- 加权虚拟节点一致性哈希环；
- 整数票据加权 Rendezvous 排名；
- 区域/机架感知副本放置；
- 拓扑快照迁移计划；
- 主副本负载与约束质量报告；
- 稳定 JSON、CLI 和 10,000 键工作负载；
- 37 个确定性测试。

## 快速验证

```bash
moon fmt --check
moon check --target all
moon test --target wasm
moon test --target wasm-gc
moon test --target js
moon run cmd/main --target js
moon run bench/main --target js
```

## 最小示例

```moonbit
let nodes = [
  @moonshardkit.ShardNode::new("a", zone="east", rack="r1"),
  @moonshardkit.ShardNode::new("b", zone="west", rack="r1"),
  @moonshardkit.ShardNode::new("c", zone="south", rack="r2"),
]

let placement = @moonshardkit.place_replicas(nodes, "customer-42", 3)
```

## 文档

- [架构](docs/ARCHITECTURE.md)
- [使用手册](docs/USAGE.md)
- [项目价值](docs/VALUE_PROPOSITION.md)
- [相关工作](docs/RELATED_WORK.md)
- [验证证据](docs/EVIDENCE.md)
- [性能计划](docs/BENCHMARK_PLAN.md)
- [路线图](ROADMAP.md)
- [更新日志](CHANGELOG.md)

## License

Apache-2.0.
