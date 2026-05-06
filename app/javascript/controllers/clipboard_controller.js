import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]
  static values  = { successLabel: { type: String, default: "Copied!" } }

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.innerText)
    const btn = this.buttonTarget
    const original = btn.textContent
    btn.textContent = this.successLabelValue
    setTimeout(() => { btn.textContent = original }, 2000)
  }
}
