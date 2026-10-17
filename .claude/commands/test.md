# /test

自動テストを実行する。機能を作るごと、またはコミット前に使う。

## 実行手順

```bash
cd /Users/aki/Desktop/CookManagement/recipe-management

# 全テスト実行（30分以上かかる場合はフリーズの可能性あり → 中断して確認）
bin/rails test
```

## テスト種別ごとの個別実行

```bash
# モデルテストのみ
bin/rails test test/models/

# コントローラーテストのみ
bin/rails test test/controllers/

# 統合テストのみ
bin/rails test test/integration/

# 特定ファイルのみ
bin/rails test test/models/recipe_test.rb
```

## 注意

- テストが30分以上かかる場合はフリーズしている可能性が高い。中断して原因を調べる。
- Fiber/MySQL競合でエラーやハングが稀に起きる既知の問題あり（実装バグではない）。
- `bin/rails test` がFiber競合エラーで失敗した場合は再実行して確認する。
