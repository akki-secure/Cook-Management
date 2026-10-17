# ログ設計書

## 概要

本アプリのログ設計（構造化ログ・運用ログ・監視ログ）をまとめる。

---

## 1. ログ出力先

| 環境 | 出力先 | 設定箇所 |
|---|---|---|
| development | `log/development.log` | Rails デフォルト |
| production | `STDOUT`（systemdがキャプチャ） | `config/environments/production.rb` |
| test | `log/test.log` | Rails デフォルト |

本番環境では `STDOUT` に出力し、systemd の journald が収集する。
EC2上での確認コマンド：

```bash
sudo journalctl -u cook-management -f
```

---

## 2. ログレベル

| 環境 | ログレベル | 設定 |
|---|---|---|
| development | debug | Rails デフォルト |
| production | info（変更可） | `ENV["RAILS_LOG_LEVEL"]` |
| test | debug | Rails デフォルト |

本番のログレベルは `.env` の `RAILS_LOG_LEVEL=info` で制御する。

---

## 3. 構造化ログ（タグ付きログ）

### request_id タグ

全ログ行にリクエストIDを付与する設定済み：

```ruby
# config/environments/production.rb
config.log_tags = [ :request_id ]
```

出力例：
```
[abc123-def456] Started GET "/recipes" for 1.2.3.4 at 2026-10-17 09:00:00
[abc123-def456] Processing by RecipesController#index as HTML
[abc123-def456] Completed 200 OK in 45ms
```

リクエスト単位でログを追跡できる。

---

## 4. 機密情報フィルタリング

以下のパラメーターは自動でフィルタリングされ、ログに出力されない：

```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn
]
```

ログ出力例（フィルタ後）：
```
Parameters: {"email"=>"[FILTERED]", "password"=>"[FILTERED]"}
```

---

## 5. 運用ログ設計

### 監視すべきログパターン

| パターン | 意味 | 対応 |
|---|---|---|
| `Completed 5xx` | サーバーエラー | 即調査 |
| `Completed 4xx` | クライアントエラー | 多発なら調査 |
| `ActiveRecord::RecordNotFound` | 存在しないIDへのアクセス | 正常範囲 |
| `ActionController::InvalidAuthenticityToken` | CSRFトークン不一致 | 攻撃の可能性 |
| `SQL` が異常に多い | N+1クエリ発生 | クエリ最適化 |

### エラーログ確認コマンド（本番）

```bash
# 直近のエラーを確認
sudo journalctl -u cook-management --since "1 hour ago" | grep -E "ERROR|5[0-9]{2}"

# 本番ログファイルが存在する場合
grep "Completed 5" log/production.log | tail -20
```

---

## 6. 監視ログ設計

### EC2本番環境での監視

| 対象 | 確認方法 |
|---|---|
| アプリ死活 | `systemctl status cook-management` |
| アプリログ | `journalctl -u cook-management -f` |
| Nginxアクセスログ | `/var/log/nginx/access.log` |
| Nginxエラーログ | `/var/log/nginx/error.log` |
| MySQLエラーログ | `/var/log/mysql/error.log` |

### 定期確認推奨サイクル

- **毎日**: アプリ起動確認、5xxエラーが増えていないか
- **週1**: Nginxアクセスログで異常なアクセスがないか確認
- **月1**: ディスク使用量、ログローテーション状況を確認

---

## 7. ログローテーション

本番環境ではログが際限なく増えないよう、logrotate を推奨設定：

```bash
# /etc/logrotate.d/cook-management（EC2上で設定）
/home/deploy/cook-management/log/*.log {
  daily
  missingok
  rotate 14
  compress
  notifempty
  sharedscripts
}
```

---

## 8. 開発環境でのデバッグログ活用

開発環境では以下が有効：

```ruby
# config/environments/development.rb
config.active_record.verbose_query_logs = true   # SQLの発行元を表示
config.active_job.verbose_enqueue_logs = true    # ジョブのキューイング元を表示
```

N+1クエリの調査時は `log/development.log` を確認する。
