const path = require('path');
const electron = require('electron');
const WindowStateKeeper = require('electron-window-state');

const {app, BrowserWindow} = electron;

// Globally declaring main window to prevent it from being garbage collected.
let mainWindow;

// Adds debug features like hotkeys for triggering dev tools and reload.
require('electron-debug')();

// This is the main URL which will be loaded into our app.
const mainURL = 'file://' + path.join(__dirname, '../renderer', 'index.html');

const APP_ICON = path.join(__dirname, '../resources', 'icon');

const iconPath = () => {
	return APP_ICON + (process.platform === 'win32' ? '.ico' : '.png');
};

// Function to handle 'closed' event
function onClosed() {
	// Dereference the mainWindow.
	mainWindow = null;
}

// A function to create a new BrowserWindow.
function createMainWindow() {
	// Default main window state
	const mainWindowState = new WindowStateKeeper({
		defaultWidth: 1000,
		defaultHeight: 600
	});

	const win = new BrowserWindow({
		// Creating a new window
		title: 'SUSI AI',
		icon: iconPath(),
		x: mainWindowState.x,
		y: mainWindowState.y,
		width: mainWindowState.width,
		height: mainWindowState.height,
		minWidth: 600,
		minHeight: 500,
		webPreferences: {
			plugins: true,
			allowDisplayingInsecureContent: true,
			nodeIntegration: true
		},
		show: false,
		autoHideMenuBar: true
	});

	win.on('focus', () => {
		win.webContents.send('focus');
	});

	win.once('ready-to-show', () => {
		win.show();
	});

	win.on('closed', onClosed);

	win.loadURL(mainURL);
	// Let mainWindowState update listeners automatically on main window.
	mainWindowState.manage(win);

	return win;
}

app.on('activate', () => {
	if (!mainWindow) {
		mainWindow = createMainWindow();
	}
});

// Triggers when the app is ready.
app.on('ready', () => {
	// Assigning the globally declared mainWindow
	mainWindow = createMainWindow();

	// Grabbing the DOM
	const page = mainWindow.webContents;

	// Display web-content when DOM has loaded
	page.on('dom-ready', () => {
		mainWindow.show();
	});
});

app.on('window-all-closed', () => {
	if (process.platform !== 'darwin') {
		app.quit();
	}
});
