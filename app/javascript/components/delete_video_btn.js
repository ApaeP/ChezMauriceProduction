const deleteVideoButton = () => {
  if (document.querySelectorAll('.delete-video-btn')) {
    document.querySelectorAll('.delete-video-btn').forEach((deleteBtn) => {
      deleteBtn.addEventListener('click', (event) => {
        document.querySelector('.video-modal-background').classList.toggle('modal-visible');
        document.querySelector('.video-modal-background').classList.toggle('modal-hidden');
      });
    });
  }
};

export { deleteVideoButton };
