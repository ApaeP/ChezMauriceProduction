const scrollToInfoDiv = () => {
  if (document.querySelector('#home-div')) {
    $("#info-link").click(function() {
      $('html,body').animate({
        scrollTop: (window.innerHeight - document.querySelector('.navbar-height').offsetHeight) + 1},
        1000
      );
    });
    $("#info-link-phone").click(function() {
      if ($('#menuToggle')) {
        $('#menuToggle > div > input').click()
      }
      $('html,body').animate({
        scrollTop: (window.innerHeight - document.querySelector('.navbar-height').offsetHeight) + 1},
        1000
      );
    });
    $("#accueil-link").click(function() {
      $('html,body').animate({
        scrollTop: $("#home-div").offset().top},
        1000
      );
    });
  }

  if (window.location.href.includes('#informations')) {
    $('html,body').animate({
      scrollTop: (window.innerHeight - document.querySelector('.navbar-height').offsetHeight) + 1},
      1000
    );
  }
};

export { scrollToInfoDiv };

// navigator.userAgent.includes('Safari') && navigator.userAgent.includes('Mobi')
