const knowWhatPageIsOn = () => {
  const galleryPage = document.querySelector('#gallery-page');
  const infoPage = document.querySelector('#info-page');
  const contactPage = document.querySelector('#contact-page');

  let page = 'home';

  // si les trois pages sont non displayed
  document.addEventListener('change', (event) => {
    if ( isHidden(contactPage) && isHidden(infoPage) && isHidden(contactPage) ) {
      page = 'home';
    } // else if () {
    //   page = 'gallery';
    // } else if () {
    //   page = 'contact'
    // } else if () {
    //   page = 'info'
    // }
    console.log(page);
  })
};

const isHidden = (page) => {
  return page.classList.contains('hidden') || page.classList.value === "";
};

export { knowWhatPageIsOn };
