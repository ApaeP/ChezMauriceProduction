import { Controller } from "@hotwired/stimulus"
import Player from "@vimeo/player"

// Connects to data-controller="video-modal"
export default class extends Controller {
  static targets = ["background", "title", "description", "player"]
  static values = {
    videoId: String,
    videoTitle: String,
    videoDescription: String
  }

  connect() {
    this.vimeoPlayer = null
    this.isModalOpen = false
    this.currentPlayerToken = null

    this.handleEscapeKey = this.handleEscapeKey.bind(this)
    this.handleBackgroundClick = this.handleBackgroundClick.bind(this)
  }

  async disconnect() {
    this.currentPlayerToken = null
    await this.cleanup()
    document.removeEventListener('keydown', this.handleEscapeKey)
  }

  open(event) {
    event.preventDefault()

    const videoElement = event.currentTarget
    const videoId = videoElement.dataset.videoid
    const videoUrl = videoElement.dataset.videourl
    const videoTitle = videoElement.dataset.videotitle
    const videoDescription = videoElement.dataset.videodesc.replaceAll('\n', '<br>')

    if (document.querySelector('.edit-video-modal-background.modal-visible')) {
      return
    }

    this.updateModalContent(videoTitle, videoDescription)
    this.showModal()
    this.addEventListeners()
    const playerToken = Symbol('video-modal-player')
    this.currentPlayerToken = playerToken
    this.initializeVideoPlayer(videoUrl, videoId, playerToken)
  }

  async close(event) {
    if (event) {
      event.preventDefault()
    }

    this.hideModal()
    this.removeEventListeners()
    this.currentPlayerToken = null
    await this.cleanup()
  }

  updateModalContent(title, description) {
    if (this.hasTitleTarget) {
      this.titleTarget.innerHTML = title || ''
    }
    if (this.hasDescriptionTarget) {
      this.descriptionTarget.innerHTML = description || ''
    }
  }

  showModal() {
    if (this.hasBackgroundTarget) {
      this.backgroundTarget.classList.remove('modal-hidden')
      this.backgroundTarget.classList.add('modal-visible')
      this.isModalOpen = true
    }
  }

  hideModal() {
    if (this.hasBackgroundTarget) {
      this.backgroundTarget.classList.remove('modal-visible')
      this.backgroundTarget.classList.add('modal-hidden')
      this.isModalOpen = false
    }
  }

  async initializeVideoPlayer(videoUrl, videoId, token) {
    if (!videoUrl && !videoId) {
      console.error('No video identifier provided')
      return
    }

    try {
      await this.cleanup()

      if (this.hasPlayerTarget) {
        this.playerTarget.innerHTML = ''
      }

      const playerOptions = {
        autoplay: true,
        width: this.playerTarget.offsetWidth || 960,
        height: this.calculatePlayerHeight()
      }

      if (videoUrl) {
        playerOptions.url = videoUrl
      } else {
        playerOptions.id = videoId
      }

      if (!this.isModalOpen || this.currentPlayerToken !== token) {
        return
      }

      this.vimeoPlayer = new Player(this.playerTarget, playerOptions)

      await this.vimeoPlayer.ready()

      if (!this.isModalOpen || this.currentPlayerToken !== token) {
        return
      }

      await this.vimeoPlayer.play()
    } catch (error) {
      this.handleVimeoError(error)
    }
  }

  calculatePlayerHeight() {
    const containerWidth = this.playerTarget.offsetWidth || 960
    return Math.floor(containerWidth * 9 / 16)
  }

  async cleanup() {
    if (this.vimeoPlayer) {
      try {
        await this.vimeoPlayer.unload()
      } catch (error) {
        console.log('Error unloading player:', error)
      }

      try {
        await this.vimeoPlayer.destroy()
      } catch (error) {
        console.log('Error destroying player:', error)
      }

      this.vimeoPlayer = null
    }

    if (this.hasPlayerTarget) {
      this.playerTarget.innerHTML = ''
    }
  }

  handleVimeoError(error) {
    if (error?.name === 'PlayInterrupted') {
      return
    }

    console.error('Vimeo player error:', error)

    let errorMessage = 'Une erreur est survenue lors du chargement de la vidéo.'

    switch (error.name) {
      case 'TypeError':
        errorMessage = 'L\'ID de la vidéo n\'est pas valide.'
        break
      case 'PasswordError':
        errorMessage = 'Cette vidéo est protégée par un mot de passe.'
        break
      case 'PrivacyError':
        errorMessage = 'Cette vidéo est privée et ne peut pas être lue.'
        break
      case 'NotFoundError':
        errorMessage = 'Cette vidéo n\'a pas été trouvée.'
        break
      default:
        errorMessage = 'Nous rencontrons un problème technique. Veuillez réessayer.'
    }

    if (this.hasPlayerTarget) {
      this.playerTarget.innerHTML = `
        <div class="video-error-message">
          <h3>Désolé</h3>
          <p>${errorMessage}</p>
          <button type="button" data-action="click->video-modal#close" class="btn btn-secondary">
            Fermer
          </button>
        </div>
      `
    }
  }

  addEventListeners() {
    document.addEventListener('keydown', this.handleEscapeKey)
    if (this.hasBackgroundTarget) {
      this.backgroundTarget.addEventListener('click', this.handleBackgroundClick)
    }
  }

  removeEventListeners() {
    document.removeEventListener('keydown', this.handleEscapeKey)
    if (this.hasBackgroundTarget) {
      this.backgroundTarget.removeEventListener('click', this.handleBackgroundClick)
    }
  }

  handleEscapeKey(event) {
    if (event.key === 'Escape' && this.isModalOpen) {
      this.close()
    }
  }

  handleBackgroundClick(event) {
    this.close()
  }
}
