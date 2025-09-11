import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="video-background"
export default class extends Controller {
  connect() {
    this.setupFadeIn()
    this.playVideo()
  }

  playVideo() {
    if (this.element) {
      this.element.play().catch(error => {
        console.error("Autoplay was prevented:", error)
        this.element.style.opacity = "0"
      })
    }
  }

  setupFadeIn() {
    this.element.addEventListener('play', () => {
      setTimeout(() => {
        this.element.style.opacity = "1"
      }, 100)
      this.element.classList.add('fade-in-on-play')
    })
  }
}
