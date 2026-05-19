import sourceMap from 'source-map';
import fs from 'fs';

async function main() {
  const raw = JSON.parse(fs.readFileSync('build/web/main.dart.js.map', 'utf-8'));
  const consumer = await new sourceMap.SourceMapConsumer(raw);
  
  const frames = [
    { line: 71905, column: 46, desc: 'rP.cj - TypeError: Cannot read properties of null' },
    { line: 4360, column: 79, desc: 'tear_off' },
    { line: 148519, column: 22, desc: 'Np.ks' },
    { line: 71938, column: 13, desc: 'rP.mh' },
    { line: 148024, column: 24, desc: 'Np.cH' },
    { line: 147615, column: 9, desc: 'Np.ag7' },
    { line: 147589, column: 7, desc: 'Np.b4H' },
    { line: 147604, column: 3, desc: 'Np.wj' },
    { line: 148054, column: 3, desc: 'aes.Jr' },
    { line: 148183, column: 39, desc: 'pH.FV' },
    { line: 4207, column: 20, desc: 'Object.f' },
    { line: 41322, column: 18, desc: 'Object.bRF' },
    { line: 147333, column: 16, desc: 'ja.gQm' },
    { line: 143241, column: 57, desc: 'P0.a4' },
    { line: 86199, column: 5, desc: 'ajp.C' },
    { line: 130402, column: 21, desc: 'P0.cj (1)' },
    { line: 143237, column: 5, desc: 'P0.cj (2)' },
    { line: 130373, column: 9, desc: 'P0.me (1)' },
    { line: 130408, column: 11, desc: 'P0.me (2)' },
    { line: 130322, column: 10, desc: 'P0.Pv' },
  ];
  
  for (const f of frames) {
    const original = consumer.originalPositionFor({ line: f.line, column: f.column });
    console.log(`${f.line}:${f.column} ${f.desc}`);
    console.log(`  -> ${original.source}:${original.line}:${original.column} [${original.name || '?'}]`);
    console.log('');
  }
  
  consumer.destroy();
}
main().catch(e => console.error(e));