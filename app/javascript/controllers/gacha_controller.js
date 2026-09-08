import { Controller } from "@hotwired/stimulus"

// マイページのガチャ演出。Godotクライアント(gacha_scene.gd)と同じ
// 「コインが落ちる → ガチャマシンが揺れる → モンスターが飛び出す」という
// 一連の演出を、ページ遷移なしでJavaScriptから再現する。
export default class extends Controller {
  static targets = [
    "coinLabel", "rainbowCoinLabel", "coinSprite", "machineSprite",
    "revealHolder", "resultLabel", "pullButton", "sevenButton",
  ]

  static values = {
    pullUrl: String,
    sevenUrl: String,
    csrf: String,
    spriteMap: Object,
    coinIcon: String,
    machineIcon: String,
    cost: Number,
    sevenCost: Number,
  }

  static COIN_DROP_MS = 400
  static MACHINE_SHAKE_MS = 400

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

  // コイン投入アニメーション → ガチャマシンが揺れる、の順に再生する。
  // この演出はあくまで「回した」ことを伝える表現で、実際の当落判定は
  // サーバー側(Gamification::GachaPullService / SevenGachaPullService)が担当している。
  playAnimation() {
    return new Promise((resolve) => {
      this.coinSpriteTarget.classList.remove("dropping")
      void this.coinSpriteTarget.offsetWidth // アニメーションを毎回頭から再生させるための強制リフロー
      this.coinSpriteTarget.classList.add("dropping")

      setTimeout(() => {
        this.machineSpriteTarget.classList.remove("shaking")
        void this.machineSpriteTarget.offsetWidth
        this.machineSpriteTarget.classList.add("shaking")

        setTimeout(resolve, this.constructor.MACHINE_SHAKE_MS)
      }, this.constructor.COIN_DROP_MS)
    })
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
    } else {
      this.resultLabelTarget.textContent = "ハズレでした…また挑戦してください。"
    }
  }

  showSevenResult(data) {
    const hits = data.pulls.filter((pull) => pull.hit && pull.monster)
    if (hits.length > 0) {
      this.resultLabelTarget.textContent = `🌈 7連ガチャで${hits.length}体獲得！`
      hits.forEach((pull) => this.revealMonster(pull.monster))
    } else {
      this.resultLabelTarget.textContent = "🌈 7連ガチャ…残念、今回は全てハズレでした。"
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
