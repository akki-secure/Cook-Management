# /performance-test

パフォーマンステストを手動実行する。機能追加のたびに自動実行せず、任意のタイミングで使う。

## 実行内容

以下を順番に実行してください：

### 1. レスポンスタイム計測

```bash
cd /Users/aki/Desktop/CookManagement/recipe-management

# Railsサーバーが起動していることを前提に、主要エンドポイントを計測
# ローカル確認用（本番は別途実施）
bin/rails test test/performance/ 2>/dev/null || echo "performance/フォルダなし"
```

### 2. N+1クエリ検出（Bullet gem / SQLログ確認）

```bash
# development.logの最新SQLログを確認
tail -100 log/development.log | grep -E "CACHE|SELECT.*FROM" | head -30
```

### 3. DB クエリ件数チェック（主要アクション）

以下のアクションでSQLが過剰に発行されていないか確認：
- `GET /recipes`（レシピ一覧）
- `GET /recipes/:id`（レシピ詳細）
- `GET /monsters`（モンスター図鑑）
- `GET /gacha`（ガチャページ）

### 4. ヘッドフルブラウザで体感速度を確認

Chromeで以下のページを開き、Network タブでロード時間を目視確認：
- レシピ一覧
- レシピ詳細（画像あり）
- モンスター図鑑
- ガチャ

### 5. 結果の記録

問題があれば `docs/` 配下に `performance-YYYY-MM-DD.md` を作成して記録する。

## 判定基準（目安）

| エンドポイント | 目標レスポンス |
|---|---|
| レシピ一覧 | 500ms 以下 |
| レシピ詳細 | 300ms 以下 |
| モンスター図鑑 | 500ms 以下 |
| ガチャ | 300ms 以下 |

## 注意

- 本番環境（https://cook-management.duckdns.org）での計測は別途手動で行う
- DB破壊的操作（db:reset等）は禁止
