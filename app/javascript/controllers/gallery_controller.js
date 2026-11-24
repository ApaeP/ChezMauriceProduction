import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const link = document.getElementById(this.element.dataset.returnTo)
    if (link && !this.element.querySelector("dialog")) link.focus({ preventScroll: true })
  }

  remember(event) {
    this.element.dataset.returnTo = event.currentTarget.id
  }
}
