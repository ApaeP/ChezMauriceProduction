const setMainContainerMinHeight = () => {
  if (document.querySelector('.main-container')) {
    document.querySelector('.main-container').style.minHeight = window.innerHeight - ( document.querySelector('.navbar-container').offsetHeight + document.querySelector('.footer-lrg').offsetHeight ) + 'px';
  } else if (document.querySelector('.info-container')) {
    document.querySelector('.info-container').style.minHeight = window.innerHeight - ( document.querySelector('.navbar-container').offsetHeight + document.querySelector('.footer-lrg').offsetHeight - 1 ) + 'px';
  }
};

export { setMainContainerMinHeight };
