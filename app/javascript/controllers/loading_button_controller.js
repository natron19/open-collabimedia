import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "loading", "modal", "instructions", "hidden"]

  open(event) {
    event.preventDefault()
    this.instructionsTarget.value = ""
    bootstrap.Modal.getOrCreateInstance(this.modalTarget).show()
  }

  generate() {
    this.hiddenTarget.value = this.instructionsTarget.value.trim()
    bootstrap.Modal.getInstance(this.modalTarget).hide()
    this.formTarget.hidden = true
    this.loadingTarget.hidden = false
    this.formTarget.querySelector("form").requestSubmit()
  }
}
