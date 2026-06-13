const { spawn, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });

const port = process.argv[2] || process.env.MAIL_RELAY_PORT || '8787';
const rawDomain = String(process.argv[3] || process.env.NGROK_DOMAIN || '').trim();

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

const ngrokPath = findNgrok();

if (!ngrokPath) {
  console.error('ngrok.exe was not found. Install it with: winget install ngrok.ngrok');
  process.exit(1);
}

console.log(`Starting ngrok from: ${ngrokPath}`);
console.log(`Forwarding to local port: ${port}`);

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

const domain = normalizeDomain(rawDomain);
if (domain) {
  console.log(`Using static ngrok domain: ${domain}`);
}

const args = domain ? ['http', `--domain=${domain}`, port] : ['http', port];

const child = spawn(ngrokPath, args, {
  stdio: 'inherit',
  windowsHide: false,
});

child.on('exit', (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
    return;
  }
  process.exit(code ?? 0);
});
