const openCloseCreateVideoModal = () => {
  if (document.querySelector('#add-video-button')) {
    const createButton = document.querySelector('#add-video-button');
    const createVideoModalBackground = document.querySelector('.create-video-modal-background');

    // OPEN
    createButton.addEventListener('click', (event) => {

      createVideoModalBackground.classList.toggle('modal-hidden');
      createVideoModalBackground.classList.toggle('modal-visible');

    }); // End of OPEN

    // CLOSE
    document.querySelector('.close-add-btn').addEventListener('click', (event) => {
      createVideoModalBackground.classList.toggle('modal-hidden');
      createVideoModalBackground.classList.toggle('modal-visible');
    });

    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape' && createVideoModalBackground.classList.contains('modal-visible')) {
        createVideoModalBackground.classList.toggle('modal-hidden');
        createVideoModalBackground.classList.toggle('modal-visible');
      }
    });
  }
};

export { openCloseCreateVideoModal };
