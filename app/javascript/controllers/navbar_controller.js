import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="navbar"
export default class extends Controller {
  static targets = ["background"]

  connect() {
    this.setActiveLink()
    this.setupScrollListener()
  }

  disconnect() {
    window.removeEventListener('scroll', this.handleScroll)
  }

  setupScrollListener() {
    this.handleScroll = this.handleScroll.bind(this)
    window.addEventListener('scroll', this.handleScroll)
  }

  handleScroll() {
    if (this.hasBackgroundTarget) {
      if (window.scrollY >= 25) {
        this.backgroundTarget.classList.add('navbar-background-fill')
      } else {
        this.backgroundTarget.classList.remove('navbar-background-fill')
      }
    }

    this.handleHomePageLinks()
  }

  setActiveLink() {
    const currentPath = window.location.pathname

    const currentLinks = document.querySelectorAll('.current-menu-link')
    currentLinks.forEach(link => {
      link.classList.remove('current-menu-link')
      link.classList.add('menu-link')
    })

    if (currentPath.includes('realisations')) {
      this.setLinkActive('#prod-link')
    } else if (currentPath.includes('contact')) {
      this.setLinkActive('#contact-link')
    } else if (currentPath === '/') {
      this.setLinkActive('#accueil-link')
    }
  }

  handleHomePageLinks() {
    const homeVideo = document.querySelector('#home-video')
    const navbar = document.querySelector('.navbar-container')
    const accueilLink = document.querySelector('#accueil-link')
    const infoLink = document.querySelector('#info-link')

    if (homeVideo && navbar && accueilLink && infoLink && window.location.pathname === '/') {
      const threshold = homeVideo.offsetHeight - navbar.offsetHeight - 1

      if (window.scrollY >= threshold) {
        accueilLink.classList.remove('current-menu-link')
        accueilLink.classList.add('menu-link')
        infoLink.classList.remove('menu-link')
        infoLink.classList.add('current-menu-link')
      } else {
        infoLink.classList.remove('current-menu-link')
        infoLink.classList.add('menu-link')
        accueilLink.classList.remove('menu-link')
        accueilLink.classList.add('current-menu-link')
      }
    }
  }

  setLinkActive(selector) {
    const link = document.querySelector(selector)
    if (link) {
      link.classList.remove('menu-link')
      link.classList.add('current-menu-link')
    }
  }
}
