# Classmate

[![Flutter](https://img.shields.io/badge/Flutter-App-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Material 3](https://img.shields.io/badge/Material%203-Enabled-6750A4?style=for-the-badge)](https://m3.material.io)
[![License](https://img.shields.io/badge/License-AGPL%20v3-A42E2B?style=for-the-badge)](LICENSE)

[English README](README_EN.md)

Classmate 是一个基于 Flutter 的课程表应用，支持多课表管理、节次时间集复用、课程编辑，以及通过学校网页或 HTML 源码导入课表。

## 功能特性

- 多课表与课程管理
- 节次时间集复用
- 学校站点管理
- 学校网页 / HTML 导入
- 导入前预览并修改课表信息
- 课表、节次模板、学校站点 JSON 导入导出

欢迎通过提交 PR 为 `assets/school_sites.json` 补充和扩展学校站点配置。

## 截图展示

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/s1.png" alt="主页" width="240"></td>
    <td align="center"><img src="docs/screenshots/s2.png" alt="查看课程详情" width="240"></td>
    <td align="center"><img src="docs/screenshots/s3.png" alt="设置页" width="240"></td>
    <td align="center"><img src="docs/screenshots/s4.png" alt="编辑节次时间集页" width="240"></td>
  </tr>
  <tr>
    <td align="center">主页</td>
    <td align="center">查看课程详情</td>
    <td align="center">设置页</td>
    <td align="center">编辑节次时间集页</td>
  </tr>
</table>

## 学校网页导入后端

项目提供了一个单文件 PHP 中转接口：[web/api.php](web/api.php)，在 [lib/config/app_config.dart](lib/config/app_config.dart) 配置你的api地址。

### 后端配置

你需要修改 `web/api.php` 顶部配置区：

- `$relayUrl`：上游 AI 接口地址
- `$relayToken`：你的 API Key
- `$model`：使用的模型
- `$timeoutSeconds`：请求超时时间，当前默认 120 秒
- `$sourceByteLimit`：单次提交内容大小上限，当前默认 300KB
- `$maxParsesPerIpPerDay`：同一 IP 每日最大解析次数，当前默认 5 次


### 当前后端行为

- 使用你配置的 API Key 通过你自己的 PHP 服务中转请求
- 返回统一 JSON 响应，便于客户端直接展示真实错误
- 对提交内容执行大小限制与按 IP 的每日解析次数限制
- 支持网页源码导入场景，不要求输入一定是标准 HTML

## 项目结构

```text
lib/
├─ config/       # 应用配置与默认 API 地址
├─ models/       # 课表、课程、学校站点、导入响应等数据模型
├─ providers/    # 状态管理与导入导出逻辑
├─ screens/      # 页面，如主页、设置页、学校站点管理页
├─ services/     # 导出、分享、导入 API、本地存储等服务
└─ widgets/      # 课表网格、课程编辑、导入预览等组件

web/
└─ api.php
```

## 隐私政策

应用当前采用本地优先策略：课表数据、节次时间、学校站点配置默认保存在本地。
只有在你主动执行导入、导出、分享，或主动提交当前网页 / 粘贴 HTML 用于解析时，应用才会处理对应数据。

隐私政策全文可在应用内“设置 → 隐私政策”查看。

## 开源协议与第三方说明

- 本项目源码基于 [GNU Affero General Public License v3.0](LICENSE) 开源
- 项目内分发的启动图标及相关平台图标资源包含第三方授权内容，详见 [NOTICE](NOTICE)
- Flutter 依赖与第三方库许可可在应用内“设置 → 开源许可”查看
