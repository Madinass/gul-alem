const assert = require('assert');
const test = require('node:test');

const {
  getPaymentKey,
  encryptField,
  decryptField,
  hashToken,
  normalizeTagList,
  dedupeTags,
  escapeRegex,
  stripMarkdown,
  isFlowerTopic,
  buildChatTitle,
  mapTagMatches,
  buildAutoTags,
  resolveProductTags,
} = require('../utils');

test('normalizeTagList handles strings and arrays', () => {
  assert.deepStrictEqual(normalizeTagList('a, b, , c'), ['a', 'b', 'c']);
  assert.deepStrictEqual(normalizeTagList([' x ', 2, null]), ['x', '2', 'null']);
  assert.deepStrictEqual(normalizeTagList(undefined), []);
});

test('dedupeTags removes duplicates', () => {
  assert.deepStrictEqual(dedupeTags(['a', 'b', 'a']), ['a', 'b']);
});

test('escapeRegex escapes special characters', () => {
  const escaped = escapeRegex('a+b?c');
  assert.strictEqual(escaped, 'a\\+b\\?c');
});

test('stripMarkdown removes basic markdown', () => {
  const input = '*Hello* **world** `code`';
  const output = stripMarkdown(input);
  assert.strictEqual(output, 'Hello world code');
});

test('isFlowerTopic detects flower keywords', () => {
  assert.strictEqual(isFlowerTopic('Flower bouquet delivery'), true);
  assert.strictEqual(isFlowerTopic('Laptop stand'), false);
});

test('buildChatTitle returns original for short text', () => {
  assert.strictEqual(buildChatTitle('Hello'), 'Hello');
});

test('mapTagMatches maps basic tags', () => {
  const result = mapTagMatches('birthday gift for mom');
  assert.ok(result.occasion.includes('birthday'));
  assert.ok(result.recipient.includes('mom'));
});

test('buildAutoTags adds defaults and inferred tags', () => {
  const result = buildAutoTags('birthday bouquet');
  assert.ok(result.occasionTags.includes('birthday'));
  assert.ok(result.occasionTags.includes('congrats'));
  assert.ok(result.recipientTags.includes('universal'));
});

test('resolveProductTags prefers explicit tags', () => {
  const result = resolveProductTags({
    occasionTags: 'love, wedding',
    recipientTags: ['friend', 'friend'],
    name: 'birthday gift',
  });
  assert.deepStrictEqual(result.occasionTags, ['love', 'wedding']);
  assert.deepStrictEqual(result.recipientTags, ['friend']);
});

test('hashToken produces deterministic sha256 hex', () => {
  const hash = hashToken('hello');
  assert.strictEqual(hash.length, 64);
  assert.strictEqual(hash, hashToken('hello'));
});

test('encryptField/decryptField round trip', () => {
  const key = 'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
  const payload = encryptField('secret', key);
  const value = decryptField(payload, key);
  assert.strictEqual(value, 'secret');
});

test('getPaymentKey throws on missing key', () => {
  assert.throws(() => getPaymentKey(''), /PAYMENT_ENC_KEY/);
});
