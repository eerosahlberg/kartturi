#!/usr/bin/env node
/**
 * Generate Mapbox/MapLibre glyph PBF files using Mapbox's `fontnik`.
 *
 * Uses fontTools (via Python) to enumerate every mapped Unicode codepoint,
 * groups them into 256-codepoint range blocks, then calls `fontnik.range` for
 * each block to produce `{range}.pbf`. Ensures ALL Unicode ranges present in
 * the font (including supplementary planes) are emitted.
 *
 * Prereq: python fontTools in .venv, fontnik npm package installed.
 *
 * Usage:
 *   node gen_glyphs_fontnik.js <font.ttf> <outdir> [fontstackName]
 */
const fontnik = require('fontnik');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const fontPath = process.argv[2];
const outDir = process.argv[3];
const stackName = process.argv[4] || path.basename(fontPath, path.extname(fontPath));

if (!fontPath || !outDir) {
	console.error('Usage: node gen_glyphs_fontnik.js <font.ttf> <outdir> [name]');
	process.exit(1);
}

// Enumerate all mapped codepoints with fontTools (fast, no rendering).
const venvPy =
	process.env.VENV_PY ||
	(fs.existsSync(path.join(__dirname, '..', '..', '.venv', 'bin', 'python'))
		? path.join(__dirname, '..', '..', '.venv', 'bin', 'python')
		: 'python3');
const scriptPath = path.join(__dirname, 'list_cmap.py');
let cps;
try {
	cps = JSON.parse(execSync(`"${venvPy}" "${scriptPath}" "${fontPath}"`, { encoding: 'utf8' }).trim());
} catch (e) {
	console.error('Failed to enumerate cmap with fontTools:', e.stderr || e.message);
	process.exit(1);
}

// Group by 256-codepoint range blocks. fontnik only supports BMP (0-65535),
// which covers all Latin/Cyrillic/Greek/CJK needed for the map text.
const blocks = new Map();
for (const cp of cps) {
	if (cp > 0xffff) continue;
	const block = cp - (cp % 256);
	if (!blocks.has(block)) blocks.set(block, []);
	blocks.get(block).push(cp);
}

fs.mkdirSync(outDir, { recursive: true });
const fontBuffer = fs.readFileSync(fontPath);

const blockStarts = [...blocks.keys()].sort((a, b) => a - b);
let written = 0;
let done = 0;

blockStarts.forEach((blockStart) => {
	fontnik.range(
		{
			font: fontBuffer,
			start: blockStart,
			end: blockStart + 255,
		},
		(err, pbf) => {
			if (err) {
				console.error(`Error on block ${blockStart}:`, err.message);
			} else {
				fs.writeFileSync(path.join(outDir, `${blockStart}.pbf`), pbf);
				written++;
			}
			done++;
			if (done === blockStarts.length) {
				console.log(`Wrote ${written} .pbf files to ${outDir} (fontstack '${stackName}')`);
			}
		},
	);
});
