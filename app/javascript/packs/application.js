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

// External imports
import "bootstrap";
import Isotope from 'isotope-layout';

// Internal imports, e.g:
import { autoplayVideoBackground }                from '../components/background_video';
import { openCloseCreateVideoModal }              from '../components/create_video_modal';
// import { deleteVideoButton }                      from '../components/delete_video_btn';
import { openCloseEditVideoModal }                from '../components/edit_video_modal_V1';
import { filterIndex }                            from '../components/filter_index';
// import { focusContactForm }                       from '../components/focus_contact';
// import { authorizeForm, contentFieldHasContent }  from '../components/form_validation';
import { scrollToInfoDiv }                        from '../components/information_scroll';
import { initMap, initMap2 }                      from '../components/init_mapbox';
// import { setLoader, displayHideLoaderNotice }     from '../components/loader_notice';
import { changeNavbarBackgroundOnScroll }         from '../components/navbar_bckgrnd_scroll';
import { returnFromLegalNotice }                  from '../components/return_from_legal_notice';
import { setMainContainerMinHeight }              from '../components/set_main_container_minheight';
import { initSortable }                           from '../components/sortable';
import { underlineNavbarLinks }                   from '../components/underline_navbar_links';
import { openCloseVideoModal }                    from '../components/video_modal_V1';

document.addEventListener('turbolinks:load', () => {

  autoplayVideoBackground();
  openCloseCreateVideoModal();
  // deleteVideoButton();
  openCloseEditVideoModal();
  filterIndex();
  scrollToInfoDiv();
  initMap();
  initMap2();
  changeNavbarBackgroundOnScroll();
  returnFromLegalNotice();
  setMainContainerMinHeight();
  initSortable();
  underlineNavbarLinks();
  openCloseVideoModal();

});
