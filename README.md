# Classmate

[![Flutter](https://img.shields.io/badge/Flutter-App-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Material 3](https://img.shields.io/badge/Material%203-Enabled-6750A4?style=for-the-badge)](https://m3.material.io)
[![License](https://img.shields.io/badge/License-AGPL%20v3-A42E2B?style=for-the-badge)](LICENSE)

[English README](README_EN.md)

Classmate 是一个基于 Flutter 的课程表应用，当前支持多课表管理、节次时间集复用、主题设置、学校站点管理，以及通过学校网页或 HTML 源码导入课表。

## 功能特性

- 多课表管理：支持新建、切换、编辑、删除课表
- 课程编辑：支持课程名称、地点、教师、周次、时间与关联节次编辑
- 节次时间集：支持复用、编辑、导入导出，并可在多个课表之间共享
- 主题设置：支持浅色 / 深色 / 跟随系统，支持预设主题色和自定义颜色
- 学校站点管理：支持新增、编辑、删除学校登录地址，并导入导出学校站点 JSON
- 学校网页 / HTML 导入：支持在应用内打开学校网站导入当前页面，也支持手动粘贴 HTML 导入
- 导入预览：导入前可查看解析结果，并选择节次时间集与导入方式
- 数据导入导出：支持课表、节次模板、学校站点等 JSON 文件导入导出与分享

欢迎通过提交 PR 为 `assets/school_sites.json` 补充和扩展学校站点配置。

## 截图展示

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/s1.jpg" alt="主页" width="240"></td>
    <td align="center"><img src="docs/screenshots/s2.jpg" alt="查看课程详情" width="240"></td>
    <td align="center"><img src="docs/screenshots/s3.jpg" alt="设置页" width="240"></td>
    <td align="center"><img src="docs/screenshots/s4.jpg" alt="编辑节次时间集页" width="240"></td>
  </tr>
  <tr>
    <td align="center">主页</td>
    <td align="center">查看课程详情</td>
    <td align="center">设置页</td>
    <td align="center">编辑节次时间集页</td>
  </tr>
</table>

## 学校网页导入后端

项目提供了 PHP 中转接口：[web/api.php](web/api.php)。应用内学校网页导入接口地址由 [lib/config/app_config.dart](lib/config/app_config.dart) 读取，可通过 `--dart-define=SCHOOL_IMPORT_API_BASE_URL=你的接口地址` 覆盖。

### 后端配置

你需要修改 `web/api.php` 顶部配置区：

- `$relayUrl`：上游 AI 接口地址
- `$relayToken`：你的 API Key
- `$model`：使用的模型
- `$timeoutSeconds`：请求超时时间，当前默认 120 秒
- `$sourceByteLimit`：单次提交内容大小上限，当前默认 300KB
- `$maxParsesPerIpPerDay`：同一 IP 每日最大解析次数，当前默认 5 次

### 当前后端行为

- 通过你自己的 PHP 服务转发解析请求，不直接在客户端暴露上游密钥
- 返回统一 JSON 响应，便于客户端展示解析结果和错误信息
- 对提交内容执行大小限制与按 IP 的每日解析次数限制
- 支持学校网页导入和手动粘贴 HTML 导入场景
- 会把页面内容、可选页面标题、页面 URL 和当前应用语言一并提交到解析接口

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

课表、课表设置、节次时间集和学校站点配置默认保存在设备或浏览器本地，不会自动上传到开发者服务器。
只有在你主动使用导入、导出、分享、外部链接或网页解析等功能时，应用才会读取相关内容或把对应操作交给系统或你配置的解析接口处理。

隐私政策全文可在应用内“设置 → 隐私政策”查看。

## 开源协议与第三方说明

- 本项目源码基于 [GNU Affero General Public License v3.0](LICENSE) 开源
- 项目内分发的启动图标及相关平台图标资源包含第三方授权内容，详见 [NOTICE](NOTICE)
- Flutter 依赖与第三方库许可可在应用内“设置 → 开源许可”查看
