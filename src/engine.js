// DSRT Basic Engine Example
export function initEngine() {
  const canvas = document.getElementById('app');
  const ctx = canvas.getContext('2d');
  resizeCanvas(canvas);
  ctx.fillStyle = '#0ff';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = '#000';
  ctx.font = '20px Arial';
  ctx.fillText('DSRT Engine Active', 20, 40);
}
function resizeCanvas(canvas) {
  canvas.width = window.innerWidth;
  canvas.height = window.innerHeight;
  window.addEventListener('resize', () => {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
  });
}
