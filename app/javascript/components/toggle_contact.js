const contactActions = () => {
  const contactButton = document.querySelector("#contact-link");
  const contactPage = document.querySelector('#contact-page');
  const closeContact = document.querySelector('#close-contact-arrow')

  // When contact link is clicked
  contactButton.addEventListener('click', (event) => {
    // Set "#contact-page" css paramater "top" to the right value (which is the height of the #contact-page div)
    contactPage.style.top = `${contactPage.offsetHeight}px`;
    // display the contact-page div
    if (contactPage.classList.contains('hidden')) {
      contactPage.classList.remove('hidden');
    }
    contactPage.classList.add('displayed');
    // allow scroll on Y axis for contact-page
    document.querySelector("body").style.overflowY = 'scroll';

      // document.querySelector('body').addEventListener('wheel', (event) => {
      //   let maxScroll = contactPage.offsetHeight - window.innerHeight
      //   // console.log(`Hauteur contact height = ${maxScroll}`);
      //   // console.log(`height of window = ${window.innerHeight}`)
      //   // console.log(`distance scrolled = ${window.pageYOffset}`);
      //   if (window.pageYOffset > maxScroll && event.deltaY > 1) {
      //     window.pageYOffset = maxScroll;
      //     document.querySelector("body").style.overflowY = 'hidden';
      //   }
      // });
      // // onScroll = function (e){
      // //    var maxScroll=1200
      // //    if(e.target.scrollLeft>maxScrollLeft){
      // //      e.target.scrollLeft=maxScrollLeft
      // //    }
      // // }


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
