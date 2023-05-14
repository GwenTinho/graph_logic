/*
 * Modal
 *
 * Pico.css - https://picocss.com
 * Copyright 2019-2022 - Licensed under MIT
 */

// Config
const modal = document.getElementById("modal");
const isOpenClass = 'modal-is-open';
const openingClass = 'modal-is-opening';
const closingClass = 'modal-is-closing';
const animationDuration = 400; // ms
let visibleModal = null;
let showNonPrime = true;
let showNonConnected = true;


// Toggle modal
function toggleModal(title, text) {
  (typeof(modal) != 'undefined' && modal != null)
    && isModalOpen(modal) ? closeModal() : openModal(title, text)
}

// Is modal open
function isModalOpen () {
  return modal.hasAttribute('open') && modal.getAttribute('open') != 'false' ? true : false;
}

// Open modal
function openModal(title, text, extraButton) {
  if (isScrollbarVisible()) {
    document.documentElement.style.setProperty('--scrollbar-width', `${getScrollbarWidth()}px`);
  }
  document.documentElement.classList.add(isOpenClass, openingClass);
  setTimeout(() => {
    visibleModal = modal;
    document.documentElement.classList.remove(openingClass);
  }, animationDuration);
  const dontSee = document.getElementById("dontsee");
  console.log(dontSee);
  if (dontSee) {
      const modal_footer = document.getElementById("modal-footer");
      modal_footer.removeChild(dontSee);
  }
  if (typeof title !== "undefined") {
      const modal_title = document.getElementById("modal-title");
      modal_title.textContent = title;
  }
  if (typeof text !== "undefined") {
      const modal_text = document.getElementById("modal-text");
      modal_text.textContent = text;
  }
  if (typeof extraButton !== "undefined") {
      const modal_footer = document.getElementById("modal-footer");
      modal_footer.appendChild(extraButton);
  }
  modal.setAttribute('open', true);
}

// Close modal
function closeModal () {
  visibleModal = null;
  document.documentElement.classList.add(closingClass);
  setTimeout(() => {
    document.documentElement.classList.remove(closingClass, isOpenClass);
    document.documentElement.style.removeProperty('--scrollbar-width');
    modal.removeAttribute('open');
  }, animationDuration);
}

// Close with a click outside
document.addEventListener('click', event => {
  if (visibleModal != null) {
    const modalContent = visibleModal.querySelector('article');
    const isClickInside = modalContent.contains(event.target);
    !isClickInside && closeModal(visibleModal);
  }
});

// Close with Esc key
document.addEventListener('keydown', event => {
  if (event.key === 'Escape' && visibleModal != null) {
    closeModal(visibleModal);
  }
});

// Get scrollbar width
const getScrollbarWidth = () => {

  // Creating invisible container
  const outer = document.createElement('div');
  outer.style.visibility = 'hidden';
  outer.style.overflow = 'scroll'; // forcing scrollbar to appear
  outer.style.msOverflowStyle = 'scrollbar'; // needed for WinJS apps
  document.body.appendChild(outer);

  // Creating inner element and placing it in the container
  const inner = document.createElement('div');
  outer.appendChild(inner);

  // Calculating difference between container's full width and the child width
  const scrollbarWidth = (outer.offsetWidth - inner.offsetWidth);

  // Removing temporary elements from the DOM
  outer.parentNode.removeChild(outer);

  return scrollbarWidth;
}

// Is scrollbar visible
const isScrollbarVisible = () => {
  return document.body.scrollHeight > screen.height;
}