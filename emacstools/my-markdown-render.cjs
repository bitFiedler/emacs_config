// Render exports using the same parser/plugins as the installed Livedown.
const fs = require('fs');
const path = require('path');
const {createRequire} = require('module');
const livedown = fs.realpathSync(process.argv[2]);
const root = path.dirname(path.dirname(livedown));
const fromLivedown = createRequire(path.join(root, 'package.json'));
const md = fromLivedown('markdown-it')({html: true, linkify: true});
md.use(fromLivedown('markdown-it-task-checkbox'));
md.use(fromLivedown('markdown-it-emoji'));
md.use(fromLivedown('markdown-it-github-headings'), {prefix: ''});
process.stdout.write(md.render(fs.readFileSync(0, 'utf8')));
