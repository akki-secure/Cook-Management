import { Controller } from "@hotwired/stimulus"

// Web版の対戦ミニゲーム。Godotクライアント(battle_scene.gd)と同じルールを
// ブラウザ上でJavaScriptで再現する。「手持ち対戦」(自モンスター2体)と
// 「ボス戦」(固定ボスに1体で挑む)の2モード、ターン制で自分の攻撃と
// 相手の飛び道具(ジャンプで回避/ガードで軽減)を繰り返す。
export default class extends Controller {
  static targets = [
    "selectionPanel", "instructionLabel", "selfModeButton", "bossModeButton",
    "monsterGrid", "startBattleButton",
    "battlePanel", "turnLabel", "playerPlatform", "enemyPlatform", "playerIcon", "enemyIcon", "projectile",
    "playerNameAtk", "playerHpFill", "playerHpNum",
    "enemyNameAtk", "enemyHpFill", "enemyHpNum",
    "attackButton", "jumpButton", "guardButton", "resultLabel",
  ]

  static values = {
    monsters: Array,
    boss: Object,
    reportUrl: String,
    csrf: String,
  }

  static TYPE_EFFECT = {
    "たまご": "#ffd933", "ドリンク": "#66ccdd", "スイーツ": "#f299bf",
    "デザート": "#bf99e6", "めん類": "#f28c33", "がっつり": "#d94033",
    "やさい": "#59bf59", "なつのあじ": "#4cd9d9", "おつまみ": "#997f4d",
  }

  // type_labelから攻撃の見た目(炎/氷/衝撃波/光線)を決める。Monsterモデルに
  // 属性カラムは無いため、既存の食べ物カテゴリを流用している。
  static ATTACK_KIND_BY_TYPE = {
    "がっつり": "fire", "めん類": "fire",
    "ドリンク": "ice", "やさい": "ice", "なつのあじ": "ice",
    "スイーツ": "shockwave", "デザート": "shockwave",
    "たまご": "beam", "おつまみ": "beam",
  }

  static BOSS_STAGE_THRESHOLDS = [0.75, 0.50, 0.25]
  static BOSS_ATTACK_MULTIPLIER = 1.25
  static FIREBALL_TRAVEL_MS = 1000
  static DODGE_WINDOW_MS = 250
  static MIN_HOP_HALF_MS = 140
  static TURN_PAUSE_MS = 500

  connect() {
    this.mode = "self"
    this.selectedPlayerIndex = -1
    this.selectedEnemyIndex = -1
    this.bossStageIndex = 0
    this.turn = "player"
    this.gameOver = false
    this.jumpPressedAt = null
    this.guarded = false
    this.impactAt = 0

    this.updateStartButton()
  }

  // --- モンスター選択画面 ---

  chooseSelfMode() {
    this.mode = "self"
    this.selfModeButtonTarget.classList.remove("btn-secondary")
    this.bossModeButtonTarget.classList.add("btn-secondary")
    this.instructionLabelTarget.textContent = "対戦する自分のモンスターを2体選んでください（1体目=自分、2体目=相手）"
    this.selectedPlayerIndex = -1
    this.selectedEnemyIndex = -1
    this.refreshGridHighlights()
    this.updateStartButton()
  }

  chooseBossMode() {
    this.mode = "boss"
    this.bossModeButtonTarget.classList.remove("btn-secondary")
    this.selfModeButtonTarget.classList.add("btn-secondary")
    this.instructionLabelTarget.textContent = "ボスに挑戦する自分のモンスターを1体選んでください"
    this.selectedPlayerIndex = -1
    this.selectedEnemyIndex = -1
    this.refreshGridHighlights()
    this.updateStartButton()
  }

  tapMonster(event) {
    const index = Number(event.currentTarget.dataset.index)

    if (index === this.selectedPlayerIndex) {
      this.selectedPlayerIndex = -1
    } else if (index === this.selectedEnemyIndex) {
      this.selectedEnemyIndex = -1
    } else if (this.selectedPlayerIndex === -1) {
      this.selectedPlayerIndex = index
    } else if (this.mode === "self" && this.selectedEnemyIndex === -1) {
      this.selectedEnemyIndex = index
    }
    // ボス戦モードでは相手はボス固定なので2体目の選択は無視する。

    this.refreshGridHighlights()
    this.updateStartButton()
  }

  refreshGridHighlights() {
    if (!this.hasMonsterGridTarget) return

    this.monsterGridTarget.querySelectorAll(".battle-monster-tile").forEach((tile) => {
      const index = Number(tile.dataset.index)
      tile.classList.remove("battle-selected-player", "battle-selected-enemy")
      if (index === this.selectedPlayerIndex) tile.classList.add("battle-selected-player")
      if (index === this.selectedEnemyIndex) tile.classList.add("battle-selected-enemy")
    })
  }

  updateStartButton() {
    const ready = this.mode === "boss"
      ? this.selectedPlayerIndex !== -1
      : this.selectedPlayerIndex !== -1 && this.selectedEnemyIndex !== -1
    this.startBattleButtonTarget.disabled = !ready
  }

  // --- 対戦開始 ---

  startBattle() {
    const playerMonster = this.monstersValue[this.selectedPlayerIndex]
    this.playerStats = {
      name: playerMonster.name, spriteUrl: playerMonster.sprite_url, typeLabel: playerMonster.type_label,
      hp: playerMonster.hp, maxHp: playerMonster.hp, attack: playerMonster.attack,
    }

    this.isBossBattle = this.mode === "boss"
    this.bossStageIndex = 0

    if (this.isBossBattle) {
      const boss = this.bossValue
      this.enemyStats = {
        name: boss.name, spriteUrl: boss.sprite_url, typeLabel: boss.type_label,
        hp: boss.hp, maxHp: boss.hp, attack: boss.attack,
      }
    } else {
      const enemyMonster = this.monstersValue[this.selectedEnemyIndex]
      this.enemyStats = {
        name: enemyMonster.name, spriteUrl: enemyMonster.sprite_url, typeLabel: enemyMonster.type_label,
        hp: enemyMonster.hp, maxHp: enemyMonster.hp, attack: enemyMonster.attack,
      }
    }

    this.playerIconTarget.src = this.playerStats.spriteUrl
    this.enemyIconTarget.src = this.enemyStats.spriteUrl

    this.gameOver = false
    this.resultLabelTarget.textContent = ""
    this.projectileTarget.hidden = true

    this.selectionPanelTarget.hidden = true
    this.battlePanelTarget.hidden = false

    this.updateHud()
    this.startPlayerTurn()
  }

  updateHud() {
    this.playerNameAtkTarget.textContent = `${this.playerStats.name}  ATK ${this.playerStats.attack}`
    this.playerHpFillTarget.style.width = `${Math.max(0, this.playerStats.hp) / this.playerStats.maxHp * 100}%`
    this.playerHpNumTarget.textContent = `${Math.max(0, this.playerStats.hp)} / ${this.playerStats.maxHp}`

    this.enemyNameAtkTarget.textContent = `${this.enemyStats.name}  ATK ${this.enemyStats.attack}`
    this.enemyHpFillTarget.style.width = `${Math.max(0, this.enemyStats.hp) / this.enemyStats.maxHp * 100}%`
    this.enemyHpNumTarget.textContent = `${Math.max(0, this.enemyStats.hp)} / ${this.enemyStats.maxHp}`
  }

  // --- ターン進行 ---

  startPlayerTurn() {
    this.turn = "player"
    this.turnLabelTarget.textContent = "あなたのターン"
    this.attackButtonTarget.disabled = false
    this.jumpButtonTarget.disabled = true
    this.guardButtonTarget.disabled = true
  }

  attack() {
    if (this.turn !== "player" || this.gameOver) return
    this.attackButtonTarget.disabled = true

    this.launchProjectile("player", this.playerStats.typeLabel, this.constructor.FIREBALL_TRAVEL_MS)
    setTimeout(() => this.resolvePlayerAttack(), this.constructor.FIREBALL_TRAVEL_MS)
  }

  resolvePlayerAttack() {
    this.projectileTarget.hidden = true

    const dmg = this.playerStats.attack
    this.enemyStats.hp = Math.max(0, this.enemyStats.hp - dmg)
    this.shake(this.enemyIconTarget)
    this.updateHud()

    if (this.enemyStats.hp <= 0) {
      this.endBattle(true)
      return
    }

    this.turn = "enemy"
    setTimeout(() => this.startEnemyTurn(), this.constructor.TURN_PAUSE_MS)
  }

  startEnemyTurn() {
    if (this.gameOver) return

    this.turn = "enemy"
    this.jumpPressedAt = null
    this.guarded = false
    this.jumpButtonTarget.disabled = false
    this.guardButtonTarget.disabled = false
    this.turnLabelTarget.textContent = `${this.enemyStats.name} のターン！`

    this.launchProjectile("enemy", this.enemyStats.typeLabel, this.constructor.FIREBALL_TRAVEL_MS)

    this.impactAt = Date.now() + this.constructor.FIREBALL_TRAVEL_MS
    this.enemyTurnTimer = setTimeout(() => this.resolveEnemyAttack(), this.constructor.FIREBALL_TRAVEL_MS)
  }

  // 攻撃側(player/enemy)のtype_labelから見た目(炎/氷/衝撃波/光線)と音を決めて、
  // 攻撃側プラットフォーム→防御側プラットフォームへ.battle-projectile要素を飛ばす。
  // 自分の攻撃・敵の攻撃どちらからも呼ばれる共通処理(ヘルパー)。
  launchProjectile(side, typeLabel, duration) {
    const kind = this.constructor.ATTACK_KIND_BY_TYPE[typeLabel] || "fire"
    const color = this.constructor.TYPE_EFFECT[typeLabel] || "#cccccc"

    const fromPlatform = side === "player" ? this.playerPlatformTarget : this.enemyPlatformTarget
    const toPlatform = side === "player" ? this.enemyPlatformTarget : this.playerPlatformTarget

    // Godot版の「発射側の少し内側から発射し、着弾側の足元近くに当たる」という
    // 狙いを踏襲した固定オフセット。攻撃する側が変わっても同じ比率を使う。
    const start = {
      left: fromPlatform.offsetLeft + fromPlatform.offsetWidth * 0.5,
      top: fromPlatform.offsetTop + fromPlatform.offsetHeight * 0.2,
    }
    const end = {
      left: toPlatform.offsetLeft + toPlatform.offsetWidth * 0.6,
      top: toPlatform.offsetTop + toPlatform.offsetHeight * 0.95,
    }
    const angleDeg = Math.atan2(end.top - start.top, end.left - start.left) * 180 / Math.PI

    const el = this.projectileTarget
    el.className = `battle-projectile battle-projectile--${kind}`
    el.style.setProperty("--projectile-color", color)
    el.style.setProperty("--projectile-angle", `${angleDeg}deg`)
    el.style.left = `${start.left}px`
    el.style.top = `${start.top}px`
    el.hidden = false

    this.playAttackSound(side, kind)

    el.animate(
      [
        { left: `${start.left}px`, top: `${start.top}px` },
        { left: `${end.left}px`, top: `${end.top}px` },
      ],
      { duration, easing: "linear", fill: "forwards" }
    )
  }

  jump() {
    if (this.turn !== "enemy" || this.gameOver || this.jumpPressedAt !== null) return
    this.jumpPressedAt = Date.now()
    this.jumpButtonTarget.disabled = true

    const half = Math.max(this.impactAt - this.jumpPressedAt, this.constructor.MIN_HOP_HALF_MS)
    this.playerIconTarget.animate(
      [{ transform: "translateY(0)" }, { transform: "translateY(-24px)" }, { transform: "translateY(0)" }],
      { duration: half * 2, easing: "ease-out" }
    )
  }

  guard() {
    if (this.turn !== "enemy" || this.gameOver || this.guarded) return
    this.guarded = true
    this.guardButtonTarget.disabled = true
  }

  resolveEnemyAttack() {
    this.jumpButtonTarget.disabled = true
    this.guardButtonTarget.disabled = true

    const dodged = this.jumpPressedAt !== null && (this.impactAt - this.jumpPressedAt) <= this.constructor.DODGE_WINDOW_MS

    let dmg
    if (dodged) {
      dmg = 0
    } else if (this.guarded) {
      dmg = Math.max(1, Math.floor(this.enemyStats.attack / 2))
    } else {
      dmg = this.enemyStats.attack
      if (this.jumpPressedAt === null) this.shake(this.playerIconTarget)
    }

    setTimeout(() => { this.projectileTarget.hidden = true }, 150)

    this.playerStats.hp = Math.max(0, this.playerStats.hp - dmg)
    this.updateHud()

    if (this.isBossBattle) this.maybeTransformBoss()

    if (this.playerStats.hp <= 0) {
      this.endBattle(false)
      return
    }

    setTimeout(() => this.startPlayerTurn(), this.constructor.TURN_PAUSE_MS)
  }

  maybeTransformBoss() {
    const thresholds = this.constructor.BOSS_STAGE_THRESHOLDS
    const stageSprites = this.bossValue.stage_sprite_urls

    while (this.bossStageIndex < thresholds.length) {
      const hpRatio = this.enemyStats.hp / this.enemyStats.maxHp
      if (hpRatio > thresholds[this.bossStageIndex]) break

      const spriteUrl = stageSprites[Math.floor(Math.random() * stageSprites.length)]
      this.enemyIconTarget.src = spriteUrl
      this.enemyStats.attack = Math.round(this.enemyStats.attack * this.constructor.BOSS_ATTACK_MULTIPLIER)
      this.bossStageIndex += 1
      this.updateHud()
    }
  }

  shake(el) {
    el.animate(
      [
        { transform: "translateX(0)" }, { transform: "translateX(-6px)" },
        { transform: "translateX(6px)" }, { transform: "translateX(0)" },
      ],
      { duration: 180 }
    )
  }

  // 攻撃音は音声ファイルを追加せず、Web Audio APIのオシレーターでその場で
  // 合成する(著作権上、外部音源を使わない方針。ガチャのBGM合成と同じ考え方)。
  // 自分側=高め+square波、敵側=低め+sawtooth波で基本の作り分けをした上で、
  // 攻撃の種類(炎/氷/衝撃波/光線)ごとに周波数の変化パターンを変える。
  ensureAudioContext() {
    if (!this.audioContext) {
      const AudioContextClass = window.AudioContext || window.webkitAudioContext
      this.audioContext = new AudioContextClass()
    }
    if (this.audioContext.state === "suspended") this.audioContext.resume().catch(() => {})
    return this.audioContext
  }

  playAttackSound(side, kind) {
    try {
      const ctx = this.ensureAudioContext()
      const now = ctx.currentTime
      const baseFreq = side === "player" ? 520 : 260

      const oscillator = ctx.createOscillator()
      const gain = ctx.createGain()
      oscillator.connect(gain)
      gain.connect(ctx.destination)

      oscillator.type = side === "player" ? "square" : "sawtooth"
      let duration = 0.2

      switch (kind) {
        case "fire":
          oscillator.frequency.setValueAtTime(baseFreq * 0.9, now)
          oscillator.frequency.exponentialRampToValueAtTime(baseFreq * 0.5, now + 0.15)
          duration = 0.18
          break
        case "ice":
          oscillator.type = "sine"
          oscillator.frequency.setValueAtTime(baseFreq * 1.8, now)
          duration = 0.3
          break
        case "shockwave":
          oscillator.frequency.setValueAtTime(baseFreq * 0.5, now)
          duration = 0.2
          break
        case "beam":
          oscillator.frequency.setValueAtTime(baseFreq, now)
          oscillator.frequency.exponentialRampToValueAtTime(baseFreq * 2.2, now + 0.2)
          duration = 0.22
          break
      }

      gain.gain.setValueAtTime(0.2, now)
      gain.gain.exponentialRampToValueAtTime(0.001, now + duration)

      oscillator.start(now)
      oscillator.stop(now + duration)
    } catch (error) {
      // 自動再生制限等で失敗しても演出自体は止めない
      console.error("attack sound failed", error)
    }
  }

  endBattle(playerWon) {
    this.gameOver = true
    this.attackButtonTarget.disabled = true
    this.jumpButtonTarget.disabled = true
    this.guardButtonTarget.disabled = true
    if (this.enemyTurnTimer) clearTimeout(this.enemyTurnTimer)

    if (playerWon) {
      this.resultLabelTarget.textContent = `🎉 勝利！ ${this.enemyStats.name} を たおした！`
    } else {
      this.resultLabelTarget.textContent = `💀 敗北… ${this.playerStats.name} は たおれた`
    }

    this.reportResult(playerWon ? "win" : "lose")
  }

  // レインボーコインという実質的な報酬が絡む通信なので、送りっぱなしにはせず
  // 成功/失敗どちらもプレイヤーにわかる形で表示する(黙って握りつぶさない)。
  async reportResult(result) {
    try {
      const response = await fetch(this.reportUrlValue, {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": this.csrfValue },
        body: JSON.stringify({ mode: this.mode, result }),
      })

      if (!response.ok) {
        this.resultLabelTarget.textContent += " ⚠ 報酬の受け取りに失敗しました。通信環境をご確認ください。"
        return
      }

      const data = await response.json()
      if (data.rainbow_coins_awarded > 0) {
        this.resultLabelTarget.textContent += ` 🌈 レインボーコインを${data.rainbow_coins_awarded}枚獲得！`
      }
    } catch (error) {
      this.resultLabelTarget.textContent += " ⚠ 報酬の受け取りに失敗しました。通信環境をご確認ください。"
      console.error("battle result report failed", error)
    }
  }

  backToList() {
    if (this.enemyTurnTimer) clearTimeout(this.enemyTurnTimer)
    this.selectedPlayerIndex = -1
    this.selectedEnemyIndex = -1
    this.refreshGridHighlights()
    this.updateStartButton()
    this.battlePanelTarget.hidden = true
    this.selectionPanelTarget.hidden = false
  }
}
