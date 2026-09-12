import { Controller } from "@hotwired/stimulus"

// マイページのガチャ演出。Godotクライアント(gacha_scene.gd)と同じ
// 「コインが落ちる → ガチャマシンが揺れる → モンスターが飛び出す」という
// 一連の演出を、ページ遷移なしでJavaScriptから再現する。
export default class extends Controller {
  static targets = [
    "coinLabel", "rainbowCoinLabel", "coinSprite", "machineSprite", "knobSprite", "capsuleSprite", "domeSwirl",
    "revealHolder", "resultLabel", "pullButton", "sevenButton",
  ]

  static values = {
    pullUrl: String,
    sevenUrl: String,
    csrf: String,
    spriteMap: Object,
    coinIcon: String,
    machineIcon: String,
    knobFrames: Array,
    capsuleClosedMap: Object,
    capsuleOpenMap: Object,
    coinSound: String,
    knobSound: String,
    capsuleDropSound: String,
    hitSound: String,
    missSound: String,
    cost: Number,
    sevenCost: Number,
  }

  static COIN_DROP_MS = 400
  static MACHINE_SHAKE_MS = 400
  static KNOB_FRAME_MS = 120
  static CAPSULE_DROP_MS = 350
  static CAPSULE_OPEN_MS = 300

  connect() {
    this.coinSpriteTarget.src = this.coinIconValue
    this.machineSpriteTarget.src = this.machineIconValue
    this.isPulling = false
  }

  pull() {
    this.run(this.pullUrlValue)
  }

  pullSeven() {
    this.run(this.sevenUrlValue)
  }

  async run(url) {
    if (this.isPulling) return
    this.isPulling = true
    this.pullButtonTarget.disabled = true
    this.sevenButtonTarget.disabled = true
    this.resultLabelTarget.textContent = ""
    this.revealHolderTarget.innerHTML = ""

    const [, data] = await Promise.all([this.playAnimation(), this.requestPull(url)])
    this.showResult(data)

    this.isPulling = false
    this.updateButtonState()
  }

  // コイン投入アニメーション → ガチャマシンが揺れる → レバーを回す →
  // カプセルが落ちて開く、の順に再生する。この演出はあくまで「回した」ことを
  // 伝える表現で、実際の当落判定はサーバー側
  // (Gamification::GachaPullService / SevenGachaPullService)が担当している。
  playAnimation() {
    return new Promise((resolve) => {
      this.playSound(this.coinSoundValue)
      this.coinSpriteTarget.classList.remove("dropping")
      void this.coinSpriteTarget.offsetWidth // アニメーションを毎回頭から再生させるための強制リフロー
      this.coinSpriteTarget.classList.add("dropping")

      setTimeout(() => {
        this.machineSpriteTarget.classList.remove("shaking")
        void this.machineSpriteTarget.offsetWidth
        this.machineSpriteTarget.classList.add("shaking")

        setTimeout(() => {
          this.playKnobTurn().then(() => this.playCapsuleStage()).then(resolve)
        }, this.constructor.MACHINE_SHAKE_MS)
      }, this.constructor.COIN_DROP_MS)
    })
  }

  // レバーを4コマ差し替えて回転を表現する。ドーム内のカプセルも
  // レバーを回している間だけ連動してくるくる回す。
  playKnobTurn() {
    return new Promise((resolve) => {
      this.playSound(this.knobSoundValue)
      this.knobSpriteTarget.classList.add("visible")
      this.domeSwirlTarget.classList.remove("spinning")
      void this.domeSwirlTarget.offsetWidth
      this.domeSwirlTarget.classList.add("spinning")
      let frame = 0
      const step = () => {
        this.knobSpriteTarget.src = this.knobFramesValue[frame]
        frame += 1
        if (frame < this.knobFramesValue.length) {
          setTimeout(step, this.constructor.KNOB_FRAME_MS)
        } else {
          setTimeout(() => {
            this.knobSpriteTarget.classList.remove("visible")
            this.domeSwirlTarget.classList.remove("spinning")
            resolve()
          }, this.constructor.KNOB_FRAME_MS)
        }
      }
      step()
    })
  }

  // ランダムな色のカプセルが落ちてきて、少し間を置いてから開く。
  // 色は結果モンスターのrarityとは無関係な、見た目だけのランダム演出。
  playCapsuleStage() {
    return new Promise((resolve) => {
      const color = this.pickCapsuleColor()
      this.capsuleSpriteTarget.src = this.capsuleClosedMapValue[color]
      this.capsuleSpriteTarget.classList.remove("dropped", "opened")
      void this.capsuleSpriteTarget.offsetWidth
      this.capsuleSpriteTarget.classList.add("visible", "dropped")
      this.playSound(this.capsuleDropSoundValue)

      setTimeout(() => {
        this.capsuleSpriteTarget.src = this.capsuleOpenMapValue[color]
        this.capsuleSpriteTarget.classList.add("opened")

        setTimeout(() => {
          this.capsuleSpriteTarget.classList.remove("visible", "dropped", "opened")
          resolve()
        }, this.constructor.CAPSULE_OPEN_MS)
      }, this.constructor.CAPSULE_DROP_MS)
    })
  }

  pickCapsuleColor() {
    const colors = Object.keys(this.capsuleClosedMapValue)
    return colors[Math.floor(Math.random() * colors.length)]
  }

  // 自動再生制限等で失敗しても演出自体は止めない
  playSound(url) {
    if (!url) return
    new Audio(url).play().catch(() => {})
  }

  async requestPull(url) {
    try {
      const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json", Accept: "application/json", "X-CSRF-Token": this.csrfValue },
      })
      const data = await response.json()
      data.ok = response.ok
      return data
    } catch (error) {
      console.error("gacha request failed", error)
      return { ok: false, error: "network_error" }
    }
  }

  showResult(data) {
    if (!data.ok) {
      if (data.error === "insufficient_coins") {
        this.resultLabelTarget.textContent = "コインが足りません。"
      } else if (data.error === "insufficient_rainbow_coins") {
        this.resultLabelTarget.textContent = "レインボーコインが足りません。"
      } else if (data.error === "monster_limit_reached") {
        this.resultLabelTarget.textContent = "モンスターの所持数が上限(100体)に達しています。"
      } else {
        this.resultLabelTarget.textContent = "通信エラーが発生しました。"
      }
      return
    }

    if ("pulls" in data) {
      this.showSevenResult(data)
    } else {
      this.showSingleResult(data)
    }

    if (typeof data.coins === "number") this.coinLabelTarget.textContent = data.coins
    if (typeof data.rainbow_coins === "number") this.rainbowCoinLabelTarget.textContent = data.rainbow_coins
  }

  showSingleResult(data) {
    if (data.hit && data.monster) {
      this.resultLabelTarget.textContent = `🎉 ${data.monster.name} を獲得しました！`
      this.revealMonster(data.monster)
      this.playSound(this.hitSoundValue)
    } else {
      this.resultLabelTarget.textContent = "ハズレでした…また挑戦してください。"
      this.playSound(this.missSoundValue)
    }
  }

  showSevenResult(data) {
    const hits = data.pulls.filter((pull) => pull.hit && pull.monster)
    if (hits.length > 0) {
      this.resultLabelTarget.textContent = `🌈 7連ガチャで${hits.length}体獲得！`
      hits.forEach((pull) => this.revealMonster(pull.monster))
      this.playSound(this.hitSoundValue)
    } else {
      this.resultLabelTarget.textContent = "🌈 7連ガチャ…残念、今回は全てハズレでした。"
      this.playSound(this.missSoundValue)
    }
  }

  // カプセルが開いてモンスターが飛び出すような演出でアイコンを追加する
  // (CSS側の gacha-reveal-pop アニメーションでポップイン+フェードインさせる)。
  revealMonster(monster) {
    const item = document.createElement("div")
    item.className = "gacha-reveal-item"

    const img = document.createElement("img")
    img.src = this.spriteMapValue[monster.sprite_key] || ""
    img.alt = monster.name

    const span = document.createElement("span")
    span.textContent = monster.name

    item.append(img, span)
    this.revealHolderTarget.appendChild(item)
  }

  updateButtonState() {
    const coins = Number(this.coinLabelTarget.textContent)
    const rainbowCoins = Number(this.rainbowCoinLabelTarget.textContent)
    this.pullButtonTarget.disabled = coins < this.costValue
    this.sevenButtonTarget.disabled = rainbowCoins < this.sevenCostValue
  }
}
