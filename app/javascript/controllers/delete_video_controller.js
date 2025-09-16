import { Controller } from "@hotwired/stimulus"
import Swal from "sweetalert2"

// Connects to data-controller="delete-video"
export default class extends Controller {
  static values = {
    url: String
  }

  connect() {
    this.videoCard = this.element.closest('.video-card')
    this.authToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
  }

  delete(event) {
    event.preventDefault()
    event.stopPropagation()

    Swal.fire({
      title: 'Voulez-vous vraiment supprimer cette vidéo ?',
      text: 'Vous ne pourrez pas revenir en arrière.',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#3085d6',
      cancelButtonColor: '#d33',
      confirmButtonText: 'Supprimer',
      cancelButtonText: 'Annuler',
    }).then((result) => {
      if (result.isConfirmed) {
        this.deleteVideo()
      }
    })
  }

  deleteVideo() {
    fetch(this.urlValue, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': this.authToken
      },
    }).then((response) => {
      if (response.ok) {
        this.videoCard.style.transition = 'opacity 0.3s ease-in-out'
        this.videoCard.style.opacity = 0
        setTimeout(() => {
          this.videoCard.remove()
        }, 300)
      } else {
        Swal.fire({
          title: 'Erreur',
          text: 'La vidéo n\'a pas été supprimée.',
          icon: 'error',
        })
      }
    }).catch((error) => {
      Swal.fire({
        title: 'Erreur',
        text: 'La vidéo n\'a pas été supprimée.',
        icon: 'error',
      })
      console.error('Error deleting video:', error)
    })
  }
}
