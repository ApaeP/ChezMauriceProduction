const resizeCardsHeight = () => {
  window.addEventListener('resize', (event) => {
    let cardHeight = ((parseFloat(window.getComputedStyle(document.querySelector('.card')).width) / 16) * 9).toFixed(2);
    $('.card').css({
      'height': `${cardHeight}px`
    });
  });
};

export { resizeCardsHeight };
