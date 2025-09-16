import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="create-modal"
export default class extends Controller {
  static targets = ["modal", "button"]

  open(event) {
    event.preventDefault()
    event.stopPropagation()

    console.log('open')

    if (this.hasModalTarget) {
      this.modalTarget.classList.remove('modal-hidden')
      this.modalTarget.classList.add('modal-visible')

      this.addEventListeners()
    }
  }

  close(event) {
    event.preventDefault()

    if (this.hasModalTarget) {
      this.modalTarget.classList.remove('modal-visible')
      this.modalTarget.classList.add('modal-hidden')

      this.removeEventListeners()
    }
  }

  closeOnBackground(event) {
    if (event.target === this.modalTarget) {
      this.close(event)
    }
  }

  closeOnEscape(event) {
    if (event.key === 'Escape' && this.modalTarget.classList.contains('modal-visible')) {
      this.close(event)
    }
  }

  addEventListeners() {
    this.modalTarget.addEventListener('click', this.closeOnBackground.bind(this))
    document.addEventListener('keydown', this.closeOnEscape.bind(this))
  }

  removeEventListeners() {
    this.modalTarget.removeEventListener('click', this.closeOnBackground.bind(this))
    document.removeEventListener('keydown', this.closeOnEscape.bind(this))
  }
}
