# ログ設計

`README.md`とは別に、ログ関連の設計をまとめたドキュメント。

## 1. 構造化ログ(アクセスログ)

`lograge` gemにより、Railsのデフォルトの複数行ログを1リクエスト1行のJSONに変換している。

- 設定ファイル: [config/initializers/lograge.rb](../config/initializers/lograge.rb)
- 出力形式: JSON(`Lograge::Formatters::Json`)
- 付加情報: `request_id`(リクエスト追跡用) / `user_id`(ログイン中のユーザーID、未ログイン時は`null`) / `params`(`controller`・`action`・`authenticity_token`を除外)
- 実装: `ApplicationController#append_info_to_payload` で `request_id` と `current_user.id` をログペイロードに注入([app/controllers/application_controller.rb](../app/controllers/application_controller.rb))

出力例(イメージ):
```json
{"method":"POST","path":"/recipes","format":"html","controller":"RecipesController","action":"create","status":302,"duration":45.2,"view":30.1,"db":8.3,"request_id":"abc-123","user_id":7,"params":{"recipe":{"title":"カレー"}}}
```

## 2. 運用ログ(業務イベントログ)

`AppEventLogger`([app/lib/app_event_logger.rb](../app/lib/app_event_logger.rb))で、業務上重要なイベントをJSON1行で`Rails.logger.info`に出力する。

### 記録しているイベント一覧

| event | 発生箇所 | 主なフィールド |
|---|---|---|
| `recipe.created` / `recipe.updated` / `recipe.destroyed` | RecipesController | `user_id`, `recipe_id` |
| `favorite.created` / `favorite.destroyed` | FavoritesController | `user_id`, `recipe_id` |
| `rating.saved` | RatingsController | `user_id`, `recipe_id`, `score` |
| `comment.created` / `comment.updated` / `comment.destroyed` | CommentsController | `user_id`, `recipe_id` or `comment_id` |
| `user.signed_up` | UsersController | `user_id` |
| `auth.login_succeeded` / `auth.login_failed` | SessionsController | `user_id`(成功時)/ `email`(失敗時) |
| `auth.logout` | SessionsController | `user_id` |

`auth.login_failed`はパスワード自体を記録しない(メールアドレスのみ)。

### 用途

- 不正アクセスの調査(`auth.login_failed`の連続発生を追跡)
- ユーザーサポート時の操作履歴確認
- 将来的な利用状況分析の元データ

## 3. 監視ログ設計(方針)

現時点では監視ツール(Datadog、Sentry等)との連携は未実装。以下は将来導入する際の方針。

| 監視対象 | 条件(案) | 深刻度 |
|---|---|---|
| 5xxエラー発生 | Railsの例外ログ(`ActionDispatch::ExceptionWrapper`)を監視、5xx発生でアラート | 高 |
| ログイン失敗の連続発生 | 同一IP/emailで`auth.login_failed`が短時間に多発(ブルートフォース疑い) | 高 |
| レスポンス遅延 | lograge出力の`duration`が閾値(例: 3000ms)を超えるリクエストが継続 | 中 |
| DB接続エラー | `ActiveRecord::ConnectionNotEstablished`等の例外ログ | 高 |

**現状の制約**: ログの出力先はRails標準のログファイル/STDOUT([config/environments/production.rb](../config/environments/production.rb)で本番はSTDOUT出力済み)のみで、外部監視サービスへの転送・アラート発報の仕組みは未構築。コンテナ環境であればSTDOUT出力をログ収集基盤(CloudWatch Logs、Datadog Agent等)に接続することで、上記の監視条件を実装できる。

## 4. ログレベルの方針

- `development`: `debug`相当(Rails標準)
- `production`: `info`(`RAILS_LOG_LEVEL`環境変数で上書き可能、[config/environments/production.rb](../config/environments/production.rb)参照)
- パスワード等の機密情報はログに出力しない(`auth.login_failed`でもパスワードは記録対象外)
