const autoplayVideoBackground = () => {
  if (document.querySelector('#home-video')) {
    const video = document.querySelector('#home-video');
    document.querySelector("#home-video").play()
    // Onplay fade in video in 2s
    video.addEventListener('play', (event) => {
      setTimeout('document.querySelector("#home-video").style.opacity = "1"', 99)
      video.classList.add('fade-in-on-play');
    });
  }
};

export { autoplayVideoBackground };
