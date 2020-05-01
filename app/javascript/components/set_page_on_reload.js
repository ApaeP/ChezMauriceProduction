const setPageOnReload = () => {
  if (window.location.href.includes('production')) {
    galleryPage.style.top = `${window.innerHeight}px`;
    galleryPage.classList.add('reload-displayed');
  } else if (window.location.href.includes('information')) {
    infoPage.style.top = `${window.innerHeight}px`;
    infoPage.classList.add('reload-displayed');
  } else if (window.location.href.includes('contact')) {
    contactPage.style.top = `${window.innerHeight}px`;
    contactPage.classList.add('reload-displayed');
  } // else if (window.location.href.includes('accueil') || window.location.href == 'http://localhost:3000/') {
  //   console.log('Accueil');
  // }
};

export { setPageOnReload };
