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
import { knowWhatPageIsOn } from '../components/know_what_page';
import { autoplayVideoBackground } from '../components/background_video';
import { mouseWheelActions } from '../components/mousewheel_actions';
import { togglePage } from '../components/toggle_page';

// =============================================================================
//                              ON TURBOLINKS LOAD
// =============================================================================



document.addEventListener('turbolinks:load', () => {

  const infoButton = document.querySelectorAll(".info-link");
  const infoPage = document.querySelector('#info-page');
  const closeInfo = document.querySelectorAll('.close-info-link')

  const galleryButton = document.querySelectorAll(".gallery-link");
  const galleryPage = document.querySelector('#gallery-page');
  const closeGallery = document.querySelectorAll('.close-gallery-link')

  const contactButton = document.querySelectorAll(".contact-link");
  const contactPage = document.querySelector('#contact-page');
  const closeContact = document.querySelectorAll('.close-contact-link')

  knowWhatPageIsOn();

  autoplayVideoBackground();

  togglePage(contactButton, contactPage, closeContact);
  togglePage(galleryButton, galleryPage, closeGallery);
  togglePage(infoButton, infoPage, closeInfo);

  // galleryActions();

  // contactActions();

  // infoActions();

  // mouseWheelActions();

});
// =============================================================================
//                          END OF ON TURBOLINKS LOAD
// =============================================================================
