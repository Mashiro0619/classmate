# Classmate

[![Flutter](https://img.shields.io/badge/Flutter-App-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Material 3](https://img.shields.io/badge/Material%203-Enabled-6750A4?style=for-the-badge)](https://m3.material.io)
[![License](https://img.shields.io/badge/License-AGPL%20v3-A42E2B?style=for-the-badge)](LICENSE)

[English README](README_EN.md)

Classmate 是一个基于 Flutter 的课程表应用，支持多课表管理、共享节次时间集、课程编辑、课程冲突展示，以及课表数据导入导出。

## 功能特性

- 首次启动自动创建空白课表，并载入内置默认节次时间
- 多课表管理：新建、切换、重命名、删除
- 共享节次时间集：选择、新建、编辑，并可被多个课表复用
- 按周查看课表，支持快捷跳转周数
- 桌面端支持方向键切周与鼠标左右拖动切周
- 添加、编辑、删除课程
- 课程详情查看与冲突课程处理
- 导入、导出、分享一个或多个课表 JSON 文件
- Android / Windows / Web 多平台支持

## 首次启动默认数据

应用首次启动时会自动生成：

- 一个名为“空白课表”的默认课表
- 一套内置默认节次时间，来源于 [assets/default_period_times.json](assets/default_period_times.json)

如果本地已有保存数据，则会优先加载本地数据。

## 主要界面

### 主页

- 按周展示课程表
- 顶部可快捷跳转到任意周
- 点击课程查看详情与冲突信息
- 长按空白区域可按当天快速添加课程
- 侧边栏可切换课表、编辑课表、创建新课表

### 设置页

- 设置开学日期
- 选择节次时间集
- 在“选择节次时间集”弹窗中直接新建或编辑节次时间集
- 导入导出课表数据
- 跳转 GitHub 仓库

## 数据导入导出

- 支持导入单个或多个课表
- 支持导出一个或多个课表为 JSON 文件
- 导入单个课表时，可选择“作为新课表导入”或“覆盖当前课表”
- 导入时会自动处理节次时间集关联与 ID 冲突

## 技术栈

- Flutter
- Dart
- Provider
- Material 3

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

## 运行项目

### 安装依赖

```bash
flutter pub get
```

### 启动应用

```bash
flutter run
```

## 开发入口

- 应用入口：[lib/main.dart](lib/main.dart)
- 状态管理：[lib/providers/timetable_provider.dart](lib/providers/timetable_provider.dart)
- 主页面：[lib/screens/home_screen.dart](lib/screens/home_screen.dart)
- 设置页：[lib/screens/settings_page.dart](lib/screens/settings_page.dart)

## 开源许可证

本项目基于 [GNU Affero General Public License v3.0](LICENSE) 开源。
