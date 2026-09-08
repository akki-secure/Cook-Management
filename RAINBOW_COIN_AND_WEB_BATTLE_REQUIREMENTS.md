# レインボーコイン7連ガチャ ＆ Web版対戦ミニゲーム 要件定義書

2026-09-08作成。対戦ミニゲーム(PR #25)完了後の次フェーズ。

## 1. 背景・目的

- 対戦ミニゲームは`feature/battle-minigame`(PR #25)でGodotクライアントに実装済み。
- レインボーコインは画像アセットのみ配置済み(PR #24)で、入手方法・使い道が未実装。
- ユーザー要望: 「ボス戦に勝つとレインボーコインが1枚もらえる」「レインボーコイン1枚で7連ガチャが引ける」「Webページ版でもモンスター対戦ができるようにしたい」。

## 2. スコープ

### 2.1 レインボーコイン獲得
- **条件**: ボス戦(`is_boss_battle == true`)に勝利した場合のみ。手持ち対戦(モンスター同士)勝利では付与しない。
- **付与数**: 1勝につき1枚。連戦での上限・クールダウンは設けない(現時点)。
- **付与経路**: これまでGodotの対戦はサーバーと一切通信せずクライアント内で完結していたが、報酬付与のため**戦闘結果をサーバーに報告するAPIが新規に必要**になる。
  - `POST /api/v1/battle_results` (仮): `{ mode: "boss" | "self", result: "win" | "lose" }` を受け取り、`mode == "boss" && result == "win"` の場合のみ `user.rainbow_coins += 1`。
  - Web版対戦もこのエンドポイント(のWeb版ラッパー、もしくは同一API)を叩いて報酬を得る。ロジックを二重実装しないよう、`Gamification::BattleRewardService`のような共通サービスに切り出す。

### 2.2 7連ガチャ
- **消費**: レインボーコイン1枚。
- **抽選ルール**: 既存の通常ガチャ(`Gamification::GachaRules::WIN_RATE = 0.5`、`Gamification::GachaPullService`)を**そのまま7回繰り返すだけ**。特殊な確定枠は設けない。
- **実装方針**: 既存`GachaPullService`を7回呼ぶラッパー(`Gamification::SevenGachaPullService`など)を新設。コイン消費だけレインボーコイン1枚に差し替える(通常コインは減らさない)。
- **対応範囲**: Godotクライアント・Webページ版の両方に7連ガチャUIを追加。

### 2.3 Web版対戦ミニゲーム
- **作り込み度**: Godot版と同等。JavaScriptでターン制・「ジャンプ」(タイミング回避)・「ガード」(被ダメ半減)の操作も再現する。
- **モード**: Godot版と同じく「手持ち対戦」(自モンスター2体)・「ボス戦」(固定ボス「クラウンハンバーグ」、HP150/ATK18、変身演出込み)の2種類。
- **入り口**: マイページ(`profile`)に「対戦する」ボタンを追加。新規`BattlesController` + ビュー + JSを作成。
- **通信方針**: 戦闘開始時にAPIから自モンスター一覧を取得(既存`/api/v1/monsters`を流用)。戦闘の演出・判定自体はGodot版同様クライアント(JS)側で完結させ、勝敗が決まった時点で2.1のAPIに結果を報告する(サーバー側でダメージ計算までは行わない、クライアント権威モデルをGodot版と揃える)。

## 3. DB変更

- `users`テーブルに `rainbow_coins:integer, default: 0, null: false` を追加するマイグレーション。

## 4. バックエンドAPI変更

| メソッド | パス | 内容 |
|---|---|---|
| POST | `/api/v1/battle_results` | 戦闘結果報告。ボス戦勝利時のみ`rainbow_coins`+1 |
| POST | `/api/v1/gacha/seven` (仮) | レインボーコイン1枚消費で7連ガチャ、結果配列を返す |
| GET | `/api/v1/status` | レスポンスに`rainbow_coins`を追加(既存のcoinsと並べて返す) |
| (Web) POST | `/battles/results` | Web版対戦結果報告、内部で共通サービス呼び出し |
| (Web) POST | `/gacha/seven` | Web版7連ガチャ |

## 5. フロントエンド変更

### Godot
- `main.gd`: マイページに`rainbow_coins`表示ラベル追加。
- `battle_scene.gd`: `_end_battle()`でAPIに結果報告する処理を追加。
- `gacha_scene.gd`: 「7連ガチャ」ボタン追加、7体分の演出。

### Web
- `app/views/profile`等: レインボーコイン枚数表示、「対戦する」導線追加。
- 新規 `BattlesController` + `app/views/battles/*` + `app/javascript/`配下に対戦用JS。
- `GachaController`: 7連ガチャアクション追加、ビューに7連ボタン。

## 6. 対象外(今回やらないこと)
- ガチャ確定枠・天井システムなどの特殊ルール。
- レインボーコインの上限・失効。
- 対戦の観戦・対人対戦(PvP)。

## 7. 未確定・要確認事項
- `/api/v1/battle_results`のような戦闘結果報告APIをGodot版にも遡って追加することになるが、これは既存の対戦フロー(PR #25)に対する後付け変更になる。問題なければこのまま進める。
