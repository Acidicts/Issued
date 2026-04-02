const FLASH_AUTO_DISMISS_MS = 4500;
const FLASH_FADE_DURATION_MS = 450;

function hideFlashMessage(element) {
  if (!element.classList.contains("flash-message--hidden")) {
    element.classList.add("flash-message--hidden");
    setTimeout(() => {
      element.remove();
    }, FLASH_FADE_DURATION_MS);
  }
}

function setupFlashFadeOut() {
  const flashContainer = document.getElementById("flash-container");
  if (!flashContainer) return;

  const messages = flashContainer.querySelectorAll(".flash-message");
  messages.forEach((message) => {
    const timeoutId = setTimeout(() => hideFlashMessage(message), FLASH_AUTO_DISMISS_MS);

    message.addEventListener("mouseenter", () => {
      clearTimeout(timeoutId);
      message.classList.remove("flash-message--hidden");
    });

    message.addEventListener("mouseleave", () => {
      setTimeout(() => hideFlashMessage(message), 750);
    });

    message.addEventListener("click", () => hideFlashMessage(message));
  });
}

document.addEventListener("turbo:load", setupFlashFadeOut);
document.addEventListener("DOMContentLoaded", setupFlashFadeOut);
