function resizeFont(event) {
  winWidth = window.outerWidth,
  document.body.style.fontSize = (winWidth / 800) + 'em';
}
window.addEventListener('resize', resizeFont, false);
