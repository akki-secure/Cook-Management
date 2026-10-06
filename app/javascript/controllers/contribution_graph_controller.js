import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { data: Object }
  static targets = ["container"]

  connect() {
    this._tooltip = this._createTooltip()
    this._buildGraph()
  }

  disconnect() {
    this._tooltip?.remove()
  }

  _buildGraph() {
    const { columns, monthLabels } = this._computeGrid(this.dataValue)

    const wrapper = document.createElement("div")
    wrapper.className = "cg-wrapper"

    const dayLabels = document.createElement("div")
    dayLabels.className = "cg-day-labels"
    ;["月", "火", "水", "木", "金", "土", "日"].forEach(label => {
      const span = document.createElement("span")
      span.textContent = label
      dayLabels.appendChild(span)
    })

    const right = document.createElement("div")
    right.className = "cg-right"

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

    right.appendChild(monthRow)
    right.appendChild(grid)
    wrapper.appendChild(dayLabels)
    wrapper.appendChild(right)
    this.containerTarget.appendChild(wrapper)
  }

  _computeGrid(data) {
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    // 今週の月曜日を求める（日=0なので6日戻す、それ以外はdow-1日戻す）
    const dow = today.getDay()
    const daysToMonday = dow === 0 ? 6 : dow - 1
    const currentWeekMonday = new Date(today)
    currentWeekMonday.setDate(today.getDate() - daysToMonday)

    // 52週前の月曜日をグラフの開始日にする
    const startDate = new Date(currentWeekMonday)
    startDate.setDate(currentWeekMonday.getDate() - 52 * 7)

    const columns = []
    const cur = new Date(startDate)

    while (cur <= today) {
      const weekAnchor = new Date(cur)
      const week = []

      for (let row = 0; row < 7; row++) {
        const d = new Date(weekAnchor)
        d.setDate(weekAnchor.getDate() + row)

        if (d > today) {
          week.push(null) // まだ来ていない日は空セル
        } else {
          week.push({ date: this._toYMD(d), count: data[this._toYMD(d)] || 0 })
        }
      }

      columns.push(week)
      cur.setDate(cur.getDate() + 7)
    }

    // 月が変わる列に月名ラベルを付ける
    const monthLabels = []
    let lastMonth = -1
    columns.forEach((week, colIndex) => {
      const firstCell = week.find(c => c !== null)
      if (!firstCell) return
      const month = new Date(firstCell.date).getMonth()
      if (month !== lastMonth) {
        monthLabels.push({ label: `${month + 1}月`, colIndex })
        lastMonth = month
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
