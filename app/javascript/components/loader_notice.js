const getOffset = (el) => {
  const rect = el.getBoundingClientRect();
  return {
    left: rect.left + window.scrollX,
    top: rect.top + window.scrollY
  };
}

const setLoader = () => {
  if (document.querySelector('#create-modal-loader')) {
    const modalTop = document.querySelector('.close-add-button');
    const modal = document.querySelector('.add-video');
    const loaderDiv = document.querySelector('#create-modal-loader');

    loaderDiv.style.width = modal.offsetWidth + 'px';
    loaderDiv.style.height = modal.offsetHeight + 'px';
    loaderDiv.style.left = getOffset(modalTop).left + 'px';
  }
}

const displayHideLoaderNotice = () => {
  if (document.querySelector('#create-modal-loader')) {
    const form = document.querySelector('#create-video-form');
    form.addEventListener('submit', (e) => {
      document.querySelector('#create-modal-loader').classList.remove('create-loader-hidden');
      document.querySelector('#create-modal-loader').classList.add('create-loader-visible');
    })
  }
}

export { setLoader, displayHideLoaderNotice };
