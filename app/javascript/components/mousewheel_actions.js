const mouseWheelActions = () => {

  const contactOpen = document.querySelector('#contact-link');
  const galleryOpen = document.querySelector('#gallery-link');
  const infoOpen = document.querySelector('.info-link');
  const accueilBtn = document.querySelector('.close-info-link');

  window.addEventListener('wheel', (event) => {
    if (event.deltaX < -50) {
    // If we scroll left


    } else if (event.deltaX > 50) {
    // If we scroll right


    } else if (event.deltaY > 50) {
    // If we scroll down
      if (window.location.href.includes('accueil') || !window.location.href.includes("?")) {
        infoOpen.click();
        // window.location.href
      }

    } else if (event.deltaY < -50) {
    // If we scroll up
      if (window.location.href.includes('information')) {
        accueilBtn.click();
      }
    }

  });
};

export { mouseWheelActions };

