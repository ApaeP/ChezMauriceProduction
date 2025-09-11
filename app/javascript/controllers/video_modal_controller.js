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

    this.handleEscapeKey = this.handleEscapeKey.bind(this)
    this.handleBackgroundClick = this.handleBackgroundClick.bind(this)
  }

  disconnect() {
    this.cleanup()
    document.removeEventListener('keydown', this.handleEscapeKey)
  }

  open(event) {
    event.preventDefault()

    const videoElement = event.currentTarget
    const videoId = videoElement.dataset.videoid
    const videoUrl = videoElement.dataset.videourl
    const videoTitle = videoElement.dataset.videotitle
    const videoDescription = videoElement.dataset.videodesc

    if (document.querySelector('.edit-video-modal-background.modal-visible')) {
      return
    }

    this.updateModalContent(videoTitle, videoDescription)
    this.showModal()
    this.initializeVideoPlayer(videoId, videoUrl)
    this.addEventListeners()
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }

    this.pauseVideo()
    this.hideModal()
    this.removeEventListeners()
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

  initializeVideoPlayer(videoId, videoUrl) {
    if (!videoId) {
      console.error('No video ID provided')
      return
    }

    try {
      const existingIframe = document.querySelector('#vimeo-video-player > iframe')

      if (existingIframe) {
        this.cleanup()
        this.createNewPlayer(videoUrl)
      } else {
        this.createNewPlayer(videoUrl)
      }
    } catch (error) {
      console.error('Error initializing video player:', error)
    }
  }

  createNewPlayer(videoUrl) {
    const playerOptions = {
      id: videoUrl,
      height: document.querySelector('.video-modal-content').offsetHeight,
      autoplay: true
    }

    this.vimeoPlayer = new Player('vimeo-video-player', playerOptions)

    this.vimeoPlayer.ready().then(() => {
      return this.vimeoPlayer.play()
    }).catch(this.handleVimeoError.bind(this))

    // this.vimeoPlayer.on('ended', () => {
    // })
  }

  calculatePlayerHeight() {
    const containerWidth = this.playerTarget.offsetWidth || 800
    return Math.floor(containerWidth * 9 / 16)
  }

  pauseVideo() {
    if (this.vimeoPlayer) {
      try {
        this.vimeoPlayer.pause().catch(error => {
          console.log('Error pausing video:', error)
        })
      } catch (error) {
        console.log('Error accessing vimeo player:', error)
      }
    }
  }

  cleanup() {
    if (this.vimeoPlayer) {
      try {
        this.vimeoPlayer.destroy().then(() => {
        }).catch(error => {
          console.log('Error destroying player:', error)
        })
      } catch (error) {
        console.log('Error during cleanup:', error)
      }
      this.vimeoPlayer = null
    }
  }

  handleVimeoError(error) {
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
