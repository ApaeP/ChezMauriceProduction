const returnFromLegalNotice = () => {
  if (document.querySelector('.return-from-legal')) {
    document.querySelectorAll('.return-from-legal').forEach((btn) => {
      btn.addEventListener('click', (e) => {
        if (window.close()) {

        } else {
          window.location.href = "http://chezmauriceproduction.com/";
        }
      });
    });
  }
};

export { returnFromLegalNotice };
