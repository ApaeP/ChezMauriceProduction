const underlineNavbarLinks = () => {
  if (window.location.href.includes('realisations')) {
    if (document.querySelector('.current-menu-link')) {
      document.querySelector('.current-menu-link').classList.remove('.current-menu-link');
      document.querySelector('#prod-link').classList.remove('menu-link');
      document.querySelector('#prod-link').classList.add('current-menu-link');
    } else {
      document.querySelector('#prod-link').classList.remove('menu-link');
      document.querySelector('#prod-link').classList.add('current-menu-link');
    }
  } else if (window.location.href.includes('a-propos')) {
    if (document.querySelector('.current-menu-link')) {
      document.querySelector('.current-menu-link').classList.remove('.current-menu-link');
      document.querySelector('#info-link').classList.remove('menu-link');
      document.querySelector('#info-link').classList.add('current-menu-link');
    } else {
      document.querySelector('#info-link').classList.remove('menu-link');
      document.querySelector('#info-link').classList.add('current-menu-link');
    }
  } else if (window.location.href.includes('contacter')) {
    if (document.querySelector('.current-menu-link')) {
      document.querySelector('.current-menu-link').classList.remove('.current-menu-link');
      document.querySelector('#contact-link').classList.remove('menu-link');
      document.querySelector('#contact-link').classList.add('current-menu-link');
    } else {
      document.querySelector('#contact-link').classList.remove('menu-link');
      document.querySelector('#contact-link').classList.add('current-menu-link');
    }
  } else if (window.location.href.includes('accueil') || window.location.href == "http://www.chezmauriceproduction.com/" || window.location.href == "http://chezmauriceproduction.com/" || window.location.href == "http://localhost:3000/") {
    if (document.querySelector('.current-menu-link')) {
      document.querySelector('.current-menu-link').classList.remove('.current-menu-link');
      document.querySelector('#accueil-link').classList.remove('menu-link');
      document.querySelector('#accueil-link').classList.add('current-menu-link');
    } else {
      document.querySelector('#accueil-link').classList.remove('menu-link');
      document.querySelector('#accueil-link').classList.add('current-menu-link');
    }
  }
};


export { underlineNavbarLinks };
