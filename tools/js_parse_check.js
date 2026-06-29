const fs = require('fs');

const path = process.argv[2] || 'assets/web/fortune_sheet/fortune_sheet.js';
const src = fs.readFileSync(path, 'utf8');

try {
  // Parses the script as a function body; sufficient to catch syntax errors.
  // (This doesn't execute the script.)
  // eslint-disable-next-line no-new-func
  new Function(src);
  console.log(`JS parse: OK (${path})`);
  process.exit(0);
} catch (e) {
  console.error(`JS parse: FAIL (${path})`);
  console.error((e && e.stack) || String(e));
  process.exit(1);
}
