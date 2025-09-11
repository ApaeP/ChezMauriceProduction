import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="map"
export default class extends Controller {
  static values = {
    apiKey: String,
    lat: { value: Number, default: 48.869434 },
    lng: { value: Number, default: 2.182081 },
    zoom: { value: Number, default: 10 },
    style: { value: String, default: 'mapbox://styles/mapbox/light-v10' }
  }

  connect() {
    this.waitForMapbox()
  }

  waitForMapbox() {
    if (typeof mapboxgl !== 'undefined') {
      this.initializeMap()
    } else {
      setTimeout(() => this.waitForMapbox(), 100)
    }
  }

  initializeMap() {
    try {
      if (!this.apiKeyValue) {
        console.error("Mapbox API key is required. Please set it via data-map-api-key-value")
        return
      }

      mapboxgl.accessToken = this.apiKeyValue

      const map = new mapboxgl.Map({
        container: this.element,
        style: this.styleValue,
        center: [this.lngValue, this.latValue],
        zoom: this.zoomValue
      })

      const marker = new mapboxgl.Marker()
        .setLngLat([this.lngValue, this.latValue])
        .addTo(map)

      map.addControl(new mapboxgl.NavigationControl())
    } catch (error) {
      console.error("Error initializing map:", error)
    }
  }
}
