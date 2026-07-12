const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const util = require('util');
const execPromise = util.promisify(exec);

const attributes = [
  { name: 'strength', world: 'Forest', color: 'green', stage: 'nature' },
  { name: 'intellect', world: 'City', color: 'blue', stage: 'cyberpunk or futuristic' },
  { name: 'vitality', world: 'Volcanic', color: 'red', stage: 'lava and fire' },
  { name: 'creativity', world: 'Oceanic', color: 'cyan', stage: 'underwater or coral' },
  { name: 'focus', world: 'Lightning', color: 'yellow', stage: 'storm and lightning' },
  { name: 'spirit', world: 'Celestial', color: 'purple', stage: 'space and galaxy' }
];

async function generateIcon(attr) {
  const dir = path.join(__dirname, 'assets', 'icons');
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  const outPath = path.join(dir, `attribute_${attr.name}.png`);
  if (fs.existsSync(outPath)) return;
  const prompt = `a flat minimalist 2D vector app icon for a ${attr.world} theme, ${attr.color} color palette, simple shapes, solid background, clean design`;
  console.log(`Generating icon for ${attr.name}...`);
  await execPromise(`polli gen image "${prompt}" --model flux --output "${outPath}"`);
}

async function generateLevelImage(attr, level) {
  const dir = path.join(__dirname, 'assets', 'worlds', attr.name);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  const outPath = path.join(dir, `level_${level}.jpg`);
  if (fs.existsSync(outPath)) return;
  const prompt = `A beautiful immersive landscape of a ${attr.stage} world, level ${level} evolution, epic scenery, highly detailed, video game concept art`;
  console.log(`Generating image for ${attr.name} level ${level}...`);
  await execPromise(`polli gen image "${prompt}" --model flux --output "${outPath}"`);
}

async function main() {
  // Generate icons
  for (const attr of attributes) {
    await generateIcon(attr);
  }

  // Generate levels with a concurrency of 10
  const tasks = [];
  for (const attr of attributes) {
    for (let level = 1; level <= 50; level++) {
      tasks.push({ attr, level });
    }
  }

  const concurrency = 10;
  for (let i = 0; i < tasks.length; i += concurrency) {
    const chunk = tasks.slice(i, i + concurrency);
    await Promise.all(chunk.map(t => generateLevelImage(t.attr, t.level)));
  }

  console.log("All assets generated!");
}

main().catch(console.error);
