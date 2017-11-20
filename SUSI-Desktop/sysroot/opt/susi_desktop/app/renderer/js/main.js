onload = function () {
	const webview = document.querySelector('webview');
	const loading = document.querySelector('#loading');

	function onStopLoad() {
		loading.classList.add('hide');
	}

	function onStartLoad() {
		loading.classList.remove('hide');
	}

	webview.addEventListener('did-stop-loading', onStopLoad);
	webview.addEventListener('did-start-loading', onStartLoad);
};
