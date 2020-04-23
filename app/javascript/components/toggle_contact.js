const contactActions = () => {
  const contactButton = document.querySelector("#contact-link");
  const contactPage = document.querySelector('#contact-page');
  const closeContact = document.querySelector('#close-contact-arrow')

  // When contact link is clicked
  contactButton.addEventListener('click', (event) => {
    // Set "#contact-page" css paramater "top" to the right value (which is the height of the #contact-page div)
    // contactPage.style.top = `${contactPage.offsetHeight}px`;
    // We'd rather set the top to the height of the window
    contactPage.style.top = `${window.innerHeight}px`;
    // display the contact-page div
    if (contactPage.classList.contains('hidden')) {
      contactPage.classList.remove('hidden');
    }
    contactPage.classList.add('displayed');

    // pause on video background after transition is over
    setTimeout('document.querySelector("#home-video").pause()', 1000)
  });

  // When close gallery arrow is clicked
  closeContact.addEventListener('click', (event) => {
    // Play the background video
    document.querySelector("#home-video").play();
    // hide the contact-page div
    contactPage.classList.remove('displayed');
    contactPage.classList.add('hidden');
    // forbid scrolling on y axis
    document.querySelector("body").style.overflowY = 'hidden';
  });
};

export { contactActions };
