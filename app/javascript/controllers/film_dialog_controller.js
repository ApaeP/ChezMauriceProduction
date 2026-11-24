import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // A Turbo snapshot restores the open attribute, but not the browser's modal state.
    if (this.element.open) this.element.close()
    this.element.showModal()
  }

  back(event) {
    event.preventDefault()
    history.back()
  }

  backdrop(event) {
    if (event.target === this.element) this.back(event)
  }
}
