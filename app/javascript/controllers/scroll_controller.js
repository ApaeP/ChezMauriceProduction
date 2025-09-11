import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="scroll"
export default class extends Controller {
  static targets = ["infoSection", "homeSection"]

  connect() {
    this.checkHashOnLoad()
  }

  scrollTo(event) {
    event.preventDefault()

    const targetId = event.currentTarget.dataset.scrollTarget
    const targetElement = document.querySelector(targetId)

    if (targetElement) {
      this.smoothScrollTo(targetElement)
    }
  }

  scrollToInfo(event) {
    console.log('scrollToInfo')
    event.preventDefault()

    const menuToggle = document.querySelector('#menuToggle input')
    if (menuToggle && menuToggle.checked) {
      menuToggle.click()
    }

    const infoSection = this.hasInfoSectionTarget ? this.infoSectionTarget : document.querySelector('#info-content')
    if (infoSection) {
      const navbar = document.querySelector('.navbar-height')
      const navbarHeight = navbar ? navbar.offsetHeight : 0
      const targetPosition = infoSection.offsetTop - navbarHeight + 3

      this.smoothScrollToPosition(targetPosition)
    }
  }

  scrollToHome(event) {
    console.log('scrollToHome')
    event.preventDefault()

    const homeSection = this.hasHomeSectionTarget ? this.homeSectionTarget : document.querySelector('#home-div')
    if (homeSection) {
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      })
    }
  }

  checkHashOnLoad() {
    if (window.location.hash === '#informations') {
      setTimeout(() => {
        const infoSection = document.querySelector('#info-content')
        if (infoSection) {
          const navbar = document.querySelector('.navbar-height')
          const navbarHeight = navbar ? navbar.offsetHeight : 0
          const targetPosition = infoSection.offsetTop - navbarHeight + 3

          this.smoothScrollToPosition(targetPosition)
        }
      }, 200)
    }
  }

  smoothScrollTo(element) {
    element.scrollIntoView({
      behavior: 'smooth',
      block: 'start'
    })
  }

  smoothScrollToPosition(position) {
    window.scrollTo({
      top: position,
      behavior: 'smooth'
    })
  }
}
