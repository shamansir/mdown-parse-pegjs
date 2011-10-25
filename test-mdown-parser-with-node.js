var fs = require('fs');
var PEG = require('pegjs');

var pegPath = process.cwd() + '/';

try {
    var parser = PEG.buildParser(
                 fs.readFileSync(pegPath + 'markdown.pegjs', 'utf-8'));
    var testContent = fs.readFileSync(pegPath + 'mdown-test/single-block-test.md', 'utf-8');
    //var testContent = fs.readFileSync(pegPath + 'mdown-test/progressing.md', 'utf-8');

    //var parser = PEG.buildParser(
    //             fs.readFileSync(pegPath + 'temp.pegjs', 'utf-8'));
    //var testContent = fs.readFileSync(pegPath + 'temp.md', 'utf-8');

    $_parser = parser; // a global variable to use from inside parse process
    var result = parser.parse(testContent);
    console.log('=====');
    /*console.log('result:',
        result.info(0
           // V_SHOW_DATA(1) | V_NO_STRIP_DATA(2) | V_NO_PAD_TEXT(4)
        ));*/
} catch(e) {
    console.log('error',e);
    throw e;
}

