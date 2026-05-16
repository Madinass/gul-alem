const path = require('path');
const nodemailer = require('nodemailer');

require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });

const SMTP_SERVICE = String(process.env.SMTP_SERVICE || process.env.GMAIL_SERVICE || 'gmail').trim();
const SMTP_USER = String(process.env.SMTP_USER || process.env.GMAIL_USER || '').trim();
const SMTP_PASS = String(process.env.SMTP_PASS || process.env.GMAIL_APP_PASSWORD || '').replace(
  /\s/g,
  ''
);
const SMTP_FROM = String(process.env.SMTP_FROM || process.env.GMAIL_FROM || SMTP_USER).trim();
const SMTP_HOST = String(process.env.SMTP_HOST || '').trim();
const SMTP_PORT = Number.parseInt(process.env.SMTP_PORT || '', 10);
const SMTP_SECURE = String(process.env.SMTP_SECURE || '').toLowerCase() === 'true';

const mask = (value) => {
  if (!value) return '<empty>';
  if (value.length <= 4) return '****';
  return `${value.slice(0, 2)}****${value.slice(-2)}`;
};

const errorReason = (error) => {
  const parts = [
    error?.message,
    error?.code && `code=${error.code}`,
    error?.responseCode && `responseCode=${error.responseCode}`,
    error?.command && `command=${error.command}`,
    error?.response && `response=${error.response}`,
  ].filter(Boolean);

  return parts.length > 0 ? parts.join(' | ') : String(error || 'Unknown error');
};

const main = async () => {
  const recipient = process.argv[2] || SMTP_USER;

  console.log('SMTP config being tested:', {
    service: SMTP_SERVICE || null,
    host: SMTP_HOST || null,
    port: Number.isInteger(SMTP_PORT) ? SMTP_PORT : null,
    secure: SMTP_SECURE,
    user: SMTP_USER || null,
    pass: mask(SMTP_PASS),
    from: SMTP_FROM || null,
    recipient: recipient || null,
  });

  if (!SMTP_USER || !SMTP_PASS) {
    throw new Error('SMTP_USER or SMTP_PASS is missing in lib/server/.env');
  }

  const auth = {
    user: SMTP_USER,
    pass: SMTP_PASS,
  };

  const transporter = nodemailer.createTransport(
    SMTP_HOST
      ? {
          host: SMTP_HOST,
          port: Number.isInteger(SMTP_PORT) ? SMTP_PORT : 587,
          secure: SMTP_SECURE,
          auth,
          connectionTimeout: 10000,
          greetingTimeout: 10000,
          socketTimeout: 15000,
        }
      : {
          service: SMTP_SERVICE || 'gmail',
          auth,
          connectionTimeout: 10000,
          greetingTimeout: 10000,
          socketTimeout: 15000,
        }
  );

  console.log('Checking SMTP login...');
  await transporter.verify();
  console.log('SMTP login is OK. Sending test email...');

  const result = await transporter.sendMail({
    from: SMTP_FROM,
    to: recipient,
    subject: 'Gul alem SMTP test',
    text: `SMTP test succeeded at ${new Date().toISOString()}.`,
  });

  console.log('SMTP test email sent:', {
    messageId: result.messageId,
    accepted: result.accepted,
    rejected: result.rejected,
    response: result.response,
  });
};

main().catch((error) => {
  console.error('SMTP TEST FAILED reason:', errorReason(error));
  console.error('SMTP TEST FAILED full error:', error);
  process.exitCode = 1;
});
