function logWorkout() {
  const note = document.getElementById('note').value;
  const timestamp = new Date().toLocaleString();
  document.getElementById('status').innerText = "📋 Logget: " + note + " kl. " + timestamp;
}
function startTrip() {
  document.getElementById('status').innerText = "🚀 Trip aktivert via p.shillosybe!";
}
function backup() {
  document.getElementById('status').innerText = "🔐 Backup sendt til Vault";
}
function startMic() {
  if (!('webkitSpeechRecognition' in window)) {
    alert("🎙️ Talegjenkjenning støttes ikke her");
    return;
  }
  const recognition = new webkitSpeechRecognition();
  recognition.lang = "no-NO";
  recognition.onresult = function(event) {
    const transcript = event.results[0][0].transcript;
    document.getElementById('note').value = transcript;
    logWorkout();
  };
  recognition.start();
}
window.onload = function() {
  const cal = document.getElementById("calendar");
  const today = new Date();
  for (let i = -3; i <= 3; i++) {
    const d = new Date(today);
    d.setDate(d.getDate() + i);
    cal.innerHTML += `<p>${d.toDateString()}</p>`;
  }
};
