import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { data: Object, url: String }
  static targets = ["container"]

  connect() {
    this._tooltip = this._createTooltip()
    this._currentYear = new Date().getFullYear()
    this._maxYear = this._currentYear
    this._buildGraph(this.dataValue)
  }

  disconnect() {
    this._tooltip?.remove()
  }

  async _fetchYear(year) {
    const url = `${this.urlValue}?year=${year}`
    const res = await fetch(url, { headers: { Accept: "application/json" } })
    const json = await res.json()
    return json.data
  }

  async _changeYear(delta) {
    const nextYear = this._currentYear + delta
    if (nextYear > this._maxYear) return

    this._currentYear = nextYear
    const data = nextYear === this._maxYear
      ? this.dataValue
      : await this._fetchYear(nextYear)

    this.containerTarget.innerHTML = ""
    this._buildGraph(data)
  }

  _buildGraph(data) {
    const { columns, monthLabels } = this._computeGrid(data, this._currentYear)

    const wrapper = document.createElement("div")
    wrapper.className = "cg-wrapper"

    // 曜日ラベル（年ナビ行の高さ分スペーサーを先頭に追加）
    const dayLabels = document.createElement("div")
    dayLabels.className = "cg-day-labels"
    const yearSpacer = document.createElement("span")
    yearSpacer.className = "cg-year-spacer"
    dayLabels.appendChild(yearSpacer)
    ;["月", "火", "水", "木", "金", "土", "日"].forEach(label => {
      const span = document.createElement("span")
      span.textContent = label
      dayLabels.appendChild(span)
    })

    const right = document.createElement("div")
    right.className = "cg-right"

    // 年ナビゲーション行
    const yearNav = document.createElement("div")
    yearNav.className = "cg-year-nav"

    const prevBtn = document.createElement("button")
    prevBtn.className = "cg-year-btn"
    prevBtn.textContent = "◄"
    prevBtn.setAttribute("aria-label", "前の年")
    prevBtn.addEventListener("click", () => this._changeYear(-1))

    const yearLabel = document.createElement("span")
    yearLabel.className = "cg-year-label"
    yearLabel.textContent = `${this._currentYear}年`

    const nextBtn = document.createElement("button")
    nextBtn.className = "cg-year-btn"
    nextBtn.textContent = "►"
    nextBtn.setAttribute("aria-label", "次の年")
    nextBtn.disabled = this._currentYear >= this._maxYear
    nextBtn.addEventListener("click", () => this._changeYear(1))

    yearNav.appendChild(prevBtn)
    yearNav.appendChild(yearLabel)
    yearNav.appendChild(nextBtn)

    // セル幅12px + gap2px = 14px が1列分の幅
    const CELL_STEP = 14
    const monthRow = document.createElement("div")
    monthRow.className = "cg-month-labels"
    monthRow.style.width = `${columns.length * CELL_STEP - 2}px`
    monthLabels.forEach(({ label, colIndex }) => {
      const span = document.createElement("span")
      span.textContent = label
      span.style.left = `${colIndex * CELL_STEP}px`
      monthRow.appendChild(span)
    })

    const grid = document.createElement("div")
    grid.className = "cg-grid"

    columns.forEach(week => {
      week.forEach(cell => {
        const div = document.createElement("div")
        if (cell === null) {
          div.className = "cg-cell cg-cell--empty"
        } else if (cell.future) {
          div.className = "cg-cell cg-cell--future"
        } else {
          const level = this._heatLevel(cell.count)
          div.className = `cg-cell cg-cell--level-${level}`
          div.dataset.date = cell.date
          div.dataset.count = cell.count
          div.addEventListener("mouseenter", this._showTooltip.bind(this))
          div.addEventListener("mouseleave", this._hideTooltip.bind(this))
        }
        grid.appendChild(div)
      })
    })

    right.appendChild(yearNav)
    right.appendChild(monthRow)
    right.appendChild(grid)
    wrapper.appendChild(dayLabels)
    wrapper.appendChild(right)
    this.containerTarget.appendChild(wrapper)
  }

  _computeGrid(data, year) {
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    // 今年の1月1日から開始
    const jan1 = new Date(year, 0, 1)
    const jan1dow = jan1.getDay()
    const daysToMonday = jan1dow === 0 ? 6 : jan1dow - 1
    const startDate = new Date(jan1)
    startDate.setDate(jan1.getDate() - daysToMonday)

    const dec31 = new Date(year, 11, 31)

    const columns = []
    const cur = new Date(startDate)

    while (cur <= dec31) {
      const weekAnchor = new Date(cur)
      const week = []

      for (let row = 0; row < 7; row++) {
        const d = new Date(weekAnchor)
        d.setDate(weekAnchor.getDate() + row)

        if (d.getFullYear() !== year) {
          week.push(null)
        } else if (d > today) {
          week.push({ future: true })
        } else {
          week.push({ date: this._toYMD(d), count: data[this._toYMD(d)] || 0 })
        }
      }

      columns.push(week)
      cur.setDate(cur.getDate() + 7)
    }

    // 月ラベル
    const monthLabels = []
    let lastMonth = -1
    columns.forEach((_week, colIndex) => {
      const weekStart = new Date(startDate)
      weekStart.setDate(startDate.getDate() + colIndex * 7)
      for (let row = 0; row < 7; row++) {
        const d = new Date(weekStart)
        d.setDate(weekStart.getDate() + row)
        if (d.getFullYear() !== year) continue
        const month = d.getMonth()
        if (month !== lastMonth) {
          monthLabels.push({ label: `${month + 1}月`, colIndex })
          lastMonth = month
        }
        break
      }
    })

    return { columns, monthLabels }
  }

  _heatLevel(count) {
    if (count === 0) return 0
    if (count === 1) return 1
    if (count === 2) return 2
    if (count === 3) return 3
    return 4
  }

  _toYMD(date) {
    const y = date.getFullYear()
    const m = String(date.getMonth() + 1).padStart(2, "0")
    const d = String(date.getDate()).padStart(2, "0")
    return `${y}-${m}-${d}`
  }

  _createTooltip() {
    const tip = document.createElement("div")
    tip.className = "cg-tooltip"
    tip.hidden = true
    document.body.appendChild(tip)
    return tip
  }

  _showTooltip(event) {
    const cell = event.currentTarget
    const count = parseInt(cell.dataset.count, 10)
    this._tooltip.textContent = count === 0
      ? `${cell.dataset.date}: 投稿なし`
      : `${cell.dataset.date}: ${count}件投稿`

    this._tooltip.hidden = false

    const rect = cell.getBoundingClientRect()
    this._tooltip.style.left = `${rect.left + rect.width / 2}px`
    this._tooltip.style.top  = `${rect.top - 36}px`
  }

  _hideTooltip() {
    this._tooltip.hidden = true
  }
}
