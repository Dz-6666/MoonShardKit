# MoonShardKit

面向 MoonBit 的确定性分片放置与安全迁移规划基础库。

MoonShardKit 服务于分布式缓存、对象存储、任务队列、搜索索引和无状态
路由。项目不止回答“一个键属于哪个节点”，还把副本隔离、扩缩容影响、
数据迁移顺序和节点压力预算建模为可测试、可审计的纯算法。

## 核心能力

- 跨后端稳定哈希、加权一致性哈希环和加权 Rendezvous 排名；
- 区域与机架感知的多副本放置；
- 节点加入、退出、排空和变权后的移动分析；
- 建目标、回填、校验、切主、清理五阶段安全迁移工作流；
- 全局波次并发预算和单节点压力预算；
- 无可读源时阻止危险迁移，并报告 `blocked_keys`；
- 负载偏斜、约束违例、移动比例和稳定 JSON 报告；
- Native、JavaScript、Wasm、Wasm-GC 后端中立。

## 快速验证

```bash
moon fmt --check
moon check --target all
moon test --target js
moon test --target wasm
moon test --target wasm-gc
moon run cmd/main --target js
moon run bench/main --target js
```

## 最小示例

```moonbit
let workflow = @moonshardkit.plan_safe_migration(
  keys,
  old_nodes,
  new_nodes,
  replicas=3,
  max_actions_per_wave=64,
  max_actions_per_node=8,
)

assert_eq(@moonshardkit.validate_safe_migration(workflow).length(), 0)
```

MoonShardKit 生成控制面计划，不连接存储系统，也不复制业务数据。应用可将
迁移波次交给自己的执行器、检查点系统或审批流程。

完整 API 示例见 [README.mbt.md](README.mbt.md)。

## License

Apache-2.0
