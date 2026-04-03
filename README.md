# Classmate

Classmate 是一个基于 Flutter 的课程表应用，支持多课表管理、共享节次时间集、课程编辑、课程冲突展示，以及课表数据导入导出。

## 功能特性

- 多课表管理与切换
- 独立的节次时间集创建、编辑与复用
- 按周查看课表，支持快捷跳转周数
- 添加、编辑、删除课程
- 课程详情查看与冲突课程处理
- 课表数据导入、导出、分享与保存
- Android / Windows / Web 多平台 Flutter 支持

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
├─ screens/      # 页面，如主页与设置页
├─ services/     # 导出、分享等服务
└─ widgets/      # 课表网格、编辑器、详情弹窗等组件
```

## 运行项目

### 1. 安装依赖

```bash
flutter pub get
```

### 2. 启动应用

```bash
flutter run
```

## 数据与导入导出

- 应用启动后会自动加载本地保存的课表数据
- 支持导入单个或多个课表
- 导出时可以选择一个或多个课表打包为 JSON 文件
- 导入时会自动处理节次时间集关联与 ID 冲突

## 当前主要页面

- 主页：查看当前周课表、切换周数、打开课程详情、添加课程
- 侧边栏：切换课表、编辑课表、新建课表
- 设置页：设置开学日期、选择节次时间集、编辑节次时间、导入导出数据、跳转 GitHub 仓库

## 开发说明

- 状态管理入口在 `lib/providers/timetable_provider.dart`
- 应用入口在 `lib/main.dart`
- 主界面在 `lib/screens/home_screen.dart`
- 设置页在 `lib/screens/settings_page.dart`

## 仓库地址

- https://github.com/Mashiro0619/classmate
