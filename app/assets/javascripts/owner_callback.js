// Fragments stay in the browser. Clear the current history entry before sending
// the response in the body of a same-origin, CSRF-protected POST.
const response = new URLSearchParams(window.location.hash.slice(1))
const hasQuery = Boolean(window.location.search)
window.history.replaceState(null, "", window.location.pathname)

const states = response.getAll("state")
const codes = response.getAll("code")
const errors = response.getAll("error")
if (!hasQuery && states.length === 1 && states[0] && codes.length + errors.length === 1 && (codes[0] || errors[0])) {
  const form = document.getElementById("oauth-response")
  form.elements.namedItem("state").value = states[0]
  form.elements.namedItem("code").value = codes[0] || ""
  form.elements.namedItem("error").value = errors[0] || ""
  form.requestSubmit()
} else {
  document.getElementById("status").textContent = "Retour d’autorisation incomplet. Recommencez depuis la gestion de la connexion."
}
