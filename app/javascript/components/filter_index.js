const filterIndex = () => {
  const madeUpBtns = document.querySelectorAll('.made-up-srch-btns');
  const videoCards = document.querySelectorAll('.video-card');
  const videoCardsArr = Array.from(videoCards);
  madeUpBtns.forEach((label) => {
    label.addEventListener('click', (event) => {
    // $(document).on('click', label, function(e){
      const searchedCat = label.dataset.cat
      const selectedCardsArray = []
      videoCardsArr.forEach((card) => {
        if (card.dataset.cats.includes(searchedCat)) {
          card.style.display = 'block';
        } else {
          card.style.display = 'none';
        }
      })

    });
  });
};

export { filterIndex };
