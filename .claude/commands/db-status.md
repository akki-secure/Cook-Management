# /db-status

データベースの状態を安全に確認する。破壊的操作は一切行わない。

## 実行手順

### 1. マイグレーション状態確認

```bash
cd /Users/aki/Desktop/CookManagement/recipe-management
bin/rails db:migrate:status
```

### 2. テーブル一覧確認

```bash
bin/rails runner "puts ActiveRecord::Base.connection.tables.sort"
```

### 3. スキーマ確認

```bash
cat db/schema.rb | head -60
```

## 注意

- `db:migrate` / `db:reset` / `db:drop` 等の破壊的コマンドはガードレールでブロック済み
- マイグレーションの実行が必要な場合はユーザー自身が直接ターミナルで実行する
