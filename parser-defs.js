// All the code below is manually translated from C++ to JS by shaman.sir,
// C++ code author is Ali Rantakari (http://hasseg.org/peg-markdown-highlight/)
// the C++ file used as source is located here: http://hasseg.org/gitweb?p=peg-markdown-highlight.git;a=blob;f=pmh_parser_head.c;h=51528032723b9fc0eed0e854abbe2847b9d127b4;hb=HEAD

var util = require('util');

var cur_state = null;

// =============================================================================
// ELEMENTS TYPES ==============================================================

var t = new Object(null);

t.pmd_PARA            = 0;    /**< Paragraph */
t.pmd_LINK            = 1;    /**< Explicit link */
t.pmd_AUTO_LINK_URL   = 2;    /**< Implicit URL link */
t.pmd_AUTO_LINK_EMAIL = 3;    /**< Implicit email link */
t.pmd_IMAGE           = 4;    /**< Image definition */
t.pmd_CODE            = 5;    /**< Code (inline) */
t.pmd_HTML            = 6;    /**< HTML */
t.pmd_HTML_ENTITY     = 7;    /**< HTML special entity definition */
t.pmd_EMPH            = 8;    /**< Emphasized text */
t.pmd_STRONG          = 9;    /**< Strong text */
t.pmd_LIST_BULLET     = 10;   /**< Bullet for an unordered list item */
t.pmd_LIST_ENUMERATOR = 11;   /**< Enumerator for an ordered list item */
t.pmd_COMMENT         = 12;   /**< (HTML) Comment */

// Code assumes that pmd_H1-6 are in order.
t.pmd_H1              = 13;   /**< Header, level 1 */
t.pmd_H2              = 14;   /**< Header, level 2 */
t.pmd_H3              = 15;   /**< Header, level 3 */
t.pmd_H4              = 16;   /**< Header, level 4 */
t.pmd_H5              = 17;   /**< Header, level 5 */
t.pmd_H6              = 18;   /**< Header, level 6 */

t.pmd_BLOCKQUOTE      = 19;   /**< Blockquote */
t.pmd_VERBATIM        = 20;   /**< Verbatim (e.g. block of code) */
t.pmd_HTMLBLOCK       = 21;   /**< Block of HTML */
t.pmd_HRULE           = 22;   /**< Horizontal rule */
t.pmd_REFERENCE       = 23;   /**< Reference */
t.pmd_NOTE            = 24;   /**< Note */

t.pmd_LIST_BULLET_ITEM = 25;  /**< Item of Bullet list */
t.pmd_LIST_ENUM_ITEM   = 26; /**< Item of Enumerator list */

// Span marker for positions in original input to be post-processed
// in a second parsing step:
t.pmd_BQRAW             = 27;   /**< Internal to parser. Please ignore. */

t.type_name = function(type) {
    switch (type) {
        case t.pmd_BQRAW:              return "BQRAW";

        case t.pmd_PARA:               return "PARA";
        case t.pmd_LINK:               return "LINK";
        case t.pmd_IMAGE:              return "IMAGE";
        case t.pmd_CODE:               return "CODE";
        case t.pmd_HTML:               return "HTML";
        case t.pmd_EMPH:               return "EMPH";
        case t.pmd_STRONG:             return "STRONG";
        case t.pmd_COMMENT:            return "COMMENT";
        case t.pmd_HTML_ENTITY:        return "HTML_ENTITY";
        case t.pmd_LIST_BULLET:        return "LIST_BULLET";
        case t.pmd_LIST_ENUMERATOR:    return "LIST_ENUMERATOR";
        case t.pmd_H1:                 return "H1";
        case t.pmd_H2:                 return "H2";
        case t.pmd_H3:                 return "H3";
        case t.pmd_H4:                 return "H4";
        case t.pmd_H5:                 return "H5";
        case t.pmd_H6:                 return "H6";
        case t.pmd_BLOCKQUOTE:         return "BLOCKQUOTE";
        case t.pmd_VERBATIM:           return "VERBATIM";
        case t.pmd_HTMLBLOCK:          return "HTMLBLOCK";
        case t.pmd_HRULE:              return "HRULE";
        case t.pmd_REFERENCE:          return "REFERENCE";
        case t.pmd_NOTE:               return "NOTE";

        case t.pmd_AUTO_LINK_URL:      return "AUTO_LINK_URL";
        case t.pmd_AUTO_LINK_EMAIL:    return "AUTO_LINK_EMAIL";

        case t.pmd_LIST_BULLET_ITEM:   return "LIST_BULLET_ITEM";
        case t.pmd_LIST_ENUM_ITEM:     return "LIST_ENUM_ITEM";

        default:                       return "?";
    }
}

/**
* \brief Number of types in pmd_element_type.
* \sa pmd_element_type
*/
t.pmd_NUM_TYPES = 31;

/**
* \brief Number of *language element* types in pmd_element_type.
* \sa pmd_element_type
*/
t.pmd_NUM_LANG_TYPES = (t.pmd_NUM_TYPES - 6);

// =============================================================================
// EXTENSIONS ==================================================================

var e = new Object(null);

// PHP Markdown Extra extensions
e.pmd_EXT_FOOTNOTES = 1;
e.pmd_EXT_DEF_LISTS = 2; // + "\:"
e.pmd_EXT_SMART_BLOCKLVL_HTML = 4;
e.pmd_EXT_ABBREVIATIONS = 8;
e.pmd_EXT_MARKDOWN_INSIDE_HTML = 16;
e.pmd_EXT_HEADERS_LINKS = 32;
e.pmd_EXT_CURLY_CODE = 64;
e.pmd_EXT_ALT_TABLES = 128; // + "\|"
e.pmd_EXT_NO_EMPHASIS_IN_QUOTES = 256;

// Other Extentions
e.pmd_EXT_HASHBANG_CODE_LANG = 512;
e.pmd_EXT_DOC_META_INFO = 1024;
e.pmd_EXT_NESTED_BLOCKQUOTES = 2048;
e.pmd_EXT_BLOCKQUOTES_SOURCES = 4096;

e.pmd_EXTENSIONS = e.pmd_EXT_FOOTNOTES
                /* | e.pmd_EXT_DEF_LISTS
                   | e.pmd_EXT_HASHBANG_CODE_LANG
                   | e.pmd_EXT_HEADERS_LINKS */;

e.ext_name = function(ext) {
    switch (ext) {
        case e.pmd_EXT_FOOTNOTES:             return "EXT_FOOTNOTES";
        case e.pmd_EXT_DEF_LISTS:             return "EXT_DEF_LISTS";
        case e.pmd_EXT_SMART_BLOCKLVL_HTML:   return "EXT_SMART_BLOCKLVL_HTML";
        case e.pmd_EXT_ABBREVIATIONS:         return "EXT_ABBREVIATIONS";
        case e.pmd_EXT_MARKDOWN_INSIDE_HTML:  return "EXT_MARKDOWN_INSIDE_HTML";
        case e.pmd_EXT_HEADERS_LINKS:         return "EXT_HEADERS_LINKS";
        case e.pmd_EXT_CURLY_CODE:            return "EXT_CURLY_CODE";
        case e.pmd_EXT_ALT_TABLES:            return "EXT_ALT_TABLES";
        case e.pmd_EXT_NO_EMPHASIS_IN_QUOTES: return "EXT_NO_EMPH_IN_QUOTES";
        case e.pmd_EXT_HASHBANG_CODE_LANG:    return "EXT_HASHBANG_CODE_LANG";
        case e.pmd_EXT_DOC_META_INFO:         return "EXT_DOC_META_INFO";
        case e.pmd_EXT_NESTED_BLOCKQUOTES:    return "EXT_NESTED_BLOCKQUOTES";
        case e.pmd_EXT_BLOCKQUOTES_SOURCES:   return "EXT_BLOCKQUOTES_SOURCES";
        default:                              return "?";
    }
}

var EOL = /(\r\n|\n|\r)/gm;
var DBL_EOL = /\r\n\r\n|\n\n|\r\r/gm;

// =============================================================================
// UTILS =======================================================================

/* pad some string to specified number of chars with spaces (if string is longer
   than specified number of chars, it will be truncated in "start ... end" form) */
function _pad(str, num) {
    var result;
    if (!str) {
        result = '';
        while (num > 0) { result += ' '; num--; }
    } else if (str.length == 1) {
        result = '';
        while (num > 0) { result += str; num--; }
    } else {
        var src = str.replace(EOL, ' ');
        if (num > src.length) {
            result = src;
            while (num > src.length) { result += ' '; num--; }
        } else if (num === src.length) {
            result = src;
        } else /*if (num < str.length)*/ {
            if (num > 12) {
               result = src.substring(0, (num / 2) - 3);
               result += ' ... ';
               result += src.substring(src.length - ((num / 2) - 3), src.length);
               while (num > result.length) { result += ' '; }
            } else {
               result = src.substring(0, num - 2);
               result += '} ';
            }
        }
    }
    return result;
}

// =============================================================================
// STATE =======================================================================

function make_state() {
    return {
        'chain': { 'head': null, 'tail': null }, // dbl-linked list of elements
        'extensions': e.pmd_EXTENSIONS, // enabled extensions
        'elems': [], /*new Array(t.pmd_NUM_TYPES)*/ // elements, indexed by type (int)
        'refs': {}, // references map (label: element)
        '_cur': null, // last processed element
        '_rwaiters': {}, // waiters for references, map (label: array of func)
        'info': function(view) { return state_info(this, view); }, // FIXME: make global funcs
        'toString': function() { return state_info(this); } // FIXME: make global funcs
    }
}

function work_with(state) {
    cur_state = state;
}

function get_state() {
    return cur_state;
}

// TODO: a function that will add node type markers to the text using state refs
/* g_state.spec(text) {
    var result = '';


} */

// =============================================================================
// CHAIN =======================================================================

/* init chain with element: set element to be a head and a tail of a chain */
function chain_init(chain, elem) {
    elem.prev = null;
    elem.next = null;
    chain.head = elem;
    chain.tail = elem;
}

/* set element as a head of a chain */
function chain_set_head(chain, elem) {
    elem.prev = null;
    elem.next = chain.head;
    chain.head.prev = elem;
    chain.head = elem;
}

/* set element as a tail of a chain */
function chain_set_tail(chain, elem) {
    elem.next = null;
    elem.prev = chain.tail;
    chain.tail.next = elem;
    chain.tail = elem;
}

/* find first element which end position is less than passed element position */
function chain_find_prev(chain, elem) {
    var cursor = chain.tail;
    while (cursor != null) {
        if (cursor.end <= elem.pos) {
            return cursor;
        }
        cursor = cursor.prev;
    }
    return null;
}

/* insert element in chain before element at_right */
function chain_insert_before(chain, elem, at_right) {
    elem.next = at_right;
    elem.prev = at_right.prev;
    if (at_right.prev == null) {
        chain.head = elem; // set as new head (at_right is a head)
    } else {
        at_right.prev.next = elem; // let previous element point at new
    }
    at_right.prev = elem;
}

/* replace element in chain with another element */
function chain_replace(chain, what_, with_) {
    with_.prev = what_.prev;
    with_.next = what_.next;
    if (what_.next != null) {
        what_.next.prev = with_;
    } else { // what_ is a tail
        chain.tail = with_;
    }
    if (what_.prev != null) {
        what_.prev.next = with_;
    } else { // what_ is a head
        chain.head = with_;
    }
    what_.prev = null;
    what_.next = null;
}

/* remove element from chain */
function chain_remove(chain, elem) {
    if (elem.prev != null) {
        elem.prev.next = elem.next;
    } else { // elem is head
        chain.head = elem.next;
    }
    if (elem.next != null) {
        elem.next.prev = elem.prev;
    } else {
        chain.tail = elem.prev;
    }
    elem.prev = null;
    elem.next = null;
}

/* insert element in proper position in elements chain */
// deep specifies the level of how deep we gone, its optional and set by recursion
function chain_insert(chain, elem, deep) {

    if (chain.head == null) {
        // set element as a head and a tail
        chain_init(chain, elem);
        return;
    }

    // find first element which end position is less than current element end position
    // next element (at right) to it will be the element that may be wraps it. if not,
    // then insert this element after the element found.

    var prev = chain_find_prev(chain, elem);
    var at_right = (prev != null) ? prev.next : chain.head;

    if (at_right == null) { // prev.next is null, so prev in fact is a tail,
                            // so append element as a tail
        chain_set_tail(chain, elem);
    } else if (elem.pos <= at_right.pos) {
        if ((elem.pos != at_right.pos) &&
            (elem.end < at_right.end)) { // insert before element at right
            chain_insert_before(chain, elem, at_right);
        } else { // place element in place of at_right and then insert at_right inside current element
            chain_replace(chain, at_right, elem);
            chain_insert(elem.children, at_right, deep + 1);
            var cursor = elem.next;
            while (cursor != null) {
                if (cursor.pos > elem.end) { return; }
                var _next = cursor.next; // it may be replaced with further actions
                if (cursor.end <= elem.end) {
                    chain_remove(chain, cursor);
                    chain_insert(elem.children, cursor, deep + 1);
                }
                cursor = _next;
            }
        }
    } else if (elem.end <= at_right.end) { // check if it fits as child
        chain_insert(at_right.children, elem, deep + 1);
    } else {
        throw new Error('No place found for elm: ' + elem);
    }

}

/* walk with a function on a chain of elements. function may return true
   to stop at current element and return it */
function chain_walk(chain, func) {
    if (chain.head != null) {
        var cursor = chain.head;
        while (cursor != null) {
            if (func(cursor)) { return cursor; }
            cursor = cursor.next;
        }
    }
}

/* reverse-walk with a function on a chain of elements. function may return true
   to stop at current element and return it */
function chain_rwalk(chain, func) {
    if (chain.tail != null) {
        var cursor = chain.tail;
        while (cursor != null) {
            if (func(cursor)) { return cursor; }
            cursor = cursor.prev;
        }
    }
}

/* travel with a function through a chain of elements, going deep if needed. 
   function may return true to stop at current element and return it */
function chain_travel(chain, func, deep) {
    var deep = deep || 0;
    if (chain.head != null) {
        var cursor = chain.head;
        while (cursor != null) {
            if (func(cursor, deep)) { return cursor; }
            if (cursor.children.head != null) {
                chain_travel(cursor.children, func, deep + 1);
            }; // FIXME: tail recursion?
            cursor = cursor.next;
        }
    }
}

// =============================================================================
// ELEMENTS ====================================================================

/* create element node with specified parameters */
function make_element_i(state, type, pos, end, text) {
    return { 'type'       : type,
             'pos'        : pos,
             'end'        : end,
             'next'       : null,
             'prev'       : null,
             'text'       : text || null, // a match for the element or the text extract
             'children'   : { 'head': null, 'tail': null }, // dbl-linked list of elements inside
             'data'       : null, // additional data that cannot be represented with text
             'toString'   : _elem_info };
}

function make_element(state, type, chunk) {
    return make_element_i(state, type, chunk.pos, chunk.end, chunk.match);
}

function _elem_info() { return elem_info(this); }

/* add element and some data (optional) to the state */
function add_element(state, elem, data) {

    if (!elem) return;

    chain_insert(state.chain, elem);

    state._cur = elem;

    if (!state.elems[elem.type]) {
        state.elems[elem.type] = [];
    }
    state.elems[elem.type].push(elem);

    elem.data = data;

}

// =============================================================================
// EXTENSIONS ==================================================================

/* check if extension is enabled */
function extension(state, extension) {
    //console.log('extension: ', e.ext_name(extension), state.extensions & extension);
    return state.extensions & extension;
};

// =============================================================================
// REFERENCES ==================================================================

/* save reference data for a label */
function save_reference(state, label, elm) {
    if (!label) return;
    var label = label.toLowerCase();
    state.refs[label] = elm;
    var waiters = state._rwaiters[label];
    if (waiters) {
       for (var i = 0; i < waiters.length; waiters++) {
            waiters[i](elm);
       }
       delete state._rwaiters[label];
    }
}

/* get reference data using label */
function get_reference(state, label) {
    //console.log('get_reference: ', label);
    if (!label) return;
    return state.refs[label];
}

/* wait for reference data to appear and then call passed function
   (will be called with null if there is no such reference at all) */
function wait_reference(state, label, func) {
    var label = label.toLowerCase();
    var ref = get_reference(state,label);
    if (ref) { func(ref) }
    else {
        if (!state._rwaiters[label]) state._rwaiters[label] = [];
        state._rwaiters[label].push(func);
    }
}

/* release (call with null) all waiting functions that hasn't got their references */
function release_waiters(state) {
    for (label in state._rwaiters) {
        var waiters = state._rwaiters[label];
        if (waiters) {
           for (var i = 0; i < waiters.length; waiters++) {
                waiters[i](null);
           }
           delete state._rwaiters[label];
        }
    }
}

// =============================================================================
// SPECIAL =====================================================================

function parse_raw(state, data) {
    if (data.length === 0) return;

    // TODO: wrap blockquote of each level with additional element

    // COLLECTING / PACKING DATA
    var bquotes = []; // contains strings with joined chunks, grouped by same level
    var positions = []; // contains arrays of actual positions, for each character
        // so (bquotes[i].length === positions[i].length)
        // where i is index of the current bquote, bquotes[i] is a string containing
        // the text of bquote where each linehad the same level [before processing],
        // and positions[i] is array of integers, where each positions[i][j]-integer 
        // corresponds to the actual position of the bqoutes[i][j]-character 
    var bqidx = 0; // bqoute index
    var plvl = null; // previous level
    var nlvl, clen, st; // new level, chunk length, chunk start 
    for (var i = 0; i < data.length; i++) {
        nlvl = data[i].level - 1;
        if (plvl === null) plvl = nlvl; // set first plvl
        if (nlvl !== plvl) {
            bqidx++; // switch to next bquote if level changed
            plvl = nlvl; // save new level as previous
        }
        clen = data[i].text.length; // length of current chunk
        st = data[i].start; // current chunk start position
        if (bquotes[bqidx] === undefined) bquotes[bqidx] = ""; // init with empty string
        if (positions[bqidx] === undefined) positions[bqidx] = []; // init with empty array
        // concat current text with new chunk text
        bquotes[bqidx] = bquotes[bqidx].concat(data[i].text); 
        var posarr = []; // collect actual positions in array
        for (var j = 0; j < clen; j++) {
            posarr[j] = st + j;
        }
        // concat current positions array with new positions array
        positions[bqidx] = positions[bqidx].concat(posarr);
        if (bquotes[bqidx].length !== positions[bqidx].length) 
           { throw new Error('lengths not matched, this should not happened!'); }
    }

    // PARSING TIME!
    var parsed;
    for (var i = 0; i < bquotes.length; i++) {
        parsed = $_parser.parse(bquotes[i]);
        chain_travel(parsed.chain, function(elem) {
            add_element(state,
                        make_element_i(state, elem.type,
                                       positions[i][elem.pos],
                                       positions[i][elem.end-1],
                                       elem.text),
                        elem.data);
        });
    }

}

function parse_block_elems(state) {
    if (!$_parser) { throw new Error('No parser accessible, please define global $_parser ' +
                                     'variable to be equal to current parser'); }
                                     // FIXME: store parser var inside somehow
    var raws = state.elems[t.pmd_BQRAW];
    if (raws === undefined) return;
    for (var idx = 0; idx < raws.length; idx++) {
        parse_raw(state, raws[idx].data);
    }
}

// =============================================================================
// GLOBAL ======================================================================

/* executed before parsing */
function before(state) {
    // things to do before parsing
    state.deep = 0;
}

/* executed after parsing */
function after(state) {
    // things to do after parsing
    release_waiters(state);
    parse_block_elems(state);
}

// =============================================================================
// ALIAS =======================================================================

function elem(x,c)         { return make_element(cur_state,x,c) } // type and chunk
function elem_c(x,c)       { return make_element_i(cur_state,x,c.pos,c.end,c.match) } // type, chunk (pos,end,text)
function elem_cz(x,c)      { return make_element_i(cur_state,x,c.pos,c.end) } // type, chunk (pos,end), no text
function elem_ct(x,c,t)    { return make_element_i(cur_state,x,c.pos,c.end,t) } // type, chunk (pos,end) and text
function elem_cn(x,c,n)    { return make_element_i(cur_state,x,c.pos,c.end,c.match.substring(n,c.match.length-n)) } // type, chunk (pos,end) and padding
function elem_pe(x,p,e)    { return make_element_i(cur_state,x,p,e) } // type, pos, end (no text)
function elem_pet(x,p,e,t) { return make_element_i(cur_state,x,p,e,t) } // type, pos, end, text
function elem_z(x)         { return make_element_i(cur_state,x,0,0) } // type only
function add(x,d)          { return add_element(cur_state,x,d) } // x is element, d (data) is optional
function ext(x)            { return extension(cur_state,x) }
function ref_exists(x)     { return (get_reference(cur_state,x) != null) }
function save_ref(x,e)     { return save_reference(cur_state,x,e) }
function get_ref(x)        { return get_reference(cur_state,x) }
function wait_ref(x,f)     { return wait_reference(cur_state,x,f) }
function start()           { return before(cur_state) }
function end()             { return after(cur_state) }

// =============================================================================
// EXPORT ======================================================================

module.exports = {
    'elem': elem,
    'elem_c': elem_c,
    'elem_cz': elem_cz,
    'elem_ct': elem_ct,
    'elem_cn': elem_cn,
    'elem_pe': elem_pe,
    'elem_pet': elem_pet,
    'elem_z': elem_z,
    'add': add,
    'ext': ext,

    'ref_exists': ref_exists,
    'save_ref': save_ref,
    'wait_ref': wait_ref,
    'get_ref': get_ref,

    'start': start,
    'end': end,

    'make_state': make_state,
    'work_with': work_with,
    'get_state': get_state,

    'types': t,
    'exts': e,
    'TYPESTR': t.type_name,
    'EXTSTR': e.ext_name
};

// =============================================================================
// INFORMATION =================================================================

/* return element information string */
function elem_info(elm, col_width, no_pad_text) {
    return _pad(elm.pos + ':' + elm.end, 11) + _pad(t.type_name(elm.type), 18) +
           ((elm.text != null) ? ((no_pad_text)
                                     ? ('\n\n~( ' + elm.text + ' )~\n\n')
                                     : (_pad('<< ' + elm.text + ' >>', col_width || 54)) + '\n')
                               : '--no-text--\n');
}

var V_QUICK = 0;
var V_SHOW_DATA = 1;
var V_NO_STRIP_DATA = 2;
var V_NO_PAD_TEXT = 4;

/* return state information string */
function state_info(state, view) {

    view = view || V_QUICK;

    var result = '\n\n';
    result += '---------------------------- CHAIN ------------------------------------------' + '\n\n';

    chain_travel(state.chain, function(elem, deep) {
       if (view !== V_QUICK) result += '> (' + deep + ') ' + 
           _pad('.',deep*4) + '] ' + _pad('~',69-deep*4) + '\n\n';
       result += elem_info(elem,54-(deep*2),(view & V_NO_PAD_TEXT));
       if ((view & V_SHOW_DATA) && elem.data) {
           result += (view !== V_QUICK) ? '' : _pad('',deep*2);
           result += 'DATA :: '
                     + ((view & V_NO_STRIP_DATA)
                         ? ('\n\n' + util.inspect(elem.data,false,3))
                         : _pad(util.inspect(elem.data,false,3), 66));
           result += (view !== V_QUICK) ? '\n\n\n' : '\n';
       }
    });

    result += '\n\n' + '---------------------------- ELEMENTS ---------------------------------------' + '\n';

    for (var i = 0; i < t.pmd_NUM_TYPES; i++) {
        var elems = state.elems[i];
        if (elems != null) {
            result += '\n%%%%%%%%%%%%%%%%% ' + t.type_name(i) + ':\n\n' ;
            for (var j = 0; j < elems.length; j++) {
                result += elem_info(elems[j], 0, (view & V_NO_PAD_TEXT));
            };
        }
    }

    result += '\n' + '---------------------------- REFERENCES -------------------------------------' + '\n\n';

    for (ref_label in state.refs) {
       result += _pad(ref_label, 20) + ' -> ' + state.refs[ref_label] + '\n';
    };

    result += '\n\n' + '---------------------------- LINKS ------------------------------------------' + '\n\n';

    var elems = state.elems[t.pmd_LINK];
    if (elems != null) {
        for (var j = 0; j < elems.length; j++) {
            result += _pad(elems[j].data.title, 16) + _pad(elems[j].data.label, 12) + _pad(elems[j].data.source, 27) + _pad(elems[j].text, 23) + '\n';
        };
    }

    return result;
}

