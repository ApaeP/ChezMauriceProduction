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
// Note(lewagon): ABOVE IS RAILS DEFAULT CONFIGURATION
// WRITE YOUR OWN JS STARTING FROM HERE 👇
// ----------------------------------------------------

// External imports
import "bootstrap";

// Internal imports, e.g:
// import { initSelect2 } from '../components/init_select2';

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
  } // if video end

});


const galleryButton = document.querySelector("#gallery-link");
const contactButton = document.querySelector("#contact-link");
const galleryPage = document.querySelector('#gallery-page');
const contactPage = document.querySelector('#contact-page');

galleryButton.addEventListener('click', (event) => {
  galleryPage.classList.add = 'displayed';
});

contactButton.addEventListener('click', (event) => {
});
