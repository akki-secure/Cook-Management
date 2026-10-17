# /quality-check

リポジトリ全体の品質チェックを行う。機能追加時・PRマージ前・定期的な棚卸しに使う。

## 実行手順

### 1. 静的解析（RuboCop）

```bash
cd /Users/aki/Desktop/CookManagement/recipe-management
bundle exec rubocop --format simple 2>/dev/null || echo "RuboCop未導入"
```

### 2. 未使用ファイル・孤立コードの確認

以下を目視で確認する：
- `app/` 配下に使われていないコントローラー・モデル・ビューがないか
- `lib/` に試作・未使用コードが残っていないか
- `public/` に不要な静的ファイルがないか

```bash
# 孤立したビューファイルを探す（参考）
find app/views -name "*.html.erb" | sort
```

### 3. シークレットスキャン

```bash
# 機密情報がコードに直書きされていないか確認
grep -rE "(password|secret|api_key|token)\s*=\s*['\"][^'\"]{8,}" app/ config/ --include="*.rb" --include="*.yml" | grep -v ".enc" | grep -v "test"
```

### 4. .env.example の整合性確認

```bash
# .env と .env.example のキーが揃っているか確認（値は不要）
cat .env.example
```

### 5. README と実装の整合性確認

- README の「主な機能」に未実装・廃止済みの機能が記載されていないか目視確認
- README の「画面遷移図」が現在のルーティングと合っているか確認

```bash
bin/rails routes | grep -v "^  Prefix" | awk '{print $1, $2, $3}' | head -40
```

### 6. テスト実行

```bash
bin/rails test
```

## 棚卸しチェックリスト

- [ ] 使っていないgemがGemfileにないか
- [ ] マイグレーションファイルが正しく適用済みか
- [ ] `tmp/` や `log/` に不要なファイルが溜まっていないか
- [ ] `docs/requirements/` が最新機能まで揃っているか
- [ ] `docs/api/openapi.yaml` が現在のAPIと一致しているか
