import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="contact-form"
export default class extends Controller {
  static targets = ["input", "submit", "email"]

  connect() {
    console.log("Contact form controller connected")
    this.emailRegex = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
    this.updateSubmitButton()
  }

  validateInput(event) {
    const input = event.target
    this.updateInputStyling(input)
    this.updateSubmitButton()
  }

  validateEmail(event) {
    const emailInput = event.target
    this.updateEmailStyling(emailInput)
    this.updateSubmitButton()
  }

  updateInputStyling(input) {
    if (this.isFilled(input)) {
      input.classList.remove('red')
      input.classList.add('green')
    } else {
      input.classList.remove('green')
      input.classList.add('red')
    }
  }

  updateEmailStyling(emailInput) {
    if (this.isFilled(emailInput) && this.isValidEmail(emailInput.value)) {
      emailInput.classList.remove('red')
      emailInput.classList.add('green')
    } else {
      emailInput.classList.remove('green')
      emailInput.classList.add('red')
    }
  }

  updateSubmitButton() {
    if (this.hasSubmitTarget) {
      if (this.allFieldsValid()) {
        this.submitTarget.disabled = false
        this.submitTarget.classList.remove('disabled')
        this.submitTarget.classList.add('enabled')
      } else {
        this.submitTarget.disabled = true
        this.submitTarget.classList.remove('enabled')
        this.submitTarget.classList.add('disabled')
      }
    }
  }

  isFilled(input) {
    return input.value.trim().length > 0
  }

  isValidEmail(email) {
    return this.emailRegex.test(email)
  }

  allFieldsValid() {
    const allInputsFilled = this.inputTargets.every(input => this.isFilled(input))

    let emailValid = true
    if (this.hasEmailTarget) {
      emailValid = this.isFilled(this.emailTarget) && this.isValidEmail(this.emailTarget.value)
    }

    return allInputsFilled && emailValid
  }
}
