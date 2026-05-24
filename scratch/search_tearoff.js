const fs = require('fs');
const readline = require('readline');

async function search() {
  const fileStream = fs.createReadStream('build/web/main.dart.js');
  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity
  });

  let lineNumber = 0;
  for await (const line of rl) {
    lineNumber++;
    if (line.includes('tear_off') || line.includes('tearoff') || line.includes('tearOff')) {
      if (line.length < 500) {
        console.log(`${lineNumber}: ${line}`);
      } else {
        console.log(`${lineNumber}: [long line] ${line.substring(0, 300)}`);
      }
    }
  }
}

search().catch(console.error);
