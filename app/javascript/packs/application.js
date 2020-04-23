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
import { galleryActions } from '../components/toggle_gallery';
import { contactActions } from '../components/toggle_contact';
import { infoActions } from '../components/toggle_info';
import { mouseWheelActions } from '../components/mousewheel_actions';

// =============================================================================
//                              ON TURBOLINKS LOAD
// =============================================================================
document.addEventListener('turbolinks:load', () => {

  autoplayVideoBackground();

  galleryActions();

  contactActions();

  infoActions();

  // mouseWheelActions();

});
// =============================================================================
//                          END OF ON TURBOLINKS LOAD
// =============================================================================
