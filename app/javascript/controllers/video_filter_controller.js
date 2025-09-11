import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="video-filter"
export default class extends Controller {
  static targets = ["button", "video"]

  connect() {
    this.setActiveButton(this.buttonTargets.find(btn => btn.dataset.cat === 'all'))
  }

  filter(event) {
    const clickedButton = event.currentTarget
    const category = clickedButton.dataset.cat

    this.setActiveButton(clickedButton)

    this.videoTargets.forEach(video => {
      const videoCategories = video.dataset.cats
      if (category === 'all' || videoCategories.includes(category)) {
        video.style.display = 'block'
        video.classList.remove('hidden')
      } else {
        video.style.display = 'none'
        video.classList.add('hidden')
      }
    })
  }

  setActiveButton(activeButton) {
    this.buttonTargets.forEach(btn => {
      btn.classList.remove('active')
      btn.classList.remove('srch-active')
    })

    if (activeButton) {
      activeButton.classList.add('active')
      activeButton.classList.add('srch-active')
    }
  }
}
