import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="layout"
export default class extends Controller {
  static targets = ["container", "navbar", "footer"]

  connect() {
    this.setContainerHeight()

    window.addEventListener('resize', this.setContainerHeight.bind(this))
  }

  disconnect() {
    window.removeEventListener('resize', this.setContainerHeight.bind(this))
  }

  setContainerHeight() {
    const mainContainer = document.querySelector('.main-container')
    const infoContainer = document.querySelector('.info-container')
    const loginContainer = document.querySelector('.log-in-container')
    const navbar = document.querySelector('.navbar-container')
    const footer = document.querySelector('.footer-lrg')

    if (!navbar || !footer) return

    const navbarHeight = navbar.offsetHeight
    const footerHeight = footer.offsetHeight
    const availableHeight = window.innerHeight - (navbarHeight + footerHeight)

    if (mainContainer) {
      if (loginContainer) {
        mainContainer.style.height = availableHeight + 'px'
      } else {
        mainContainer.style.minHeight = availableHeight + 'px'
      }
    } else if (infoContainer) {
      infoContainer.style.minHeight = (availableHeight) + 'px'
    }
  }
}
