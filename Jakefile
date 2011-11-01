var fs = require('fs');
var util = require('util');
var PEG = require('pegjs');

// CONSTANTS

var SRC_DIR       = ".";
var TEST_DIR      = "./test";
var LIB_DIR       = "./lib";

var PEGJS_REQ = 'pegjs';
var PARSER_DEFS_FILE = SRC_DIR + '/parser-defs.js'; 
var PARSER_SRC_FILE = SRC_DIR + '/markdown.pegjs';
var PARSER_OUT_FILE = LIB_DIR + '/markdown.parser.js';

/*var TESTS = {
	'man': { 'dir': 'manual', 
	         'in-ext': 'md', 
	         'check-ext': 'xhtml' },
	'md-base': { 'dir': 'mdtest1.1/Markdown.mdtest', 
	             'in-ext': 'text', 
	             'check-ext': 'x?html' },
	'md-php': { 'dir': 'mdtest1.1/PHP Markdown.mdtest', 
	            'in-ext': 'text', 
	            'check-ext': 'x?html' },
	'md-php-ex': { 'dir': 'mdtest1.1/PHP Markdown Extra.mdtest', 
	               'in-ext': 'text', 
	               'check-ext': 'x?html' },
	'spec-bsc': { 'dir': 'spec/basics', 
	              'in-ext': 'md', 
	              'check-ext': 'xhtml' },
	'spec-stx': { 'dir': 'spec/syntax', 
	              'in-ext': 'md', 
	              'check-ext': 'xhtml' }
}*/

// ======== UTILS

function abort(message) {
  util.error(message);
  exitFailure();
}

function removeDir(dir) {
  fs.readdirSync(dir).every(function(file) {
    var file = dir  + "/" + file;

    var stats = fs.statSync(file);
    if (stats.isDirectory()) {
      removeDir(file);
    } else {
      fs.unlinkSync(file);
    }

    return true;
  });

  fs.rmdirSync(dir);
}

function dirExists(dir) {
  try {
    var stats = fs.statSync(file);
  } catch (e) {
    return false;
  }

  return stats.isDirectory();
}

function mkdirUnlessExists(dir) {
  try {
    fs.statSync(dir);
  } catch (e) {
    fs.mkdirSync(dir, 0755);
  }
}

// ======== TASKS

desc('Remove previously built versions');
task('clean', [], function() {
  console.log('[Cleaning]: ' + LIB_DIR);

  if (dirExists(LIB_DIR)) {
    removeDir(LIB_DIR);
  }
});

desc('Generate the Markdown parser');
task('build', [], function() {

  console.log('[Building]: ' + PARSER_SRC_FILE + ' -> ...');
  
  var input = fs.readFileSync(PARSER_SRC_FILE, 'utf8');

  try {
    var parser = PEG.buildParser(input);
  } catch (e) {
    if (e.line !== undefined && e.column !== undefined) {
      abort(e.line + ":" + e.column + ": " + e.message);
    } else {
      abort(e.message);
    }
  }

  mkdirUnlessExists(LIB_DIR);
  fs.writeFileSync(PARSER_OUT_FILE, "PEG.parser = " + parser.toSource() + ";\n");

  console.log('[Built]: -> ' + PARSER_OUT_FILE);

});

desc('Test');
task('test', [], function() {
	console.log(util.inspect(Array.prototype.slice.call(arguments)));
});

