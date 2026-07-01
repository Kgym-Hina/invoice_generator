# Receipt Studio

一个基于 Flutter 的模版化收据生成器，现已调整为更适合桌面端和 Web 公开部署的工作台布局，使用统一的 `pdf` 渲染逻辑生成高一致性的收据文件。

## 已实现

- 模版化收据编辑界面
- 基于 `go_router` 的 URL 路由：`Workspace / Vault / Templates / Storage Plan`
- 更适合桌面端的双栏工作台与侧边导航
- 收款人 / 付款人模板保存、加载、删除
- 多货币支持：`CNY`、`USD`、`EUR`、`GBP`、`JPY`、`HKD`、`SGD`
- 实时金额计算：小计、税额、总额
- 统一 PDF 生成：同一份草稿在桌面端与移动端输出一致
- PDF 预览
- MacOS 保存到本地文件
- iOS 通过系统分享面板导出 PDF / 工作区文件，可直接存到“文件”App 或 iCloud Drive
- 本地持久化：草稿与模板使用 `shared_preferences` 保存

## 关键依赖

- `pdf`
- `printing`
- `shared_preferences`
- `intl`
- `file_selector`
- `path_provider`
- `go_router`

## Web 本地存储方案

当前项目继续使用 `shared_preferences` 保存草稿、模板和最近收据记录，这样改动最小，Flutter Web 下也能直接工作。

如果最终作为公开 Web 工具长期部署，建议按下面的分层演进：

1. 草稿自动保存继续走 `shared_preferences`，保证实现简单、启动快。
2. 模板库、收据库和工作区快照迁移到 `IndexedDB`，因为容量和结构都更适合浏览器端长期存储。
3. 保留 JSON 导入导出作为显式备份和跨设备迁移手段。
4. 在 UI 中明确提示“数据默认仅保存在当前浏览器”，避免用户误以为存在云同步。

如果后续继续开发，建议抽象一个 `LocalStore` 接口：

- `SharedPreferencesLocalStore`：默认实现，兼容当前多平台。
- `IndexedDbLocalStore`：Web 专用实现，承载模板库和历史收据。

## 运行

```bash
flutter pub get
flutter run -d chrome
```

或

```bash
flutter run -d macos
```

## 验证

```bash
flutter analyze
flutter test
```
