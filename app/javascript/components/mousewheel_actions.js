const mouseWheelActions = () => {

  window.addEventListener('wheel', (event) => {
    if (event.deltaX < -50 ) {
      document.querySelector('#contact-link').click();
    } else if (event.deltaX > 50) {
      document.querySelector('#gallery-link').click();
    }
  });
};

export { mouseWheelActions };

