const togglePage = (openLinks, page, closeLinks) => {

  openLinks.forEach((openLink) => {

    // When link to page is clicked
    openLink.addEventListener('click', (event) => {
      // Set the page parameter "top" to the hight of the window
      page.style.top = `${window.innerHeight}px`;

      // Hide a page if one is displayed
      if (document.querySelector('.displayed')) {
        let displayedPage = document.querySelector('.displayed')
        displayedPage.classList.add('hidden');
        displayedPage.classList.remove('displayed');
      }

      // Display the page
      if (page.classList.contains('hidden')) {
        page.classList.remove('hidden');
      }
      page.classList.add('displayed');

      // Pause the video after display animation
      setTimeout('document.querySelector("#home-video").pause()', 1000)

    });
  });

  closeLinks.forEach((link) => {
    link.addEventListener('click', (event) => {
      // Play the background video
      document.querySelector("#home-video").play();
      // hide the page
      page.classList.remove('displayed');
      page.classList.add('hidden');
    });
  });

};

export { togglePage };
