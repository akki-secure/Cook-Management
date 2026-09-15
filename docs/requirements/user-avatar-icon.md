# 要件定義書: ユーザーアイコン(シェフ選択)

> **廃止済み**: この機能は [user-avatar-upload.md](./user-avatar-upload.md) により置き換えられた。
> `avatar_key` カラム・関連コード・Godot側のアイコン表示は削除済み。本ドキュメントは経緯の記録として残す。

## 背景・目的

ユーザーから提供された「シェフの男性」「シェフの女性」のイラストを、ユーザーアイコンとして使えるようにする。プロフィールに個性を持たせ、Web版・Godot版の両方で自分のアイコンを表示できるようにする。

## スコープ

### 含むもの

- Userに `avatar_key` カラムを追加(`chef_male` / `chef_female` の2択、デフォルト `chef_male`)
- Web版: 新規登録・プロフィール編集画面でアイコンを選択できる
- Web版: ヘッダーのユーザーメニュー、マイページにアイコン画像を表示
- Godot版: API(`/api/v1/status`)のレスポンスに `avatar_key` を含め、メイン画面にアイコンを表示
- Minitestによる自動テスト追加

### 含まないもの(対象外)

- 3種類目以降のアイコン追加(将来拡張の余地として`avatar_key`は文字列型のまま残す)
- カスタム画像のアップロード機能
- Godot側でのアイコン変更UI(選択・変更はWeb版のみ)

## 機能要件

- `User#avatar_key` は `chef_male` / `chef_female` のいずれか(バリデーションで制限)
- 新規登録画面: ラジオボタン+プレビュー画像で選択。未選択時は `chef_male` がデフォルト
- プロフィール編集画面: 同様に変更可能
- ヘッダーの「〇〇さん」表示の前にアイコン画像(小)を表示
- マイページの「お名前」欄付近にアイコン画像(中)を表示
- Godotのメイン画面に、称号・レベル表示の近くにアイコン画像を表示

## 画像アセットの扱い

- `app/assets/images/avatars/{chef_male,chef_female}.png` (Web用)
- `godot-client/assets/avatars/{chef_male,chef_female}.png` (Godot用)
- モンスター画像とは区別し、専用の `avatars` ディレクトリに配置する

## 非機能要件

- 既存の配色・フォーム構造(`app/views/users/new.html.erb` 等)に沿ったUIにする
- 既存テストスタイル(Minitest, `ActionDispatch::IntegrationTest`, `sign_in_as`)に沿ったテストを追加する
