const openCloseEditVideoModal = () => {
  const editBtns = document.querySelectorAll('.modify-video-button');
  const editModals = document.querySelectorAll('.edit-video-modal-background');

  editBtns.forEach((button) => {
    button.addEventListener('click', (event) => {
      document.querySelector('.video-modal-background').classList.toggle('modal-visible');
      document.querySelector('.video-modal-background').classList.toggle('modal-hidden');
      document.querySelector(`#edit-video-id-${button.dataset.videoid}`).classList.toggle('modal-hidden');
      document.querySelector(`#edit-video-id-${button.dataset.videoid}`).classList.toggle('modal-visible');
    });
  });

  document.addEventListener('click', (event) => {
    if (event.target.classList.contains('close-edit-btn-p') || event.target.classList.contains('close-edit-btn-i') || event.target.classList.contains('edit-video-modal-background')) {
      const openedEditModal = document.querySelector('.edit-video-modal-background.modal-visible');
      openedEditModal.classList.toggle('modal-hidden');
      openedEditModal.classList.toggle('modal-visible');
    }
  });

  document.querySelectorAll('.close-edit-btn-p').forEach((closeBtn) => {
    closeBtn.addEventListener('click', (event) => {
      const openedEditModal = document.querySelector('.edit-video-modal-background.modal-visible');
      openedEditModal.classList.toggle('modal-hidden');
      openedEditModal.classList.toggle('modal-visible');
    });
  });

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && document.querySelector('.edit-video-modal-background.modal-visible')) {
      const openedEditModal = document.querySelector('.edit-video-modal-background.modal-visible');
      openedEditModal.classList.toggle('modal-hidden');
      openedEditModal.classList.toggle('modal-visible');
    }
  });
};

export { openCloseEditVideoModal };
