# レシピ管理

自分の作ったレシピを登録・共有できるレシピ管理アプリです。カテゴリやタグでの検索、お気に入り登録、コメント、5段階の星評価に対応しています。

## 主な機能

- **レシピのCRUD**: タイトル・説明・材料(複数追加/削除可)・作り方・調理時間・人数分・写真を登録
- **カテゴリ・タグ**: カテゴリはプルダウン選択、なければその場で新規作成可。タグはカンマ区切りで自由入力(自動で新規作成)
- **検索・絞り込み**: キーワード・カテゴリ・タグでレシピ一覧を絞り込み
- **お気に入り(♥)**: ログインユーザーがレシピをワンクリックでお気に入り登録・解除(ページ遷移なしで即時反映)
- **コメント**: レシピへのコメント投稿・編集・削除(自分のコメントのみ編集・削除可)
- **評価(★5段階)**: レシピを1〜5の星で評価。1人1レシピにつき1件、後から変更可。平均評価を一覧・詳細に表示
- **ユーザー認証**: メールアドレス・パスワードでの新規登録/ログイン(セッションベース、Devise等は未使用)

## 技術スタック

- Ruby 3.3.11 / Rails 7.1
- MySQL 8.0
- Turbo / Stimulus(importmap、JSビルド不要)
- Active Storage(画像アップロード)
- Minitest(テスト)

## セットアップ

### Dockerを使う場合(推奨)

```bash
docker compose up
```

初回起動時は別ターミナルでDBを作成・マイグレーションします。

```bash
docker compose exec web bin/rails db:create db:migrate
```

`http://localhost:3000` でアクセスできます。

### ローカル環境で動かす場合

MySQLが起動していること(`config/database.yml`参照。`DB_HOST`/`DB_USERNAME`/`DB_PASSWORD` で接続先を変更可能)。

```bash
bundle install
bin/rails db:create db:migrate
bin/rails server
```

`http://localhost:3000` でアクセスできます。

## テストの実行

```bash
bin/rails test
```

## マイグレーションの追加後

コード変更(マイグレーション追加含む)をした場合、Docker環境では以下でDBに反映します。

```bash
docker compose exec web bin/rails db:migrate
```
