const play = (player) => {
  player.play();
};

const closeModal = () => {
  document.querySelector('.video-modal-background').classList.remove('modal-visible');
  document.querySelector('.video-modal-background').classList.add('modal-hidden');
  const videoPlayer = new Vimeo.Player(document.querySelector('#vimeo-video-player > iframe'));
  videoPlayer.pause();
};

const openCloseVideoModal = () => {
  // const modalContent = document.querySelector('.video-modal-content');

  // OPEN
  document.querySelector('html').addEventListener('click', (event) => {
    if (event.target.classList.contains('thumbnail-overlay') || event.target.classList.contains('thumbnail-overlay-title')) {
      if (!document.querySelector('.edit-video-modal-background.modal-visible')) {
        if (document.querySelector('#vimeo-video-player > iframe')) {
          document.querySelector('#vimeo-video-player > iframe').setAttribute('src', `https://player.vimeo.com/video/${event.target.dataset.videoid}?autoplay=1?app_id=122963`);
          const videoPlayer = new Vimeo.Player(document.querySelector('#vimeo-video-player > iframe'));
          setTimeout(play, 500, videoPlayer);
        } else {
          const playerOptions = {
            id: event.target.dataset.videoid,
            height: document.querySelector('.video-modal-content').offsetHeight,
            // height: $('.video-modal-content').offsetHeight,
            autoplay: true
          };
          const videoPlayer = new Vimeo.Player('vimeo-video-player', playerOptions);

          setTimeout(play, 500, videoPlayer);

        }; // End of condition
      }
      document.querySelector('.video-modal-title').innerHTML = event.target.dataset.videotitle;
      document.querySelector('.video-modal-description').innerHTML = event.target.dataset.videodesc;

      document.querySelector('.video-modal-background').classList.toggle('modal-hidden');
      document.querySelector('.video-modal-background').classList.toggle('modal-visible');
    } // if (event.target.classList.contains('thumbnail-overlay')) {
  }); // document.querySelector('html').addEventListener('click', (event) => {

  // CLOSE
  document.querySelector('.video-modal-background').addEventListener('click', (event) => {
    closeModal();
  });

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && document.querySelector('.video-modal-background').classList.contains('modal-visible')) {
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

