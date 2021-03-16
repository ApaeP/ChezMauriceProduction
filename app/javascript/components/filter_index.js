const filterIndex = () => {
  if (document.querySelectorAll('.video-card')) {
    const madeUpBtns = document.querySelectorAll('.made-up-srch-btns');
    const videoCards = document.querySelectorAll('.video-card');
    const videoCardsArr = Array.from(videoCards);
    madeUpBtns.forEach((label) => {
      label.addEventListener('click', (event) => {
        if (document.querySelector('.made-up-srch-btns.filter-btn-active')) {
          document.querySelector('.made-up-srch-btns.filter-btn-active').classList.remove('filter-btn-active');
          label.classList.add('filter-btn-active');
        } else {
          label.classList.add('filter-btn-active');
        }
        const searchedCat = label.dataset.cat;
        const selectedCardsArray = [];
        videoCardsArr.forEach((card) => {
          if (card.dataset.cats.includes(searchedCat)) {
            card.style.display = 'block';
          } else {
            card.style.display = 'none';
          }
        });
      });
    });
  };
};

export { filterIndex };
