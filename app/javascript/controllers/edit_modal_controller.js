import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="edit-modal"
export default class extends Controller {
  static targets = ["modal", "closeButton"]

  open(event) {
    const videoId = event.currentTarget.dataset.videoid
    const modal = document.querySelector(`#edit-video-id-${videoId}`)

    if (modal) {
      modal.classList.remove('modal-hidden')
      modal.classList.add('modal-visible')

      this.addModalEventListeners(modal)
    }
  }

  close(event) {
    const modal = event.target.closest('.edit-video-modal-background')
    if (modal) {
      modal.classList.remove('modal-visible')
      modal.classList.add('modal-hidden')

      this.removeModalEventListeners(modal)
    }
  }

  closeOnBackground(event) {
    if (event.target.classList.contains('edit-video-modal-background')) {
      this.close(event)
    }
  }

  closeOnEscape(event) {
    if (event.key === 'Escape') {
      const visibleModal = document.querySelector('.edit-video-modal-background.modal-visible')
      if (visibleModal) {
        visibleModal.classList.remove('modal-visible')
        visibleModal.classList.add('modal-hidden')
      }
    }
  }

  addModalEventListeners(modal) {
    modal.addEventListener('click', this.closeOnBackground.bind(this))
    document.addEventListener('keydown', this.closeOnEscape.bind(this))
  }

  removeModalEventListeners(modal) {
    modal.removeEventListener('click', this.closeOnBackground.bind(this))
    document.removeEventListener('keydown', this.closeOnEscape.bind(this))
  }
}
