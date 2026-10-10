import { Controller } from "@hotwired/stimulus"

// Web版の対戦ミニゲーム。ターン制で自分の攻撃と
// 相手の飛び道具(ジャンプで回避/ガードで軽減)を繰り返す。
// 各モンスターは固有の3攻撃を持ち、うち1つは必ず突進(charge)。
export default class extends Controller {
  static targets = [
    "selectionPanel", "instructionLabel", "selfModeButton", "bossModeButton",
    "monsterGrid", "startBattleButton",
    "battlePanel", "turnLabel", "playerPlatform", "enemyPlatform", "playerIcon", "enemyIcon", "projectile", "projectileImage",
    "playerNameAtk", "playerHpFill", "playerHpNum",
    "enemyNameAtk", "enemyHpFill", "enemyHpNum",
    "attackButton", "attackChoicePanel", "jumpButton", "guardButton", "resultLabel",
    "weaknessLabel",
  ]

  static values = {
    monsters: Array,
    boss: Object,
    reportUrl: String,
    csrf: String,
    attackImages: Object,
  }

  static ATTACK_NAMES = {
    charge:    "ラッシュチャージ",
    fire:      "フレイムウェーブ",
    ice:       "アイスブレイカー",
    beam:      "ライトビーム",
    lightning: "サンダーボルト",
    wind:      "ブレードウィンド",
    shockwave: "ソニックブレイク",
  }

  static ATTACK_ICONS = {
    charge:    "⚔️",
    fire:      "🔥",
    ice:       "❄️",
    beam:      "✨",
    lightning: "⚡",
    wind:      "🌪️",
    shockwave: "💥",
  }

  static TYPE_EFFECT = {
    "たまご": "#ffd933", "ドリンク": "#66ccdd", "スイーツ": "#f299bf",
    "デザート": "#bf99e6", "めん類": "#f28c33", "がっつり": "#d94033",
    "やさい": "#59bf59", "なつのあじ": "#4cd9d9", "おつまみ": "#997f4d",
  }

  // 突進(charge)が基本攻撃力そのまま(1.0)。他の技はモンスターごとにバラバラな値にするための倍率。
  static ATTACK_POWER_MULTIPLIER = {
    charge:    1.0,
    fire:      1.8,
    ice:       1.5,
    beam:      1.6,
    lightning: 2.2,
    wind:      1.2,
    shockwave: 1.7,
  }

  static BOSS_STAGE_THRESHOLDS = [0.75, 0.50, 0.25]
  static BOSS_ATTACK_MULTIPLIER = 1.25
  static FIREBALL_TRAVEL_MS = 1000
  static CHARGE_TRAVEL_MS = 1800
  static DODGE_WINDOW_MS = 250
  static MIN_HOP_HALF_MS = 400
  static TURN_PAUSE_MS = 500

  connect() {
    this.mode = "self"
    this.selectedPlayerIndex = -1
    this.selectedEnemyIndex = -1
    this.bossStageIndex = 0
    this.bossAttackKind = "fire"
    this.turn = "player"
    this.gameOver = false
    this.isAnimating = false
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
      hp: playerMonster.hp, maxHp: playerMonster.hp,
      attack: playerMonster.attack, defense: playerMonster.defense || 0,
      attacks: playerMonster.attacks || ["charge", "fire", "beam"],
      weakness: playerMonster.weakness || null,
    }

    this.isBossBattle = this.mode === "boss"
    this.bossStageIndex = 0
    this.bossAttackKind = "fire"

    if (this.isBossBattle) {
      const boss = this.bossValue
      this.enemyStats = {
        name: boss.name, spriteUrl: boss.sprite_url, typeLabel: boss.type_label,
        hp: boss.hp, maxHp: boss.hp,
        attack: boss.attack, defense: boss.defense || 0,
        attacks: boss.attacks || ["charge", "fire", "shockwave"],
        weakness: boss.weakness || null,
      }
    } else {
      const enemyMonster = this.monstersValue[this.selectedEnemyIndex]
      this.enemyStats = {
        name: enemyMonster.name, spriteUrl: enemyMonster.sprite_url, typeLabel: enemyMonster.type_label,
        hp: enemyMonster.hp, maxHp: enemyMonster.hp,
        attack: enemyMonster.attack, defense: enemyMonster.defense || 0,
        attacks: enemyMonster.attacks || ["charge", "fire", "beam"],
        weakness: enemyMonster.weakness || null,
      }
    }

    // 前の対戦で残ったアニメーション状態（消滅演出など）をリセット
    ;[this.playerIconTarget, this.enemyIconTarget].forEach(icon => {
      icon.getAnimations().forEach(a => a.cancel())
      const shadow = icon.closest(".battle-platform")?.querySelector(".battle-shadow")
      if (shadow) shadow.getAnimations().forEach(a => a.cancel())
    })

    this.playerIconTarget.src = this.playerStats.spriteUrl
    this.enemyIconTarget.src = this.enemyStats.spriteUrl
    this.element.classList.toggle("battle-is-boss", this.isBossBattle)

    this.gameOver = false
    this.resultLabelTarget.textContent = ""
    this.projectileTarget.hidden = true

    this.selectionPanelTarget.hidden = true
    this.battlePanelTarget.hidden = false

    this.startBgm(this.isBossBattle)
    this.renderAttackButtons()
    this.updateHud()
    this.startPlayerTurn()
  }

  // プレイヤーモンスターの固有攻撃3種のボタンを動的に生成する
  renderAttackButtons() {
    const panel = this.attackChoicePanelTarget
    panel.innerHTML = ""
    const names = this.constructor.ATTACK_NAMES
    const icons = this.constructor.ATTACK_ICONS

    this.playerStats.attacks.forEach((kind) => {
      const btn = document.createElement("button")
      btn.type = "button"
      btn.className = "btn battle-choice-btn"
      btn.dataset.kind = kind
      btn.dataset.action = "battle#chooseAttack"
      btn.textContent = `${icons[kind] || ""} ${names[kind] || kind}`
      panel.appendChild(btn)
    })
  }

  updateHud() {
    this.playerNameAtkTarget.textContent = this.playerStats.name
    this.playerHpFillTarget.style.width = `${Math.max(0, this.playerStats.hp) / this.playerStats.maxHp * 100}%`
    this.playerHpNumTarget.textContent = `${Math.max(0, this.playerStats.hp)} / ${this.playerStats.maxHp}`

    this.enemyNameAtkTarget.textContent = this.enemyStats.name
    this.enemyHpFillTarget.style.width = `${Math.max(0, this.enemyStats.hp) / this.enemyStats.maxHp * 100}%`
    this.enemyHpNumTarget.textContent = `${Math.max(0, this.enemyStats.hp)} / ${this.enemyStats.maxHp}`
  }

  // --- ターン進行 ---

  startPlayerTurn() {
    this.isAnimating = false
    this.turn = "player"
    this.turnLabelTarget.textContent = "あなたのターン"
    this.attackButtonTarget.disabled = false
    this.attackButtonTarget.hidden = false
    this.attackChoicePanelTarget.hidden = true
    this.jumpButtonTarget.disabled = true
    this.guardButtonTarget.disabled = true
  }

  attack() {
    if (this.turn !== "player" || this.gameOver || this.isAnimating) return
    this.attackButtonTarget.hidden = true
    this.attackChoicePanelTarget.hidden = false
  }

  chooseAttack(event) {
    if (this.turn !== "player" || this.gameOver || this.isAnimating) return
    this.isAnimating = true
    const kind = event.currentTarget.dataset.kind
    this.attackChoicePanelTarget.hidden = true
    this.attackButtonTarget.hidden = false
    this.attackButtonTarget.disabled = true

    const duration = kind === "charge" ? this.constructor.CHARGE_TRAVEL_MS : this.constructor.FIREBALL_TRAVEL_MS
    this.launchAttack("player", kind, duration)
    setTimeout(() => this.resolvePlayerAttack(kind), duration)
  }

  resolvePlayerAttack(kind) {
    this.projectileTarget.hidden = true

    const multiplier = this.constructor.ATTACK_POWER_MULTIPLIER[kind] ?? 1.0
    const rawDmg = Math.max(1, Math.round(this.playerStats.attack * multiplier) - this.enemyStats.defense)
    const isWeak = kind === this.enemyStats.weakness
    const dmg = isWeak ? Math.round(rawDmg * 1.5) : rawDmg

    this.enemyStats.hp = Math.max(0, this.enemyStats.hp - dmg)
    this.shake(this.enemyIconTarget)
    if (isWeak) this.showWeaknessFlash()
    this.updateHud()

    if (this.enemyStats.hp <= 0) {
      this.playDefeatSound()
      this.defeatAnimation(this.enemyIconTarget).then(() => this.endBattle(true))
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

    // ボス戦: 突進とステージ固定技をランダムに選ぶ。通常戦: attacks配列からランダムに選ぶ。
    const kind = this.isBossBattle
      ? (Math.random() < 0.5 ? "charge" : this.bossAttackKind)
      : this.enemyStats.attacks[Math.floor(Math.random() * this.enemyStats.attacks.length)]

    const duration = kind === "charge" ? this.constructor.CHARGE_TRAVEL_MS : this.constructor.FIREBALL_TRAVEL_MS
    this.launchAttack("enemy", kind, duration)

    let actualImpactMs
    if (kind === "charge") {
      // 突進: スプライトがプレイヤー位置に到達する瞬間に着弾判定
      // 前進フェーズは duration * 0.55 でアリーナ端(arenaWidth+120)まで直線移動
      const chargeArena = this.enemyPlatformTarget.closest(".battle-arena")
      const chargeArenaWidth = chargeArena ? chargeArena.clientWidth : 600
      const totalChargeDistance = chargeArenaWidth + 120
      const distToPlayer = this.enemyPlatformTarget.offsetLeft
        - (this.playerPlatformTarget.offsetLeft + this.playerPlatformTarget.offsetWidth)
      const forwardDuration = duration * 0.70
      actualImpactMs = totalChargeDistance > 0
        ? Math.round((distToPlayer / totalChargeDistance) * forwardDuration)
        : Math.round(forwardDuration * 0.5)
    } else {
      const enemyLeft   = this.enemyPlatformTarget.offsetLeft
      const playerRight = this.playerPlatformTarget.offsetLeft + this.playerPlatformTarget.offsetWidth
      const totalPx     = enemyLeft + 60
      const distToPlayer = enemyLeft - playerRight
      actualImpactMs = totalPx > 0
        ? Math.round((distToPlayer / totalPx) * duration)
        : duration
    }

    this.impactAt         = Date.now() + actualImpactMs
    this.attackAnimEndsAt = Date.now() + duration
    this.currentEnemyKind = kind
    this.enemyTurnTimer   = setTimeout(() => this.resolveEnemyAttack(), actualImpactMs)
  }

  // 攻撃の種類に応じてプロジェクタイルか突進かを振り分けるメソッド
  launchAttack(side, kind, duration) {
    if (kind === "charge") {
      this.launchCharge(side, duration)
    } else {
      const typeLabel = side === "player" ? this.playerStats.typeLabel : this.enemyStats.typeLabel
      this.launchProjectile(side, typeLabel, duration, kind)
    }
  }

  // モンスタースプライト自体が突進して戻るアニメーション
  launchCharge(side, duration) {
    const sprite = side === "enemy" ? this.enemyIconTarget : this.playerIconTarget
    const fromPlatform = side === "enemy" ? this.enemyPlatformTarget : this.playerPlatformTarget
    const arena = fromPlatform.closest(".battle-arena")
    const arenaWidth = arena ? arena.clientWidth : 600
    const dir = side === "enemy" ? -1 : 1
    // アリーナの端まで突進する距離
    const distance = arenaWidth + 120

    this.playAttackSound(side, "charge")

    // 前進55%はlinear(一定速で端まで)→残り45%で瞬間帰還
    sprite.animate([
      { transform: "translateX(0) scaleX(1)",                                                    offset: 0 },
      { transform: `translateX(${dir * distance}px) scaleX(${dir > 0 ? 1.2 : -1.2})`,           offset: 0.70 },
      { transform: "translateX(0) scaleX(1)",                                                    offset: 1 },
    ], { duration, easing: "linear" })
  }

  // 飛び道具プロジェクタイルを発射する
  launchProjectile(side, typeLabel, duration, kindOverride = null) {
    const kind = kindOverride || "fire"
    const color = this.constructor.TYPE_EFFECT[typeLabel] || "#cccccc"

    const fromPlatform = side === "player" ? this.playerPlatformTarget : this.enemyPlatformTarget

    const arena = fromPlatform.closest(".battle-arena")
    const fixedY = arena ? arena.clientHeight * 0.85 : fromPlatform.offsetTop + fromPlatform.offsetHeight * 0.4

    const arenaWidth = arena ? arena.clientWidth : 600
    const start = {
      left: side === "player"
        ? fromPlatform.offsetLeft + fromPlatform.offsetWidth
        : fromPlatform.offsetLeft,
      top: fixedY,
    }
    const end = {
      left: side === "player" ? arenaWidth + 60 : -60,
      top: fixedY,
    }

    const el = this.projectileTarget
    el.className = `battle-projectile battle-projectile--${kind}`
    el.style.setProperty("--projectile-color", color)
    el.style.setProperty("--projectile-angle", "0deg")
    el.style.left = `${start.left}px`
    el.style.top = `${start.top}px`

    const imageUrl = this.attackImagesValue[kind]
    if (imageUrl) {
      this.projectileImageTarget.src = imageUrl
      this.projectileImageTarget.hidden = false
    } else {
      this.projectileImageTarget.hidden = true
    }

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
      [
        { transform: "translateY(0)",      easing: "cubic-bezier(0.33, 1, 0.68, 1)" },
        { transform: "translateY(-130px)", easing: "cubic-bezier(0.32, 0, 0.67, 0)" },
        { transform: "translateY(0)" },
      ],
      { duration: half * 2 }
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

    const dodged = this.jumpPressedAt !== null

    const multiplier = this.constructor.ATTACK_POWER_MULTIPLIER[this.currentEnemyKind] ?? 1.0
    const rawDmg = Math.max(1, Math.round(this.enemyStats.attack * multiplier) - this.playerStats.defense)
    const isWeak = this.currentEnemyKind === this.playerStats.weakness

    let dmg
    if (dodged) {
      dmg = 0
    } else if (this.guarded) {
      dmg = Math.max(1, Math.floor(rawDmg / 2))
    } else {
      dmg = isWeak ? Math.round(rawDmg * 1.5) : rawDmg
      if (this.jumpPressedAt === null) this.shake(this.playerIconTarget)
    }

    const remainingMs = Math.max(150, (this.attackAnimEndsAt || 0) - Date.now())
    setTimeout(() => { this.projectileTarget.hidden = true }, remainingMs)

    this.playerStats.hp = Math.max(0, this.playerStats.hp - dmg)
    if (!dodged && isWeak) this.showWeaknessFlash()
    this.updateHud()

    if (this.isBossBattle) this.maybeTransformBoss()

    if (this.playerStats.hp <= 0) {
      this.playDefeatSound()
      this.defeatAnimation(this.playerIconTarget).then(() => this.endBattle(false))
      return
    }

    // アニメーションが完全に終わってからプレイヤーターンを開始する
    setTimeout(() => this.startPlayerTurn(), remainingMs + this.constructor.TURN_PAUSE_MS)
  }

  maybeTransformBoss() {
    const thresholds = this.constructor.BOSS_STAGE_THRESHOLDS
    const bossStages = this.bossValue.boss_stages

    while (this.bossStageIndex < thresholds.length) {
      const hpRatio = this.enemyStats.hp / this.enemyStats.maxHp
      if (hpRatio > thresholds[this.bossStageIndex]) break

      const stage = bossStages[this.bossStageIndex]
      this.enemyIconTarget.src = stage.sprite
      this.bossAttackKind = stage.kind
      this.enemyStats.attack = Math.round(this.enemyStats.attack * this.constructor.BOSS_ATTACK_MULTIPLIER)
      this.bossStageIndex += 1
      this.updateHud()
    }
  }

  // 弱点ヒット時に「弱点！」テキストをアリーナ中央に一瞬表示する
  showWeaknessFlash() {
    const arena = this.enemyPlatformTarget.closest(".battle-arena")
    if (!arena) return

    const el = document.createElement("div")
    el.className = "battle-weakness-flash"
    el.textContent = "効果ばつぐん！"
    arena.appendChild(el)

    el.animate(
      [
        { opacity: 0, transform: "scale(0.5) translateY(0)" },
        { opacity: 1, transform: "scale(1.2) translateY(-10px)", offset: 0.3 },
        { opacity: 0, transform: "scale(1) translateY(-30px)" },
      ],
      { duration: 900 }
    ).onfinish = () => el.remove()
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

  // 撃破SE: ドンッと鳴ってから音が下降して消える
  playDefeatSound() {
    try {
      const ctx = this.ensureAudioContext()
      const now = ctx.currentTime

      // 衝撃音（低いインパクト）
      const impact = ctx.createOscillator()
      const impactGain = ctx.createGain()
      impact.connect(impactGain); impactGain.connect(ctx.destination)
      impact.type = "sawtooth"
      impact.frequency.setValueAtTime(180, now)
      impact.frequency.exponentialRampToValueAtTime(30, now + 0.25)
      impactGain.gain.setValueAtTime(0.6, now)
      impactGain.gain.exponentialRampToValueAtTime(0.001, now + 0.25)
      impact.start(now); impact.stop(now + 0.25)

      // 下降グリッサンド（消えていく感じ）
      const fall = ctx.createOscillator()
      const fallGain = ctx.createGain()
      fall.connect(fallGain); fallGain.connect(ctx.destination)
      fall.type = "sine"
      fall.frequency.setValueAtTime(440, now + 0.05)
      fall.frequency.exponentialRampToValueAtTime(60, now + 0.7)
      fallGain.gain.setValueAtTime(0.3, now + 0.05)
      fallGain.gain.exponentialRampToValueAtTime(0.001, now + 0.7)
      fall.start(now + 0.05); fall.stop(now + 0.75)

      // ホワイトノイズのクラッシュ
      const buf = ctx.createBuffer(1, Math.floor(ctx.sampleRate * 0.15), ctx.sampleRate)
      const data = buf.getChannelData(0)
      for (let i = 0; i < data.length; i++) data[i] = Math.random() * 2 - 1
      const noise = ctx.createBufferSource()
      const noiseFilt = ctx.createBiquadFilter()
      const noiseGain = ctx.createGain()
      noise.buffer = buf
      noise.connect(noiseFilt); noiseFilt.connect(noiseGain); noiseGain.connect(ctx.destination)
      noiseFilt.type = "lowpass"
      noiseFilt.frequency.setValueAtTime(3000, now)
      noiseGain.gain.setValueAtTime(0.4, now)
      noiseGain.gain.exponentialRampToValueAtTime(0.001, now + 0.15)
      noise.start(now)
    } catch (e) {
      console.error("defeat sound failed", e)
    }
  }

  // 倒されたモンスターが白くフラッシュしてから縮んで消える演出（影も同時に消す）
  defeatAnimation(el) {
    const shadow = el.closest(".battle-platform")?.querySelector(".battle-shadow")
    if (shadow) {
      shadow.animate(
        [{ opacity: 1 }, { opacity: 1, offset: 0.3 }, { opacity: 0 }],
        { duration: 700, easing: "ease-in", fill: "forwards" }
      )
    }
    return el.animate(
      [
        { filter: "brightness(1)",    transform: "scale(1)",              opacity: 1 },
        { filter: "brightness(8)",    transform: "scale(1.15)",           opacity: 1,   offset: 0.15 },
        { filter: "brightness(1)",    transform: "scale(1)",              opacity: 1,   offset: 0.30 },
        { filter: "brightness(4)",    transform: "scale(1.05)",           opacity: 0.8, offset: 0.50 },
        { filter: "brightness(0.5)",  transform: "scale(0.4) translateY(30px)", opacity: 0,   offset: 1 },
      ],
      { duration: 700, easing: "ease-in", fill: "forwards" }
    ).finished
  }

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
        case "charge":
          oscillator.type = "sawtooth"
          oscillator.frequency.setValueAtTime(baseFreq * 0.4, now)
          oscillator.frequency.exponentialRampToValueAtTime(baseFreq * 1.8, now + 0.25)
          oscillator.frequency.exponentialRampToValueAtTime(baseFreq * 0.3, now + 0.5)
          duration = 0.5
          break
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
        case "lightning":
          oscillator.type = "sawtooth"
          oscillator.frequency.setValueAtTime(baseFreq * 3.0, now)
          oscillator.frequency.exponentialRampToValueAtTime(baseFreq * 0.3, now + 0.12)
          duration = 0.14
          break
        case "wind":
          oscillator.type = "sine"
          oscillator.frequency.setValueAtTime(baseFreq * 1.2, now)
          oscillator.frequency.linearRampToValueAtTime(baseFreq * 0.8, now + 0.25)
          duration = 0.28
          break
      }

      gain.gain.setValueAtTime(0.2, now)
      gain.gain.exponentialRampToValueAtTime(0.001, now + duration)

      oscillator.start(now)
      oscillator.stop(now + duration)
    } catch (error) {
      console.error("attack sound failed", error)
    }
  }

  // === BGM System ===

  startBgm(isBoss) {
    this.stopBgm()
    const ctx = this.ensureAudioContext()

    const master = ctx.createGain()
    master.gain.setValueAtTime(0, ctx.currentTime)
    master.gain.linearRampToValueAtTime(0.18, ctx.currentTime + 1.2)
    master.connect(ctx.destination)
    this._bgmMaster = master

    const bpm = isBoss ? 82 : 140
    this._bgmStepSec = 60 / bpm / 4   // 16分音符
    this._bgmStep = 0
    this._bgmNextTime = ctx.currentTime + 0.05
    this._bgmIsBoss = isBoss
    this._bgmPattern = isBoss ? this._bossBgmPattern() : this._normalBgmPattern()

    const schedule = () => {
      if (!this.audioContext) return
      const ahead = this.audioContext.currentTime + 0.25
      while (this._bgmNextTime < ahead) {
        this._scheduleBgmStep(this.audioContext, this._bgmNextTime, this._bgmStep, master)
        this._bgmNextTime += this._bgmStepSec
        this._bgmStep = (this._bgmStep + 1) % this._bgmPattern.length
      }
    }
    schedule()
    this._bgmTimer = setInterval(schedule, 80)
  }

  stopBgm() {
    if (this._bgmTimer) { clearInterval(this._bgmTimer); this._bgmTimer = null }
    if (this._bgmMaster && this.audioContext) {
      this._bgmMaster.gain.setTargetAtTime(0, this.audioContext.currentTime, 0.4)
    }
    this._bgmMaster = null
  }

  // 通常対戦BGM: Aマイナーペンタトニック、アップビート、BPM140
  _normalBgmPattern() {
    const A2=110, E2=82.4, G2=98, D2=73.4
    const A3=220, C4=261.6, D4=293.7, E4=329.6, G4=392, A4=440, G3=196, E3=164.8
    const _ = null
    // [メロディHz, バスHz, キック(0/1), ハイハット(0/1)]  32ステップ = 2小節ループ
    return [
      [A4, A2, 1, 1], [E4, _,  0, 1], [C4, _,  0, 0], [A3, _,  0, 1],
      [G3, E2, 1, 1], [A3, _,  0, 1], [C4, _,  0, 0], [E4, _,  0, 1],
      [A4, A2, 1, 1], [G4, _,  0, 1], [E4, _,  0, 0], [C4, _,  0, 1],
      [A3, G2, 1, 1], [C4, _,  0, 1], [E4, _,  0, 0], [G4, _,  0, 1],
      [A4, A2, 1, 1], [A4, _,  0, 1], [G4, _,  0, 0], [E4, _,  0, 1],
      [D4, D2, 1, 1], [E4, _,  0, 1], [G4, _,  0, 0], [A4, _,  0, 1],
      [E4, A2, 1, 1], [C4, _,  0, 1], [A3, _,  0, 0], [G3, _,  0, 1],
      [A3, E2, 1, 1], [C4, _,  0, 1], [E4, _,  0, 0], [G4, _,  0, 1],
    ]
  }

  // ボス対戦BGM: Eマイナー、重厚なバスドローン、BPM82
  _bossBgmPattern() {
    const E1=41.2, B1=61.7, E2=82.4, A2=110, B2=123.5, D3=146.8, E3=164.8, G3=196, B3=246.9, D4=293.7
    const _ = null
    // 32ステップ = 2小節ループ
    return [
      [E3, E1, 1, 0], [_,  _,  0, 0], [_,  E1, 0, 0], [D3, _,  0, 1],
      [B2, B1, 1, 0], [_,  _,  0, 0], [_,  B1, 0, 0], [G3, _,  0, 1],
      [A2, E1, 1, 0], [_,  _,  0, 0], [_,  E1, 0, 0], [B2, _,  0, 1],
      [D3, B1, 1, 0], [B2, _,  0, 0], [_,  _,  0, 0], [G3, _,  0, 1],
      [E3, E1, 1, 0], [E3, _,  0, 0], [_,  E1, 0, 0], [D3, _,  0, 1],
      [B2, B1, 1, 0], [G3, _,  0, 0], [A2, E1, 0, 0], [B2, _,  0, 1],
      [G3, E1, 1, 0], [_,  _,  0, 0], [D3, E1, 0, 0], [B2, _,  0, 1],
      [A2, A2, 1, 0], [G3, _,  0, 0], [_,  B1, 0, 0], [D3, _,  0, 1],
    ]
  }

  _scheduleBgmStep(ctx, time, step, master) {
    const [melody, bass, kick, hihat] = this._bgmPattern[step]
    const dur = this._bgmStepSec
    const isBoss = this._bgmIsBoss

    if (melody) {
      const osc = ctx.createOscillator()
      const g = ctx.createGain()
      osc.connect(g); g.connect(master)
      osc.type = isBoss ? "sawtooth" : "square"
      osc.frequency.setValueAtTime(melody, time)
      const noteDur = dur * (isBoss ? 2.0 : 0.65)
      g.gain.setValueAtTime(isBoss ? 0.22 : 0.14, time)
      g.gain.exponentialRampToValueAtTime(0.001, time + noteDur)
      osc.start(time); osc.stop(time + noteDur)
    }

    if (bass) {
      const osc = ctx.createOscillator()
      const filt = ctx.createBiquadFilter()
      const g = ctx.createGain()
      osc.connect(filt); filt.connect(g); g.connect(master)
      osc.type = "sawtooth"
      filt.type = "lowpass"
      filt.frequency.setValueAtTime(isBoss ? 280 : 350, time)
      osc.frequency.setValueAtTime(bass, time)
      const bassDur = dur * (isBoss ? 4.0 : 1.8)
      g.gain.setValueAtTime(isBoss ? 0.45 : 0.30, time)
      g.gain.exponentialRampToValueAtTime(0.001, time + bassDur)
      osc.start(time); osc.stop(time + bassDur)
    }

    if (kick) {
      const osc = ctx.createOscillator()
      const g = ctx.createGain()
      osc.connect(g); g.connect(master)
      osc.type = "sine"
      osc.frequency.setValueAtTime(isBoss ? 140 : 90, time)
      osc.frequency.exponentialRampToValueAtTime(28, time + 0.1)
      g.gain.setValueAtTime(isBoss ? 0.9 : 0.6, time)
      g.gain.exponentialRampToValueAtTime(0.001, time + 0.18)
      osc.start(time); osc.stop(time + 0.22)
    }

    if (hihat) {
      try {
        const buf = ctx.createBuffer(1, Math.floor(ctx.sampleRate * 0.04), ctx.sampleRate)
        const data = buf.getChannelData(0)
        for (let i = 0; i < data.length; i++) data[i] = Math.random() * 2 - 1
        const src = ctx.createBufferSource()
        const filt = ctx.createBiquadFilter()
        const g = ctx.createGain()
        src.buffer = buf
        src.connect(filt); filt.connect(g); g.connect(master)
        filt.type = "highpass"
        filt.frequency.setValueAtTime(9000, time)
        g.gain.setValueAtTime(0.07, time)
        g.gain.exponentialRampToValueAtTime(0.001, time + 0.04)
        src.start(time)
      } catch (e) { /* ignore */ }
    }
  }

  // === BGM System End ===

  endBattle(playerWon) {
    this.gameOver = true
    this.attackButtonTarget.disabled = true
    this.attackButtonTarget.hidden = false
    this.attackChoicePanelTarget.hidden = true
    this.jumpButtonTarget.disabled = true
    this.guardButtonTarget.disabled = true
    if (this.enemyTurnTimer) clearTimeout(this.enemyTurnTimer)
    this.stopBgm()

    if (playerWon) {
      this.resultLabelTarget.textContent = `🎉 勝利！ ${this.enemyStats.name} を たおした！`
    } else {
      this.resultLabelTarget.textContent = `💀 敗北… ${this.playerStats.name} は たおれた`
    }

    this.reportResult(playerWon ? "win" : "lose")
  }

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
    this.stopBgm()
    this.attackChoicePanelTarget.hidden = true
    this.attackButtonTarget.hidden = false
    this.selectedPlayerIndex = -1
    this.selectedEnemyIndex = -1
    this.refreshGridHighlights()
    this.updateStartButton()
    this.battlePanelTarget.hidden = true
    this.selectionPanelTarget.hidden = false
  }
}
