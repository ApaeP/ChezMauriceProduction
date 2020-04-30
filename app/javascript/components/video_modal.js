let play = (player) => {
  player.play();
};

const closeModal = () => {
  const videoModalBackground = document.querySelector('.video-modal-background');
  videoModalBackground.classList.toggle('modal-hidden');
  videoModalBackground.classList.toggle('modal-visible');
  // set the player in the function scope
  const videoPlayer = new Vimeo.Player(document.querySelector('#vimeo-video-player > iframe'));
  videoPlayer.pause();
};

const openCloseVideoModal = () => {
  const modalButtons = document.querySelectorAll('.thumbnail-overlay');
  const videoModalBackground = document.querySelector('.video-modal-background');
  const modalTitle = document.querySelector('.video-modal-title');
  const modalDescription = document.querySelector('.video-modal-description');
  // const modalContent = document.querySelector('.video-modal-content');

  // OPEN
  modalButtons.forEach((videoButton) => {
    videoButton.addEventListener('click', (event) => {

      if (document.querySelector('#vimeo-video-player > iframe')) {
      // If player already exists (after first click) => replace the src attribute of the iframe

      document.querySelector('#vimeo-video-player > iframe').setAttribute('src', `https://player.vimeo.com/video/${videoButton.dataset.videoid}?autoplay=1?app_id=122963`);

        // set the player in the scope
        const videoPlayer = new Vimeo.Player(document.querySelector('#vimeo-video-player > iframe'));

        setTimeout(play, 500, videoPlayer);

      } else {
      // If player doesnt exist yet (on first click) => create the player

      const playerOptions = {
        id: videoButton.dataset.videoid,
        height: document.querySelector('.video-modal-content').offsetHeight,
        autoplay: true
      };
      const videoPlayer = new Vimeo.Player('vimeo-video-player', playerOptions);

        setTimeout(play, 500, videoPlayer);

      }; // End of condition

      // fill title and description
      modalTitle.innerHTML = videoButton.dataset.videotitle;
      modalDescription.innerHTML = videoButton.dataset.videodesc;

      // toggle modal
      videoModalBackground.classList.toggle('modal-hidden');
      videoModalBackground.classList.toggle('modal-visible');

    }); // End of click event

  }); // End of OPEN

  // CLOSE
  videoModalBackground.addEventListener('click', (event) => {
    closeModal();
  });

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && videoModalBackground.classList.contains('modal-visible')) {
      closeModal();
    }
  });

};

export { openCloseVideoModal };



//   Redimmensionner la video par rapport a la div#vimeo-video-player:
//    1 - ecouter les changements de taille d'ecran si la div est affichée
//    2 - set l'option max width de la video a la taille de div#vimeo-video-player
        // document.querySelector('#vimeo-video-player > iframe').setAttribute('width', '100%')
//   Quand le lecteur s'ouvre =
//    1 - Afficher le lecteur une fois que la video a commencé a charger
//    2 - Lancer la lecture
//    3 - Quand la video a terminé, cacher la modale


        // // When the player is ready, add listeners for pause, finish, and playProgress
        // videoPlayer.on('ready', function() {

        //   videoPlayer.on('pause', console.log('paused'));
        //   videoPlayer.on('finish', console.log('finished'));
        //   videoPlayer.on('playProgress', console.log('progress'));
        // });






















