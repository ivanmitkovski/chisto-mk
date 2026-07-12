#!/usr/bin/env node
/**
 * Validates admin i18n message catalogs: key parity, no em dashes, ICU placeholder parity.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const messagesRoot = path.resolve(__dirname, '../src/i18n/messages');
const LOCALES = ['en', 'mk', 'sq'];

const EM_DASH = '\u2014';
const EN_DASH = '\u2013';

function shouldFlagUntranslated(enVal) {
  if (typeof enVal !== 'string' || enVal.length <= 3) return false;
  if (/^[A-Z0-9_./:?=&%+•x\-()@]+$/.test(enVal)) return false;
  if (/^\+[\d]/.test(enVal)) return false;
  if (/^[x•\-/\s.@]+$/i.test(enVal)) return false;
  if (/^FREQ=/.test(enVal)) return false;
  if (/^admin@/.test(enVal)) return false;
  if (/^Chisto/i.test(enVal)) return false;
  if (/^(English|Македонски|Shqip)$/.test(enVal.trim())) return false;
  const loanwords =
    /^(Apple Maps|Google Maps|OpenStreetMap|CARTO|Postmark|Twilio|Draft|Live|Outbox|Email|Admin|Moderator|Super admin|Super Admin|JSON|2FA|MFA|QR|IP|CSV|HTTP|SSE|UTC|RRULE|E\.164|Prometheus|Media)$/i;
  if (loanwords.test(enVal.trim())) return false;
  if (/\(en\)|\(mk\)|quiz JSON/i.test(enVal)) return false;
  return true;
}

function listNamespaces(locale) {
  const dir = path.join(messagesRoot, locale);
  return fs.readdirSync(dir).filter((f) => f.endsWith('.json')).map((f) => f.replace(/\.json$/, ''));
}

function flattenKeys(obj, prefix = '') {
  const keys = [];
  for (const [key, value] of Object.entries(obj)) {
    const full = prefix ? `${prefix}.${key}` : key;
    if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
      keys.push(...flattenKeys(value, full));
    } else {
      keys.push(full);
    }
  }
  return keys.sort();
}

function getByPath(obj, dotted) {
  return dotted.split('.').reduce((acc, part) => (acc == null ? acc : acc[part]), obj);
}

function extractIcuPlaceholders(str) {
  if (typeof str !== 'string') return [];
  const matches = str.match(/\{[a-zA-Z0-9_]+(?:,\s*[^}]*)?\}/g) ?? [];
  return matches
    .map((m) => m.replace(/^\{([^,}]+).*$/, '$1'))
    .sort();
}

function loadLocale(locale) {
  const namespaces = listNamespaces(locale);
  const data = {};
  for (const ns of namespaces) {
    const raw = fs.readFileSync(path.join(messagesRoot, locale, `${ns}.json`), 'utf8');
    data[ns] = JSON.parse(raw);
  }
  return data;
}

function main() {
  const enNs = listNamespaces('en');
  for (const locale of LOCALES) {
    const ns = listNamespaces(locale);
    const missing = enNs.filter((n) => !ns.includes(n));
    const extra = ns.filter((n) => !enNs.includes(n));
    if (missing.length || extra.length) {
      console.error(`Namespace mismatch for ${locale}: missing=${missing.join(',')} extra=${extra.join(',')}`);
      process.exit(1);
    }
  }

  const catalogs = Object.fromEntries(LOCALES.map((l) => [l, loadLocale(l)]));
  let failed = false;

  for (const ns of enNs) {
    const enKeys = flattenKeys(catalogs.en[ns]);
    for (const locale of ['mk', 'sq']) {
      const localeKeys = flattenKeys(catalogs[locale][ns]);
      const enSet = new Set(enKeys);
      const localeSet = new Set(localeKeys);
      for (const k of enKeys) {
        if (!localeSet.has(k)) {
          console.error(`Missing key ${locale}.${ns}.${k}`);
          failed = true;
        }
      }
      for (const k of localeKeys) {
        if (!enSet.has(k)) {
          console.error(`Extra key ${locale}.${ns}.${k}`);
          failed = true;
        }
      }
    }

    for (const key of enKeys) {
      const enVal = getByPath(catalogs.en[ns], key);
      for (const locale of LOCALES) {
        const val = getByPath(catalogs[locale][ns], key);
        if (typeof val !== 'string') continue;
        if (val.includes(EM_DASH) || val.includes(EN_DASH)) {
          console.error(`Dash found in ${locale}.${ns}.${key}: ${val}`);
          failed = true;
        }
      }

      const enPlaceholders = extractIcuPlaceholders(enVal);
      for (const locale of ['mk', 'sq']) {
        const val = getByPath(catalogs[locale][ns], key);
        if (typeof val !== 'string') continue;
        const ph = extractIcuPlaceholders(val);
        if (ph.join(',') !== enPlaceholders.join(',')) {
          console.error(
            `ICU placeholder mismatch ${ns}.${key}: en=[${enPlaceholders}] ${locale}=[${ph}]`,
          );
          failed = true;
        }
        const fullKey = `${ns}.${key}`;
        if (
          locale !== 'en' &&
          val === enVal &&
          shouldFlagUntranslated(enVal)
        ) {
          console.error(`Untranslated ${locale}.${fullKey}: "${val}"`);
          failed = true;
        }
      }
    }
  }

  if (failed) {
    process.exit(1);
  }
  console.log(`check-admin-i18n: OK (${enNs.length} namespaces × ${LOCALES.length} locales)`);
}

main();
