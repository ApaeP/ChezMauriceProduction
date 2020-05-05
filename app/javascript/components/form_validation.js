const allInputs = document.querySelectorAll('.form-contact-input');
const allInputsArr = Array.from(allInputs);
const mailInput = document.querySelector('.email-contact')

const mailRegex = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
const submitBtn = document.querySelector('#send-contact-btn');

const isFilled = input => input.value;

const validEmail = () => {
  return mailRegex.test(mailInput.value);
};

const allFilled = () => allInputsArr.every(isFilled);

const enableBtn = () => {
  if (allFilled() && validEmail()) {
    submitBtn.disabled = false;
  } else {
    submitBtn.disabled = true;
  }
};

const authorizeForm = () => {

  allInputs.forEach((input) => {
    input.addEventListener('blur', (e) => {

      if (isFilled(input) && !input.classList.contains('email-contact')) {
        if (input.classList.contains('red')) {
          input.classList.remove('red');
        }
        input.classList.add('green');
      } else {
        if (!input.classList.contains('email-contact')) {
          input.classList.add('red');
        }
      }

      if (isFilled(input) && input.classList.contains('email-contact') && validEmail()) {
        if (input.classList.contains('red')) {
          input.classList.remove('red');
        }
        input.classList.add('green');
      } else {
        if (input.classList.contains('email-contact')) {
          input.classList.add('red');
        }
      }

      enableBtn();

    })
  });

};

export { authorizeForm };
