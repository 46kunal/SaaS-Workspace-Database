const pingBtn = document.getElementById('ping');

async function pingApi() {
	// TODO: point to real endpoint once backend ready
	await fetch('/test').catch(() => {});
}

if (pingBtn) {
	pingBtn.addEventListener('click', pingApi);
}
