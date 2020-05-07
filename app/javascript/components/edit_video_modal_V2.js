const openCloseEditVideoModal = () => {

  document.querySelector('html').addEventListener('click', (event) => {
    if (event.target.classList.contains('modify-video-button')) {
      document.querySelector(`#edit-video-id-${event.target.dataset.videoid}`).classList.toggle('modal-hidden');
      document.querySelector(`#edit-video-id-${event.target.dataset.videoid}`).classList.toggle('modal-visible');
    } else if (event.target.classList.contains('close-edit-btn-p') || event.target.classList.contains('close-edit-btn-i') || event.target.classList.contains('edit-video-modal-background')) {
      const openedEditModal = document.querySelector('.edit-video-modal-background.modal-visible');
      openedEditModal.classList.toggle('modal-hidden');
      openedEditModal.classList.toggle('modal-visible');
    }
  });

    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape' && document.querySelector('.edit-video-modal-background.modal-visible')) {
        // const openedEditModal = document.querySelector('.edit-video-modal-background.modal-visible');
        document.querySelector('.edit-video-modal-background.modal-visible').classList.toggle('modal-hidden');
        document.querySelector('.edit-video-modal-background.modal-visible').classList.toggle('modal-visible');
      }
    });

};

export { openCloseEditVideoModal };
