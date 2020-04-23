const infoActions = () => {
  const infoButton = document.querySelector("#info-link");
  const infoPage = document.querySelector('#info-page');
  const closeinfo = document.querySelector('#close-info-arrow')
  // When info link is clicked SHOW
  infoButton.addEventListener('click', (event) => {
    // set "#info-page" css parameter "top" to the right value (which is the height of the #info-page div)
    infoPage.style.top = `${infoPage.offsetHeight}px`
    // display the info-page div
    if (infoPage.classList.contains('hidden')) {
      infoPage.classList.remove('hidden');
    }
    infoPage.classList.add('displayed');
    // allow scrolling on Y axis for the info-page
    document.querySelector("body").style.overflowY = 'scroll';
    // pause on video background after transition is over
    setTimeout('document.querySelector("#home-video").pause()', 1000)
  });

  // When close info arrow is clicked
  closeinfo.addEventListener('click', (event) => {
    // Play the background video
    document.querySelector("#home-video").play();
    // hide the info-page div
    infoPage.classList.remove('displayed');
    infoPage.classList.add('hidden');
    // forbid scrolling on y axis
    document.querySelector("body").style.overflowY = 'hidden';
  });
};

export { infoActions };
