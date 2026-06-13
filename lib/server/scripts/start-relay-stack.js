const { spawn, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });

const relayPort = String(process.env.MAIL_RELAY_PORT || '8787').trim();
const rawDomain = String(process.argv[2] || process.env.NGROK_DOMAIN || '').trim();

const unique = (items) => Array.from(new Set(items.filter(Boolean)));

const findNgrok = () => {
  const fromEnv = process.env.NGROK_PATH;
  const fromWhere =
    process.platform === 'win32'
      ? spawnSync('where.exe', ['ngrok'], { encoding: 'utf8' }).stdout
          .split(/\r?\n/)
          .map((line) => line.trim())
          .filter(Boolean)
      : spawnSync('which', ['ngrok'], { encoding: 'utf8' }).stdout
          .split(/\r?\n/)
          .map((line) => line.trim())
          .filter(Boolean);

  const localAppData = process.env.LOCALAPPDATA || '';
  const candidates = unique([
    fromEnv,
    ...fromWhere,
    localAppData && path.join(localAppData, 'Microsoft', 'WinGet', 'Links', 'ngrok.exe'),
    localAppData && path.join(localAppData, 'Programs', 'ngrok', 'ngrok.exe'),
    'C:\\ngrok\\ngrok.exe',
  ]);

  return candidates.find((candidate) => fs.existsSync(candidate));
};

const normalizeDomain = (value) => {
  if (!value) return '';
  try {
    const url = value.startsWith('http://') || value.startsWith('https://')
      ? new URL(value)
      : new URL(`https://${value}`);
    return url.host;
  } catch (_) {
    return value.replace(/^https?:\/\//i, '').replace(/\/.*$/, '').trim();
  }
};

const ngrokPath = findNgrok();
if (!ngrokPath) {
  console.error('ngrok.exe was not found. Install it with: winget install ngrok.ngrok');
  process.exit(1);
}

const domain = normalizeDomain(rawDomain);
const ngrokArgs = domain ? ['http', `--domain=${domain}`, relayPort] : ['http', relayPort];
const children = [];

const startChild = (name, command, args) => {
  console.log(`Starting ${name}: ${command} ${args.join(' ')}`);
  const child = spawn(command, args, {
    cwd: path.resolve(__dirname, '..'),
    stdio: 'inherit',
    windowsHide: false,
  });
  children.push(child);
  child.on('exit', (code, signal) => {
    if (signal) {
      console.log(`${name} stopped by ${signal}`);
    } else if (code) {
      console.log(`${name} exited with code ${code}`);
    }
    stopAll();
  });
};

let stopping = false;
const stopAll = () => {
  if (stopping) return;
  stopping = true;
  for (const child of children) {
    if (!child.killed) child.kill();
  }
};

process.on('SIGINT', () => {
  stopAll();
});
process.on('SIGTERM', () => {
  stopAll();
});

if (domain) {
  console.log(`Static relay URL: https://${domain}/send-reset-code`);
} else {
  console.log('NGROK_DOMAIN is empty. ngrok will create a temporary URL.');
}

startChild('mail relay', process.execPath, [path.join('scripts', 'mail-relay.js')]);
startChild('ngrok', ngrokPath, ngrokArgs);
