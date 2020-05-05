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
import { autoplayVideoBackground } from '../components/background_video';
import { togglePage } from '../components/toggle_page';
import { openCloseVideoModal } from '../components/video_modal';
import { openCloseCreateVideoModal } from '../components/create_video_modal';
import { openCloseEditVideoModal } from '../components/edit_video_modal';
import { setPageOnReload } from '../components/set_page_on_reload';
import { initMap } from '../components/init_mapbox';
import { initSortable } from '../components/sortable'
import { mouseWheelActions } from '../components/mousewheel_actions';
import { authorizeForm, contentFieldHasContent } from '../components/form_validation'
import { focusContactForm } from '../components/focus_contact'
// import { resizeCardsHeight } from '../components/resize_cards_height';

// =============================================================================
//                              ON TURBOLINKS LOAD
// =============================================================================
const startTime = Date.now();
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

  togglePage(contactButton, contactPage, closeContact, "contact");
  togglePage(galleryButton, galleryPage, closeGallery, "production");
  togglePage(infoButton, infoPage, closeInfo, "information");

  if (document.querySelector('.contact-page-form')) {
    authorizeForm();
    focusContactForm();

    contentFieldHasContent();
  }


  autoplayVideoBackground();

  if (document.querySelector('#map')) {
    initMap();
  }

  if (document.querySelector('.video-modal-background')) {
    openCloseVideoModal();
  }

  if (document.querySelector('.create-video-modal-background')) {
    openCloseCreateVideoModal();
  }

  if (document.querySelector('.edit-video-modal-background')) {
    openCloseEditVideoModal();
  }

  if (document.querySelector('#welcome-video-container')) {
    setTimeout('document.querySelector("#welcome-video-container").classList.add("welcome-video-hide")', 5000);
  }

  if (document.querySelector('.homepage')) {
    mouseWheelActions();
  }

  setPageOnReload();

  document.querySelectorAll('.delete-video-btn').forEach((deleteBtn) => {
    deleteBtn.addEventListener('click', (event) => {
      document.querySelector('.video-modal-background').classList.toggle('modal-visible');
      document.querySelector('.video-modal-background').classList.toggle('modal-hidden');
    });
  });

  if (document.querySelector('#sortable-ul')) {
    initSortable();
  }

  window.onload = function(){
    const timeToLOad = Date.now() - startTime;
    console.log("Time to load website: " + timeToLOad + "ms");
    // document.querySelector('#loading-hider').classList.add('load-hide')
  }

  document.querySelectorAll('.return-from-legal').forEach((btn) => {
    btn.addEventListener('click', (e) => {
      if (window.close()) {

      } else {
        window.location.href = "http://stackoverflow.com";
      }
    });
  });

});
// =============================================================================
//                          END OF ON TURBOLINKS LOAD
// =============================================================================
