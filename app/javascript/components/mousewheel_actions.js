const mouseWheelActions = () => {

  const contactPage = document.querySelector('#contact-page');
  const galleryPage = document.querySelector('#gallery-page');
  const infoPage = document.querySelector('#info-page');

  const contactOpen = document.querySelector('#contact-link')
  const galleryOpen = document.querySelector('#gallery-link')
  const infoOpen = document.querySelector('#info-link')

  const closeContact = document.querySelector('#close-contact-arrow');
  const closeGallery = document.querySelector('#close-gallery-arrow');
  const closeInfo = document.querySelector('#close-info-arrow');

  window.addEventListener('wheel', (event) => {
    if (event.deltaX < -50) {
    // If we scroll left

      contactOpen.click();


    } else if (event.deltaX > 50) {
    // If we scroll right


      galleryOpen.click();


    } else if (event.deltaY > 50) {
    // If we scroll down

      infoOpen.click();


    } else if (event.deltaY < -50) {
    // If we scroll up

    }

  });
};

export { mouseWheelActions };
