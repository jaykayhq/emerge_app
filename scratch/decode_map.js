const fs = require('fs');
const http = require('https');
const sourceMap = require('source-map');

const mapUrl = 'https://tradeflash-l2966.web.app/main.dart.js.map';
const localMapPath = 'scratch/main.dart.js.map';

const points = [
  { line: 71905, column: 46 },
  { line: 4360, column: 79 },
  { line: 148519, column: 22 },
  { line: 71938, column: 13 },
  { line: 148024, column: 24 },
  { line: 147615, column: 9 },
  { line: 147589, column: 7 },
  { line: 147604, column: 3 },
  { line: 148054, column: 3 },
  { line: 148183, column: 39 }
];

function downloadMap(url, dest) {
  return new Promise((resolve, reject) => {
    console.log(`Downloading source map from ${url}...`);
    const file = fs.createWriteStream(dest);
    http.get(url, (response) => {
      if (response.statusCode !== 200) {
        reject(new Error(`Failed to download: ${response.statusCode}`));
        return;
      }
      response.pipe(file);
      file.on('finish', () => {
        file.close();
        console.log('Download complete.');
        resolve();
      });
    }).on('error', (err) => {
      fs.unlink(dest, () => {});
      reject(err);
    });
  });
}

async function run() {
  try {
    if (!fs.existsSync(localMapPath)) {
      await downloadMap(mapUrl, localMapPath);
    } else {
      console.log(`Using existing local map at ${localMapPath}`);
    }

    console.log('Reading source map file...');
    const rawSourceMap = JSON.parse(fs.readFileSync(localMapPath, 'utf8'));
    
    console.log('Parsing source map...');
    const consumer = await new sourceMap.SourceMapConsumer(rawSourceMap);
    
    console.log('Mapping stack trace points:');
    for (const pt of points) {
      const original = consumer.originalPositionFor({
        line: pt.line,
        column: pt.column
      });
      console.log(`JS: ${pt.line}:${pt.column} -> Dart: ${original.source}:${original.line}:${original.column} (name: ${original.name})`);
    }
    
    consumer.destroy();
  } catch (err) {
    console.error('Error:', err);
  }
}

run();
