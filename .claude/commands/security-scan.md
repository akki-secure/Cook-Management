# /security-scan

セキュリティチェックを実行する。デプロイ前・定期的な確認に使う。

## 実行手順

### 1. Bundler Audit（gemの既知脆弱性チェック）

```bash
cd /Users/aki/Desktop/CookManagement/recipe-management
bundle exec bundle-audit check --update 2>/dev/null || echo "bundle-audit未導入"
```

### 2. シークレット直書きスキャン

```bash
# パスワード・APIキー等のハードコードを検出
grep -rE "(password|secret|api_key|token|private_key)\s*[=:]\s*['\"][^'\"]{6,}" \
  app/ config/ lib/ \
  --include="*.rb" --include="*.yml" --include="*.json" \
  | grep -v "credentials.yml.enc" \
  | grep -v "_test.rb" \
  | grep -v "# " 
```

### 3. .gitignore に .env が含まれているか確認

```bash
grep "\.env" .gitignore
```

### 4. Gitコミット履歴のシークレットスキャン

```bash
# 過去のコミットに機密情報が含まれていないか（直近20件）
git log --oneline -20
```

### 5. 依存関係のバージョン確認

```bash
bundle exec gem list | grep -E "rails|devise|jwt|bcrypt"
```

## 確認ポイント

- `.env` が `.gitignore` に含まれている ✅
- `.env.example` に値が空の状態でコミットされている ✅
- `config/master.key` が `.gitignore` に含まれている ✅
- RCE等の重大脆弱性情報が出た場合は即バージョンアップ
