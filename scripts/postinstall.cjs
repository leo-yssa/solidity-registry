/* eslint-disable no-console */
const fs = require('fs');
const path = require('path');

function ensureOpenZeppelinVersionedAlias(version) {
  const ozDir = path.join(__dirname, '..', 'node_modules', '@openzeppelin');
  const target = path.join(ozDir, 'contracts');
  const link = path.join(ozDir, `contracts@${version}`);

  if (!fs.existsSync(ozDir) || !fs.existsSync(target)) return;
  if (fs.existsSync(link)) return;

  // Create a relative symlink so it survives path moves.
  try {
    fs.symlinkSync('contracts', link, 'dir');
  } catch (e) {
    // Fallback for Windows
    fs.symlinkSync(target, link, 'junction');
  }

  console.log(`[postinstall] linked ${path.relative(process.cwd(), link)} -> contracts`);
}

ensureOpenZeppelinVersionedAlias('4.9.6');

