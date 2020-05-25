// Default SortableJS
import Sortable from 'sortablejs/modular/sortable.core.esm.js';

const initSortable = () => {
  if (document.querySelector('#sortable-ul')) {
    const el = document.querySelector('#sortable-ul');
    Sortable.create(el, {
      onEnd: function (evt) {
        const element1 = document.querySelector('#numero_newIndex');
        const element2 = document.querySelector('#numero_oldIndex');
        const updateBtn = document.querySelector('.update-rank-btn');
        element1.value = evt.newIndex;
        element2.value = evt.oldIndex;
        updateBtn.click();
      }
    });
  }
}

export { initSortable };

