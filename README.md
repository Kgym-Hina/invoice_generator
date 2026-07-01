# Receipt Studio

一个基于 Flutter 的模版化收据生成器，提供桌面优先的工作台界面，并使用统一的 `pdf` 渲染逻辑生成高一致性的收据文件。

## 已实现

- 模版化收据编辑界面
- 基于 `go_router` 的 URL 路由：`Workspace / Vault / Templates`
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
