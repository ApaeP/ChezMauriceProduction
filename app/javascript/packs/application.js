const startTime = Date.now();
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
import { openCloseVideoModal } from '../components/video_modal_V1';
import { openCloseCreateVideoModal } from '../components/create_video_modal';
import { openCloseEditVideoModal } from '../components/edit_video_modal_V1';
import { initMap, initMap2 } from '../components/init_mapbox';
import { initSortable } from '../components/sortable';
import { authorizeForm, contentFieldHasContent } from '../components/form_validation';
import { focusContactForm } from '../components/focus_contact';
import { filterIndex } from '../components/filter_index';
import { changeNavbarBackgroundOnScroll } from '../components/navbar_bckgrnd_scroll';
import { scrollToInfoDiv } from '../components/information_scroll';
import { setMainContainerMinHeight } from '../components/set_main_container_minheight';
import { deleteVideoButton } from '../components/delete_video_btn';
import { returnFromLegalNotice } from '../components/return_from_legal_notice';
import { underlineNavbarLinks } from '../components/underline_navbar_links';

// =============================================================================
//                              ON TURBOLINKS LOAD
// =============================================================================

document.addEventListener('turbolinks:load', () => {

  setMainContainerMinHeight();
  changeNavbarBackgroundOnScroll();
  scrollToInfoDiv();
  filterIndex();
  autoplayVideoBackground();
  initMap();
  initMap2();
  openCloseVideoModal();
  openCloseCreateVideoModal();
  openCloseEditVideoModal();
  initSortable();
  deleteVideoButton();
  returnFromLegalNotice();
  underlineNavbarLinks();

  window.onload = function(){
    const timeToLOad = Date.now() - startTime;
    console.log("Time to load DOM & JS: " + timeToLOad + "ms");
    // document.querySelector('#loading-hider').classList.add('load-hide')
  }
});
// =============================================================================
//                          END OF ON TURBOLINKS LOAD
// =============================================================================
