const autoplayVideoBackground = () => {
  const video = document.querySelector('#home-video');
  // Jouer la video 2s apres chargement de la page
  setTimeout('document.querySelector("#home-video").play()', 100);
  // Onplay fade video in 2s
  video.addEventListener('play', (event) => {
    setTimeout('document.querySelector("#home-video").style.opacity = "1"', 99)
    video.classList.add('fade-in-on-play');
  });
};

export { autoplayVideoBackground };
