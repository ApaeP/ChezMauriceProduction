// const initUpdateNavbarOnScroll = () => {
//   const navbar = document.querySelector('.navbar-lewagon');
//   const banner = document.querySelector('.home-banner');
//   if (navbar) {
//     window.addEventListener('scroll', () => {
//       if (window.scrollY >= banner.offsetHeight - navbar.offsetHeight) {
//         navbar.classList.add('navbar-lewagon-white');
//       } else {
//         navbar.classList.remove('navbar-lewagon-white');
//       }
//     });
//   };
// };

const changeNavbarBackgroundOnScroll  = () => {
  if (document.querySelector('#banner-bckgrnd-white')) {

    const navbarBackground = document.querySelector('#banner-bckgrnd-white');

    window.addEventListener('scroll', () => {
      if (window.scrollY >= 25) {
        navbarBackground.classList.add('navbar-background-fill');
      } else {
        navbarBackground.classList.remove('navbar-background-fill');
      }
    });

  }
};

export { changeNavbarBackgroundOnScroll };
