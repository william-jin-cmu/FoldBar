# 实现参考

- Thaw 3.0.0-alpha.5：macOS 27 限制与行为说明
  https://github.com/thaw-app/Thaw/releases/tag/3.0.0-alpha.5
- Pelmet，fif7y 及贡献者（GPL-3.0）：MenuBarClientCore 的运行时接口、系统标识映射、MenuBarAgent AX 树结构。
  https://github.com/fif7y/pelmet
  研究时版本：095cc56e96afd110743267894a803b58ab672333
  参考文件：MBAssessmentShim.m、MenuBarPolicy.swift、ItemEnumerator.swift、EngineGoldenGate.swift。

FoldBar 采用上述公开研究揭示的 macOS 27 API 和系统标识。这里的精简桥接、分界计算、UI、测试由本项目实现；没有引入 Pelmet/Thaw 的完整引擎、配置系统、模拟拖拽或后台辅助进程。为覆盖参考实现涉及的衍生部分，整个交付以 GPL-3.0-or-later 分发，并保留上游来源与许可。
