const allInputs = document.querySelectorAll('.form-contact-input');
const allInputsArr = Array.from(allInputs);
const mailInput = document.querySelector('.email-contact');
const contentInput = document.querySelector('#content-input');

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

const contentFieldHasContent = () => {
  contentInput.addEventListener('input', (e) => {
    if (isFilled(contentInput)) {
      if (contentInput.classList.contains('red')) {
        contentInput.classList.remove('red');
        contentInput.classList.add('green');
      } else {
        contentInput.classList.add('green')
      }
    } else {
      if (contentInput.classList.contains('green')) {
        contentInput.classList.remove('green');
        contentInput.classList.add('red');
      } else {
        contentInput.classList.add('red')
      }
    }
  })
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

export { authorizeForm, contentFieldHasContent };
