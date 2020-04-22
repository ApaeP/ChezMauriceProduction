const galleryActions = () => {
  const galleryButton = document.querySelector("#gallery-link");
  const galleryPage = document.querySelector('#gallery-page');
  const closeGallery = document.querySelector('#close-gallery-arrow')
  // When gallery link is clicked SHOW
  galleryButton.addEventListener('click', (event) => {
    // set "#gallery-page" css parameter "top" to the right value (which is the height of the #gallery-page div)
    galleryPage.style.top = `${galleryPage.offsetHeight}px`
    // display the gallery-page div
    if (galleryPage.classList.contains('hidden')) {
      galleryPage.classList.remove('hidden');
    }
    galleryPage.classList.add('displayed');
    // allow scrolling on Y axis for the gallery-page
    document.querySelector("body").style.overflowY = 'scroll';
    // pause on video background after transition is over
    setTimeout('document.querySelector("#home-video").pause()', 1000)
  });

  // When close gallery arrow is clicked
  closeGallery.addEventListener('click', (event) => {
    // Play the background video
    document.querySelector("#home-video").play();
    // hide the gallery-page div
    galleryPage.classList.remove('displayed');
    galleryPage.classList.add('hidden');
    // forbid scrolling on y axis
    document.querySelector("body").style.overflowY = 'hidden';
  });
};

export { galleryActions };
