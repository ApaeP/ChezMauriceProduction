import { Controller } from '@hotwired/stimulus'
import { Sortable } from 'sortablejs'

export default class extends Controller {

  connect() {
    this.sortable = Sortable.create(this.element, {
      delayOnTouchOnly: 150,
      animation: 150,
      handle: ".reorder-handle",
      easing: "cubic-bezier(1, 0, 0, 1)",
      onEnd: this.onEnd.bind(this)
    })
  }

  onEnd(event) {
    let id = event.item.dataset.reorderId
    var data = new FormData()
    data.append('position', event.newIndex + 1)

    const url = this.data.get('url').replace(":id", id)
    const csrfToken = document.querySelector('[name="csrf-token"]').content
    const params = {
      method: 'PATCH',
      body: data,
      headers: {
        'X-CSRF-Token': csrfToken
      }
    }

    fetch(url, params)
  }
}
