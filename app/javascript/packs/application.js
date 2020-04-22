// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()
require("channels")

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)


// ----------------------------------------------------
// ABOVE IS RAILS DEFAULT CONFIGURATION
// ----------------------------------------------------

// External imports
import "bootstrap";

// Internal imports, e.g:
// import { initSelect2 } from '../components/init_select2';

// =============================================================================
//                              ON TURBOLINKS LOAD
// =============================================================================
document.addEventListener('turbolinks:load', () => {


  // Autoplay home video
  if (document.querySelector('#home-video')) {
    const video = document.querySelector('#home-video');
    // Jouer la video 2s apres chargement de la page
    setTimeout('document.querySelector("#home-video").play()', 100);
    // Onplay fade video in 2s
    video.addEventListener('play', (event) => {
      setTimeout('document.querySelector("#home-video").style.opacity = "1"', 99)
      video.classList.add('fade-in-on-play');
    });
  } // if video exists *end*

});
// =============================================================================
//                          END OF ON TURBOLINKS LOAD
// =============================================================================

const galleryButton = document.querySelector("#gallery-link");
const contactButton = document.querySelector("#contact-link");
const galleryPage = document.querySelector('#gallery-page');
const contactPage = document.querySelector('#contact-page');
const closeGallery = document.querySelector('#close-gallery-arrow')

// When gallery link is clicked
galleryButton.addEventListener('click', (event) => {
  // set "#gallery-page" css parameter "top" to the right value (which is the height of the #gallery-page div)
  galleryPage.style.top = `${galleryPage.offsetHeight}px`
  // display the gallery-page div
  galleryPage.classList.add('displayed');
  // allow scrolling on Y axis for the gallery-page
  document.querySelector("body").style.overflowY = 'scroll';
  // pause on video background after transition is over
  setTimeout('document.querySelector("#home-video").pause()', 1000)
});

// When close gallery arrow is clicked
closeGallery.addEventListener('click', (event) => {
  // Play the background video
  document.querySelector("#home-video").play();
  // hide the gallery-page div
  galleryPage.classList.remove('displayed');
  // forbid scrolling on y axis
  document.querySelector("body").style.overflowY = 'hidden';
});

// When contact link is clicked
contactButton.addEventListener('click', (event) => {
});
