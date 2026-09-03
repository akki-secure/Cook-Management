extends Node
## 図鑑一覧シーン→詳細シーンへのデータ受け渡し用Autoload(シングルトン)。
## change_scene_to_fileはコンストラクタ引数を渡せないため、
## 「どのモンスターの一覧か」「今何番目を見ているか」をここに保持する。

var monsters: Array = []
var selected_index: int = 0
