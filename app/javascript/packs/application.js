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
import { initMap } from '../components/init_mapbox';
import { initSortable } from '../components/sortable';
import { authorizeForm, contentFieldHasContent } from '../components/form_validation';
import { focusContactForm } from '../components/focus_contact';
import { filterIndex } from '../components/filter_index';
// import { togglePage } from '../components/toggle_page';
// import { setPageOnReload } from '../components/set_page_on_reload';
// import { mouseWheelActions } from '../components/mousewheel_actions';
// import { resizeCardsHeight } from '../components/resize_cards_height';

// =============================================================================
//                              ON TURBOLINKS LOAD
// =============================================================================
const startTime = Date.now();
document.addEventListener('turbolinks:load', () => {

    if (document.querySelector('#home-div')) {
      $("#info-link").click(function() {
        $('html,body').animate({
          scrollTop: window.innerHeight - document.querySelector('.navbar-height').offsetHeight},
          1200
        );
      });
      $("#accueil-link").click(function() {
        $('html,body').animate({
          scrollTop: $("#home-div").offset().top},
          1200
        );
      });
    }

  // const searchLabels = document.querySelectorAll('.search-labels');
  // const searchRadioBtns = document.querySelectorAll('.search-radio-btns');

  // madeUpBtns.forEach((label) => {
  //   label.addEventListener('click', (event) => {
  //   // $(document).on('click', label, function(e){
  //     let id = label.dataset.cat;
  //     document.querySelector(`#${id}-radio-btn`).click();
  //     document.querySelector('#search-button').click();
  //   });
  // });
  if (document.querySelectorAll('.video-card')) {
    filterIndex();
  }

  if (document.querySelector('.main-container')) {
    document.querySelector('.main-container').style.minHeight = `${window.innerHeight - (document.querySelector('.footer').offsetHeight + document.querySelector('.navbar-height').offsetHeight)}px`;
    // document.querySelector('.main-container').style.marginTop = `${document.querySelector('.navbar-height').offsetHeight}px`

    window.addEventListener('resize', (event) => {
      document.querySelector('.main-container').style.minHeight = `${window.innerHeight - (document.querySelector('.footer').offsetHeight + document.querySelector('.navbar-height').offsetHeight)}px`;
      // document.querySelector('.main-container').style.marginTop = `${document.querySelector('.navbar-height').offsetHeight}px`
    });
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

  if (document.querySelector('#sortable-ul')) {
    initSortable();
  }

  document.querySelectorAll('.delete-video-btn').forEach((deleteBtn) => {
    deleteBtn.addEventListener('click', (event) => {
      document.querySelector('.video-modal-background').classList.toggle('modal-visible');
      document.querySelector('.video-modal-background').classList.toggle('modal-hidden');
    });
  });


  window.onload = function(){
    const timeToLOad = Date.now() - startTime;
    console.log("Time to load website: " + timeToLOad + "ms");
    // document.querySelector('#loading-hider').classList.add('load-hide')
  }

  document.querySelectorAll('.return-from-legal').forEach((btn) => {
    btn.addEventListener('click', (e) => {
      if (window.close()) {

      } else {
        window.location.href = "http://www.chezmauriceproduction.com/";
      }
    });
  });


  if (window.location.href.includes('realisations')) {
    if (document.querySelector('.current-menu-link')) {
      document.querySelector('.current-menu-link').classList.remove('.current-menu-link');
      document.querySelector('#prod-link').classList.remove('menu-link');
      document.querySelector('#prod-link').classList.add('current-menu-link');
    } else {
      document.querySelector('#prod-link').classList.remove('menu-link');
      document.querySelector('#prod-link').classList.add('current-menu-link');
    }
  } else if (window.location.href.includes('a-propos')) {
    if (document.querySelector('.current-menu-link')) {
      document.querySelector('.current-menu-link').classList.remove('.current-menu-link');
      document.querySelector('#info-link').classList.remove('menu-link');
      document.querySelector('#info-link').classList.add('current-menu-link');
    } else {
      document.querySelector('#info-link').classList.remove('menu-link');
      document.querySelector('#info-link').classList.add('current-menu-link');
    }
  } else if (window.location.href.includes('contacter')) {
    if (document.querySelector('.current-menu-link')) {
      document.querySelector('.current-menu-link').classList.remove('.current-menu-link');
      document.querySelector('#contact-link').classList.remove('menu-link');
      document.querySelector('#contact-link').classList.add('current-menu-link');
    } else {
      document.querySelector('#contact-link').classList.remove('menu-link');
      document.querySelector('#contact-link').classList.add('current-menu-link');
    }
  } else if (window.location.href.includes('accueil') || window.location.href == "http://www.chezmauriceproduction.com/" || window.location.href == "http://chezmauriceproduction.com/" || window.location.href == "http://localhost:3000/") {
    if (document.querySelector('.current-menu-link')) {
      document.querySelector('.current-menu-link').classList.remove('.current-menu-link');
      document.querySelector('#accueil-link').classList.remove('menu-link');
      document.querySelector('#accueil-link').classList.add('current-menu-link');
    } else {
      document.querySelector('#accueil-link').classList.remove('menu-link');
      document.querySelector('#accueil-link').classList.add('current-menu-link');
    }
  }

  // if (document.querySelector('.contact-container')) {
  //   window.onload = function(){
  //     setTimeout(authorizeForm, 300)
  //     setTimeout(focusContactForm, 300)
  //     setTimeout(contentFieldHasContent, 300)
  //     // authorizeForm();
  //     // focusContactForm();
  //     // contentFieldHasContent();
  //   }
  // }

});
// =============================================================================
//                          END OF ON TURBOLINKS LOAD
// =============================================================================
