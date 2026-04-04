# Classmate

[![Flutter](https://img.shields.io/badge/Flutter-App-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Material 3](https://img.shields.io/badge/Material%203-Enabled-6750A4?style=for-the-badge)](https://m3.material.io)
[![License](https://img.shields.io/badge/License-AGPL%20v3-A42E2B?style=for-the-badge)](LICENSE)

[English README](README_EN.md)

Classmate 是一个基于 Flutter 的课程表应用，提供多课表管理、共享节次时间集、课程编辑、冲突展示，以及课表与节次模板导入导出能力。

支持平台：Android、iOS、Windows、macOS、Linux、Web。

## 功能概览

- 多课表：新建、切换、重命名、编辑、删除
- 周视图课表：支持顶部跳周、左右滑动切周、键盘方向键切周
- 课程管理：支持地点、教师、学分、备注、自定义字段
- 冲突处理：查看冲突课程，并切换外部显示的冲突课程
- 节次时间集：支持选择、新建、编辑、删除，并可被多个课表复用
- 模板与数据：支持导入、导出、分享、保存课表 JSON 与节次模板
- 设置页：提供开学日期、节次时间集、开源许可、GitHub 仓库入口

## 默认数据

首次启动时，应用会自动生成：

- 一个名为“空白课表”的默认课表
- 一套内置默认节次时间，来源于 [assets/default_period_times.json](assets/default_period_times.json)

如果本地已有保存数据，则会优先加载本地数据。

## 截图展示

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/screenshot1.png" alt="主页" width="240"></td>
    <td align="center"><img src="docs/screenshots/screenshot2.png" alt="侧边栏" width="240"></td>
    <td align="center"><img src="docs/screenshots/screenshot3.png" alt="课程详情弹窗" width="240"></td>
    <td align="center"><img src="docs/screenshots/screenshot4.png" alt="设置页" width="240"></td>
  </tr>
  <tr>
    <td align="center">主页</td>
    <td align="center">侧边栏</td>
    <td align="center">课程详情弹窗</td>
    <td align="center">设置页</td>
  </tr>
</table>

## 项目结构

```text
lib/
├─ data/         # 本地存储与平台适配
├─ models/       # 课表、课程、节次时间等数据模型
├─ providers/    # 状态管理与导入导出逻辑
├─ screens/      # 页面，如主页、设置页、节次时间编辑页
├─ services/     # 导出、分享等服务
└─ widgets/      # 课表网格、课程编辑、详情弹窗等组件
```

## 开源许可证

本项目基于 [GNU Affero General Public License v3.0](LICENSE) 开源。

项目内分发的启动图标及相关图标资源包含第三方授权内容，详见 [NOTICE](NOTICE)。
