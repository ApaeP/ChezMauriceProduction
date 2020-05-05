const form = document.querySelector('.contact-page-form');
// const allInputs = document.querySelectorAll('.form-contact-input');
const allInputs = document.querySelectorAll('.contact-form-element');
const allInputsArray = Array.from(allInputs);
const firstInput = document.querySelector('#name-input');
const secondInput = document.querySelector('#email-input');
const thirdInput = document.querySelector('#content-input');
const submitBtn = document.querySelector('#send-contact-btn');

const allInputsGreen = () => {
  let areGreen = true;
  allInputs.forEach((input) => {
    if (!input.classList.contains('green')) {
      areGreen = false;
    }
  })
  return areGreen;
};

const focusContactForm = () => {

  // au clic, si je suis dans contact et qu'un elem du form est actif
  window.addEventListener('click', (clickevent) => {
    if (window.location.href.includes('contact') && allInputsArray.includes(document.activeElement)) {
      // si je clique dans le form
    }
  });

  // au tab, si je suis dans contact et qu'un elem du form est actif
  document.addEventListener('keydown', (keyevent) => {
    if (keyevent.keyCode === 9 && window.location.href.includes('contact') && allInputsArray.includes(document.activeElement)) {
      if (keyevent.shiftKey) {
        // tab up

        if (allInputsGreen()) {
        // si tout est vert
          if (document.activeElement === firstInput) {
            keyevent.preventDefault();
            submitBtn.disabled = false;
            submitBtn.focus();
          } else if (document.activeElement === submitBtn) {
            keyevent.preventDefault();
            thirdInput.focus();
          }
        } else {
          // si il manque un input
          if (document.activeElement === firstInput) {
            keyevent.preventDefault();
            submitBtn.disabled = true;
            thirdInput.focus();
          } else if (document.activeElement === submitBtn) {
            keyevent.preventDefault();
            thirdInput.focus();
          }
        }
      } else {
        // tab down
        if (allInputsGreen()) {
          if (document.activeElement === thirdInput) {
            keyevent.preventDefault();
            submitBtn.disabled = false;
            submitBtn.focus();
          } else if (document.activeElement === submitBtn) {
            keyevent.preventDefault();
            keyevent.preventDefault();
            firstInput.focus();
          }
        } else {
          if (document.activeElement === thirdInput) {
            keyevent.preventDefault();
            submitBtn.disabled = true;
            firstInput.focus();
          } else if (document.activeElement === submitBtn) {
            keyevent.preventDefault();
            keyevent.preventDefault();
            firstInput.focus();
          }
        }
      }
    }
  });
};

export { focusContactForm };




    // - si le premier element est focus, je descneds vers le suivant,
    // - si le deuxiement element est focus, je descneds vers le suivant
    // - si le troisiement element est focus mais red, je remonte vers le premier
    // - si le troisieme element est focus et green je descend vers le bouton
    // - si le bouton est focus, je remonte vers le premier}

  // // si un element du form a le focus:
  // if (window.location.href.includes('contact')) {
  //   form.addEventListener('transitionstart', (event) => {
  //     // - je vais ecouter les tabs:
  //     document.addEventListener('keypressed', (e) => {
  //       if (e.keyCode === 9) {
  //         // si tab vers le haut
  //         if (e.shiftKey) {
  //           console.log('je tab vers le haut dans le formulaire');
  //         }
  //         // si tab vers le bas
  //         console.log('je tab vers le bas dans le formulaire');

  //       }
  //     });
  //   });
  // };



  // document.querySelector('.contact-page-form').addEventListener('transitionend', (e) => {
  //   if (document.activeElement === document.querySelector('#content-input')) {
  //     document.addEventListener('keydown', (e) => {
  //       if (e.keyCode === 9 && document.activeElement === document.querySelector('#content-input')) {
  //         console.log('tab')
  //         document.querySelector('#name-input').focus();
  //       }
  //     });
  //   } else {
  //     if (document.querySelector('.contact-page-form').querySelector('.red')) {
  //       document.querySelector('.contact-page-form').querySelector('.red').focus();
  //     }
  //   }
  // });
