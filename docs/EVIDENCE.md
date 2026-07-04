# 验证证据

## 测试范围

当前 37 个测试覆盖：

- 固定哈希向量、边界编码和长输入；
- 权重、虚拟节点、环二分查找和节点状态；
- Rendezvous 排名、盐命名空间和权重分布；
- 区域/机架优先与约束降级；
- 节点加入、下线、主副本变化和移动比例；
- 主副本计数、偏斜、不完整放置和约束违例；
- JSON 转义与结构化报告。

## 固定工作负载

`moon run bench/main --target js` 的 10,000 键结果：

```text
keys=10000
nodes=8->9
primary_range=1200..1286
spread=86
incomplete=0
moved_keys=3731
movement_ratio=0.3731
evidence=2184339487
```

结果来自实际运行，不是性能承诺。
