/*
 * ============= PEGJS MARKDOWN PARSER: TREE GENERATOR =========================
 *
 * PegJS Markdown Parser: Tree Generator, JavaScript part is programmed by
 * Ulric Wilfred <shaman.sir@gmail.com>, http://shamansir.github.com
 *
 * PEG rules and the idea are taken and adapted to PegJS from PegC version written
 * by Ali Rantakari. PegC version in its turn is written using PEG grammar
 * from John MacFarlane
 *
 * === ORIGINAL COMMENT: ===
 *
 * PEG Markdown Highlight
 * Copyright 2011 Ali Rantakari -- http://hasseg.org
 * Licensed under the GPL2+ and MIT licenses (see LICENSE for more info).
 *
 * pmd_grammar.leg
 *
 * This is a slightly adapted version of the PEG grammar from John MacFarlane's
 * peg-markdown compiler.
 */

// see parser-defs.js for the source of used functions and variables

{

    var d = require(process.cwd() + '/parser-defs');
    var e = d.exts;
    var t = d.types;

    function packListData(start, cont) {
        for (var i = 0, result = [start]; i < cont.length; i++) {
            for (var j = 0; j < cont[i].length; j++) {
                result.push(cont[i][j]);
        }   }
        return result;
    }

    function extractListText(data) {
        for (var i = 0, text = ''; i < data.length; i++) {
            for (var j = 0, src = data[i][2]; j < src.length; j++) {
                for (var k = 0; k < src[j].length; k++) {
                    text += src[j][k];
        }   }   }
        return text;
    }

    d.start();

    d.deep = 0; // TODO: move to before(state)

    // TODO: _chunk.match is not required for parsers, remove element text?

}

start =     Doc { d.end(); return d.state; }

Doc =       ( Block )*

// placeholder for marking locations
LocMarker = &. { return _chunk.pos; }

BlockElm = b:( BlockQuote
              / Note
              / Reference
              / HorizontalRule
              / Heading
              / OrderedList
              / BulletList
              / HtmlBlock
              / StyleBlock
              / Para
              / Plain ) { // all block-elms return their numeric types
                          return b; }

Block =     BlankLine*
            (Verbatim / BlockElm)
            BlankLine*

Para =      NonindentSpace 
            txt:Inlines 
            BlankLine+
            { d.add(d.elem_ct(t.pmd_PARA,_chunk,txt));
              return t.pmd_PARA; }

Plain =     Inlines { return -1; }

AtxInline = !Newline !(Sp? '#'* Sp Newline) Inline

AtxStart =  hashes:( "######" / "#####" / "####" / "###" / "##" / "#" )
            { return (t.pmd_H1 + (hashes.length - 1)) }

AtxHeading = hx:AtxStart Sp?
             txt:( ( AtxInline )+ { return _chunk.match } )
             (Sp? '#'* Sp)? Newline
             { d.add(d.elem_ct(hx,_chunk,txt)); return hx; }

SetextHeading = SetextHeading1 / SetextHeading2

SetextBottom1 = "===" '='* Newline

SetextBottom2 = "---" '-'* Newline

SetextHeading1 =  &(RawLine SetextBottom1)
                  s:LocMarker
                  txt:( ( !Endline Inline )+ { return _chunk.match } ) Sp? Newline
                  SetextBottom1
                  { d.add(d.elem_pet(t.pmd_H1,s,_chunk.end,txt)); 
                    return t.pmd_H1; }

SetextHeading2 =  &(RawLine SetextBottom2)
                  s:LocMarker
                  txt:( ( !Endline Inline )+ { return _chunk.match } ) Sp? Newline
                  SetextBottom2
                  { d.add(d.elem_pet(t.pmd_H2,s,_chunk.end,txt));
                    return t.pmd_H2; }

Heading = SetextHeading / AtxHeading { return t.pmd_H1; }

BlockQuote = block:/*OneLinersBlockquote / */BlockBasedBlockquote
             { d.add(d.elem_ct(t.pmd_BLOCKQUOTE,_chunk,block.text),block);
               return t.pmd_BLOCKQUOTE; }

/*OneLinersBlockquote = lines:(
                         w:( l:('>'+ { return _chunk.match } ) ' '? { return l.length } )
                         s:LocMarker
                         start:( Line { return _chunk.match } )
                         next:( !'>' !BlankLine Line { return _chunk.match } )*
                         stop:( BlankLine { return '\n' } )*
                         { return { 'text': start+next.join('')+stop, 'start': s,
                                    'level': w } }
                      )+
                      { return lines; }*/

BlockBasedBlockquote = !Space s:LocMarker 
                       w:( l:('>'+ { return _chunk.match } ) ' '+
                           { return l.length } )
                       o:LocMarker
                       !{ d.deep = d.deep + 1; }
                       ( bl:BlankLine* ind:AnyIndent 
                         &{ return (bl.length == 0) || (ind === d.deep); } )
                       start:( BlockElm { return _chunk.match; } )
                       BlankLine*
                       next:( !'>' ( Verbatim /
                              ( ind:Indents &{ return (ind === d.deep); }
                                BlockElm ) )
                              BlankLine*
                              { return _chunk.match; } )*
                       !{ d.deep = d.deep - 1; }              
                       { return { 'text': start+next.join(''), 'start': s, 'level': w } }

VerbatimChunk = ( !BlankLine 
                  ind:Indents &{ return (ind > d.deep); }  
                  Line )+

Verbatim = (VerbatimChunk BlankLine*)+
           { d.add(d.elem_c(t.pmd_VERBATIM,_chunk)); 
             return t.pmd_VERBATIM; }

HorizontalRule = NonindentSpace
                 s1:LocMarker
                 ( '*' Sp '*' Sp '*' (Sp '*')*
                 / '-' Sp '-' Sp '-' (Sp '-')*
                 / '_' Sp '_' Sp '_' (Sp '_')*)
                 s2:LocMarker
                 Sp Newline BlankLine+
                 { d.add(d.elem_pe(t.pmd_HRULE,s1,s2));
                   return t.pmd_HRULE; }

Bullet = !HorizontalRule /*NonindentSpace*/ ('+' / '*' / '-') Spacechar+

Enumerator = /*NonindentSpace*/ [0-9]+ '.' Spacechar+

BulletList = &Bullet data:BulletListItems
             { d.add(d.elem_ct(t.pmd_LIST_BULLET,_chunk,_chunk.match),data);
               return t.pmd_LIST_BULLET; }

OrderedList = &Enumerator data:OrderedListItems
              { d.add(d.elem_ct(t.pmd_LIST_ENUMERATOR,_chunk,_chunk.match),data);
                return t.pmd_LIST_ENUMERATOR; }

AnyBulletListItem = BulletListInlinedItem / BulletListItem

AnyOrderedListItem = OrderedListInlinedItem / OrderedListItem

BulletListItems = data:(
                    AnyBulletListItem
                    ( ind:AnyIndent &{ return (ind === d.deep); }
                      AnyBulletListItem )*
                    BlankLine*
                    { return _chunk.match; } )
                  { return data; }

OrderedListItems = data:(
                     AnyOrderedListItem
                     ( ind:AnyIndent &{ return (ind === d.deep); }
                       AnyOrderedListItem )* 
                     BlankLine*
                     { return _chunk.match; } )  
                   { return data; }             

BulletListInlinedItem = !Space s:LocMarker
                        Bullet o:LocMarker
                        ( bl:BlankLine* ind:AnyIndent 
                          &{ return (bl.length == 0) || (ind === d.deep); } )
                        i:(ListInlines { return _chunk.match; })
                        !BlankLine
                        { d.add(d.elem_c(t.pmd_LIST_BULLET_ITEM,_chunk));
                          return [s,o,i]; }

OrderedListInlinedItem = !Space s:LocMarker
                         Enumerator o:LocMarker
                         ( bl:BlankLine* ind:AnyIndent 
                           &{ return (bl.length == 0) || (ind === d.deep); } )
                         i:(ListInlines { return _chunk.match; })
                         !BlankLine
                         { d.add(d.elem_c(t.pmd_LIST_ENUM_ITEM,_chunk));
                           return [s,o,i]; }

// TODO: check verbatim at start of list items (or blank lines before it)

BulletListItem = !Space s:LocMarker Bullet
                 o:LocMarker
                 !{ d.deep = d.deep + 1; }
                 ( bl:BlankLine* ind:AnyIndent 
                   &{ return (bl.length == 0) || (ind === d.deep); } )
                 start:( BlockElm { return _chunk.match; } )
                 BlankLine*                 
                 next:( !(Bullet / Enumerator)
                        ( Verbatim /
                          ( ind:Indents &{ return (ind === d.deep); }
                            BlockElm ) )
                        BlankLine*
                        { return _chunk.match; } )*
                 !{ d.deep = d.deep - 1; }
                 { d.add(d.elem_c(t.pmd_LIST_BULLET_ITEM,_chunk));
                   return [s,(o-s),start+next.join(''),
                                   _chunk.match.substring(o-s)]; }                   

OrderedListItem = !Space s:LocMarker Enumerator
                  o:LocMarker
                  !{ d.deep = d.deep + 1; }
                  ( bl:BlankLine* ind:AnyIndent
                    &{ return (bl.length == 0) || (ind === d.deep); } )                     
                  start:( BlockElm { return _chunk.match; } )
                  BlankLine*
                  next:( !(Bullet / Enumerator)
                         ( Verbatim / 
                           ( ind:Indents &{ return (ind === d.deep); }
                             BlockElm ) )
                         BlankLine*
                         { return _chunk.match; } )*
                  !{ d.deep = d.deep - 1; }
                  { d.add(d.elem_c(t.pmd_LIST_ENUM_ITEM,_chunk));
                    return [s,(o-s),start+next.join(''),
                                    _chunk.match.substring(o-s)]; }

// Parsers for different kinds of block-level HTML content.
// This is repetitive due to constraints of PEG grammar.

// TODO: add "table"?..

HtmlBlockOpenAddress = '<' Spnl ("address" / "ADDRESS") Spnl HtmlAttribute* '>'
HtmlBlockCloseAddress = '<' Spnl '/' ("address" / "ADDRESS") Spnl '>'
HtmlBlockAddress = HtmlBlockOpenAddress (HtmlBlockAddress / !HtmlBlockCloseAddress .)* HtmlBlockCloseAddress

HtmlBlockOpenBlockquote = '<' Spnl ("blockquote" / "BLOCKQUOTE") Spnl HtmlAttribute* '>'
HtmlBlockCloseBlockquote = '<' Spnl '/' ("blockquote" / "BLOCKQUOTE") Spnl '>'
HtmlBlockBlockquote = HtmlBlockOpenBlockquote (HtmlBlockBlockquote / !HtmlBlockCloseBlockquote .)* HtmlBlockCloseBlockquote

HtmlBlockOpenCenter = '<' Spnl ("center" / "CENTER") Spnl HtmlAttribute* '>'
HtmlBlockCloseCenter = '<' Spnl '/' ("center" / "CENTER") Spnl '>'
HtmlBlockCenter = HtmlBlockOpenCenter (HtmlBlockCenter / !HtmlBlockCloseCenter .)* HtmlBlockCloseCenter

HtmlBlockOpenDir = '<' Spnl ("dir" / "DIR") Spnl HtmlAttribute* '>'
HtmlBlockCloseDir = '<' Spnl '/' ("dir" / "DIR") Spnl '>'
HtmlBlockDir = HtmlBlockOpenDir (HtmlBlockDir / !HtmlBlockCloseDir .)* HtmlBlockCloseDir

HtmlBlockOpenDiv = '<' Spnl ("div" / "DIV") Spnl HtmlAttribute* '>'
HtmlBlockCloseDiv = '<' Spnl '/' ("div" / "DIV") Spnl '>'
HtmlBlockDiv = HtmlBlockOpenDiv (HtmlBlockDiv / !HtmlBlockCloseDiv .)* HtmlBlockCloseDiv

HtmlBlockOpenDl = '<' Spnl ("dl" / "DL") Spnl HtmlAttribute* '>'
HtmlBlockCloseDl = '<' Spnl '/' ("dl" / "DL") Spnl '>'
HtmlBlockDl = HtmlBlockOpenDl (HtmlBlockDl / !HtmlBlockCloseDl .)* HtmlBlockCloseDl

HtmlBlockOpenFieldset = '<' Spnl ("fieldset" / "FIELDSET") Spnl HtmlAttribute* '>'
HtmlBlockCloseFieldset = '<' Spnl '/' ("fieldset" / "FIELDSET") Spnl '>'
HtmlBlockFieldset = HtmlBlockOpenFieldset (HtmlBlockFieldset / !HtmlBlockCloseFieldset .)* HtmlBlockCloseFieldset

HtmlBlockOpenForm = '<' Spnl ("form" / "FORM") Spnl HtmlAttribute* '>'
HtmlBlockCloseForm = '<' Spnl '/' ("form" / "FORM") Spnl '>'
HtmlBlockForm = HtmlBlockOpenForm (HtmlBlockForm / !HtmlBlockCloseForm .)* HtmlBlockCloseForm

HtmlBlockOpenH1 = '<' Spnl ("h1" / "H1") Spnl HtmlAttribute* '>'
HtmlBlockCloseH1 = '<' Spnl '/' ("h1" / "H1") Spnl '>'
HtmlBlockH1 = HtmlBlockOpenH1 txt:( (HtmlBlockH1 / !HtmlBlockCloseH1 .)* { return _chunk.match } ) HtmlBlockCloseH1
              { d.add(d.elem_ct(t.pmd_H1,_chunk,txt)) }

HtmlBlockOpenH2 = '<' Spnl ("h2" / "H2") Spnl HtmlAttribute* '>'
HtmlBlockCloseH2 = '<' Spnl '/' ("h2" / "H2") Spnl '>'
HtmlBlockH2 = HtmlBlockOpenH2 txt:( (HtmlBlockH2 / !HtmlBlockCloseH2 .)* { return _chunk.match } ) HtmlBlockCloseH2
              { d.add(d.elem_ct(t.pmd_H2,_chunk,txt)) }

HtmlBlockOpenH3 = '<' Spnl ("h3" / "H3") Spnl HtmlAttribute* '>'
HtmlBlockCloseH3 = '<' Spnl '/' ("h3" / "H3") Spnl '>'
HtmlBlockH3 = HtmlBlockOpenH3 txt:( (HtmlBlockH3 / !HtmlBlockCloseH3 .)* { return _chunk.match } ) HtmlBlockCloseH3
              { d.add(d.elem_ct(t.pmd_H3,_chunk,txt)) }

HtmlBlockOpenH4 = '<' Spnl ("h4" / "H4") Spnl HtmlAttribute* '>'
HtmlBlockCloseH4 = '<' Spnl '/' ("h4" / "H4") Spnl '>'
HtmlBlockH4 = HtmlBlockOpenH4 txt:( (HtmlBlockH4 / !HtmlBlockCloseH4 .)* { return _chunk.match } ) HtmlBlockCloseH4
              { d.add(d.elem_ct(t.pmd_H4,_chunk,txt)) }

HtmlBlockOpenH5 = '<' Spnl ("h5" / "H5") Spnl HtmlAttribute* '>'
HtmlBlockCloseH5 = '<' Spnl '/' ("h5" / "H5") Spnl '>'
HtmlBlockH5 = HtmlBlockOpenH5 txt:( (HtmlBlockH5 / !HtmlBlockCloseH5 .)* { return _chunk.match } ) HtmlBlockCloseH5
              { d.add(d.elem_ct(t.pmd_H5,_chunk,txt)) }

HtmlBlockOpenH6 = '<' Spnl ("h6" / "H6") Spnl HtmlAttribute* '>'
HtmlBlockCloseH6 = '<' Spnl '/' ("h6" / "H6") Spnl '>'
HtmlBlockH6 = HtmlBlockOpenH6 txt:( (HtmlBlockH6 / !HtmlBlockCloseH6 .)* { return _chunk.match } ) HtmlBlockCloseH6
              { d.add(d.elem_ct(t.pmd_H6,_chunk,txt)) }

HtmlBlockOpenMenu = '<' Spnl ("menu" / "MENU") Spnl HtmlAttribute* '>'
HtmlBlockCloseMenu = '<' Spnl '/' ("menu" / "MENU") Spnl '>'
HtmlBlockMenu = HtmlBlockOpenMenu (HtmlBlockMenu / !HtmlBlockCloseMenu .)* HtmlBlockCloseMenu

HtmlBlockOpenNoframes = '<' Spnl ("noframes" / "NOFRAMES") Spnl HtmlAttribute* '>'
HtmlBlockCloseNoframes = '<' Spnl '/' ("noframes" / "NOFRAMES") Spnl '>'
HtmlBlockNoframes = HtmlBlockOpenNoframes (HtmlBlockNoframes / !HtmlBlockCloseNoframes .)* HtmlBlockCloseNoframes

HtmlBlockOpenNoscript = '<' Spnl ("noscript" / "NOSCRIPT") Spnl HtmlAttribute* '>'
HtmlBlockCloseNoscript = '<' Spnl '/' ("noscript" / "NOSCRIPT") Spnl '>'
HtmlBlockNoscript = HtmlBlockOpenNoscript (HtmlBlockNoscript / !HtmlBlockCloseNoscript .)* HtmlBlockCloseNoscript

HtmlBlockOpenOl = '<' Spnl ("ol" / "OL") Spnl HtmlAttribute* '>'
HtmlBlockCloseOl = '<' Spnl '/' ("ol" / "OL") Spnl '>'
HtmlBlockOl = HtmlBlockOpenOl (HtmlBlockOl / !HtmlBlockCloseOl .)* HtmlBlockCloseOl

HtmlBlockOpenP = '<' Spnl ("p" / "P") Spnl HtmlAttribute* '>'
HtmlBlockCloseP = '<' Spnl '/' ("p" / "P") Spnl '>'
HtmlBlockP = HtmlBlockOpenP (HtmlBlockP / !HtmlBlockCloseP .)* HtmlBlockCloseP

HtmlBlockOpenPre = '<' Spnl ("pre" / "PRE") Spnl HtmlAttribute* '>'
HtmlBlockClosePre = '<' Spnl '/' ("pre" / "PRE") Spnl '>'
HtmlBlockPre = HtmlBlockOpenPre (HtmlBlockPre / !HtmlBlockClosePre .)* HtmlBlockClosePre

HtmlBlockOpenTable = '<' Spnl ("table" / "TABLE") Spnl HtmlAttribute* '>'
HtmlBlockCloseTable = '<' Spnl '/' ("table" / "TABLE") Spnl '>'
HtmlBlockTable = HtmlBlockOpenTable (HtmlBlockTable / !HtmlBlockCloseTable .)* HtmlBlockCloseTable

HtmlBlockOpenUl = '<' Spnl ("ul" / "UL") Spnl HtmlAttribute* '>'
HtmlBlockCloseUl = '<' Spnl '/' ("ul" / "UL") Spnl '>'
HtmlBlockUl = HtmlBlockOpenUl (HtmlBlockUl / !HtmlBlockCloseUl .)* HtmlBlockCloseUl

HtmlBlockOpenDd = '<' Spnl ("dd" / "DD") Spnl HtmlAttribute* '>'
HtmlBlockCloseDd = '<' Spnl '/' ("dd" / "DD") Spnl '>'
HtmlBlockDd = HtmlBlockOpenDd (HtmlBlockDd / !HtmlBlockCloseDd .)* HtmlBlockCloseDd

HtmlBlockOpenDt = '<' Spnl ("dt" / "DT") Spnl HtmlAttribute* '>'
HtmlBlockCloseDt = '<' Spnl '/' ("dt" / "DT") Spnl '>'
HtmlBlockDt = HtmlBlockOpenDt (HtmlBlockDt / !HtmlBlockCloseDt .)* HtmlBlockCloseDt

HtmlBlockOpenFrameset = '<' Spnl ("frameset" / "FRAMESET") Spnl HtmlAttribute* '>'
HtmlBlockCloseFrameset = '<' Spnl '/' ("frameset" / "FRAMESET") Spnl '>'
HtmlBlockFrameset = HtmlBlockOpenFrameset (HtmlBlockFrameset / !HtmlBlockCloseFrameset .)* HtmlBlockCloseFrameset

HtmlBlockOpenLi = '<' Spnl ("li" / "LI") Spnl HtmlAttribute* '>'
HtmlBlockCloseLi = '<' Spnl '/' ("li" / "LI") Spnl '>'
HtmlBlockLi = HtmlBlockOpenLi (HtmlBlockLi / !HtmlBlockCloseLi .)* HtmlBlockCloseLi

HtmlBlockOpenTbody = '<' Spnl ("tbody" / "TBODY") Spnl HtmlAttribute* '>'
HtmlBlockCloseTbody = '<' Spnl '/' ("tbody" / "TBODY") Spnl '>'
HtmlBlockTbody = HtmlBlockOpenTbody (HtmlBlockTbody / !HtmlBlockCloseTbody .)* HtmlBlockCloseTbody

HtmlBlockOpenTd = '<' Spnl ("td" / "TD") Spnl HtmlAttribute* '>'
HtmlBlockCloseTd = '<' Spnl '/' ("td" / "TD") Spnl '>'
HtmlBlockTd = HtmlBlockOpenTd (HtmlBlockTd / !HtmlBlockCloseTd .)* HtmlBlockCloseTd

HtmlBlockOpenTfoot = '<' Spnl ("tfoot" / "TFOOT") Spnl HtmlAttribute* '>'
HtmlBlockCloseTfoot = '<' Spnl '/' ("tfoot" / "TFOOT") Spnl '>'
HtmlBlockTfoot = HtmlBlockOpenTfoot (HtmlBlockTfoot / !HtmlBlockCloseTfoot .)* HtmlBlockCloseTfoot

HtmlBlockOpenTh = '<' Spnl ("th" / "TH") Spnl HtmlAttribute* '>'
HtmlBlockCloseTh = '<' Spnl '/' ("th" / "TH") Spnl '>'
HtmlBlockTh = HtmlBlockOpenTh (HtmlBlockTh / !HtmlBlockCloseTh .)* HtmlBlockCloseTh

HtmlBlockOpenThead = '<' Spnl ("thead" / "THEAD") Spnl HtmlAttribute* '>'
HtmlBlockCloseThead = '<' Spnl '/' ("thead" / "THEAD") Spnl '>'
HtmlBlockThead = HtmlBlockOpenThead (HtmlBlockThead / !HtmlBlockCloseThead .)* HtmlBlockCloseThead

HtmlBlockOpenTr = '<' Spnl ("tr" / "TR") Spnl HtmlAttribute* '>'
HtmlBlockCloseTr = '<' Spnl '/' ("tr" / "TR") Spnl '>'
HtmlBlockTr = HtmlBlockOpenTr (HtmlBlockTr / !HtmlBlockCloseTr .)* HtmlBlockCloseTr

HtmlBlockOpenScript = '<' Spnl ("script" / "SCRIPT") Spnl HtmlAttribute* '>'
HtmlBlockCloseScript = '<' Spnl '/' ("script" / "SCRIPT") Spnl '>'
HtmlBlockScript = HtmlBlockOpenScript (!HtmlBlockCloseScript .)* HtmlBlockCloseScript

HtmlBlockInTags = HtmlBlockAddress
                / HtmlBlockBlockquote
                / HtmlBlockCenter
                / HtmlBlockDir
                / HtmlBlockDiv
                / HtmlBlockDl
                / HtmlBlockFieldset
                / HtmlBlockForm
                / HtmlBlockH1
                / HtmlBlockH2
                / HtmlBlockH3
                / HtmlBlockH4
                / HtmlBlockH5
                / HtmlBlockH6
                / HtmlBlockMenu
                / HtmlBlockNoframes
                / HtmlBlockNoscript
                / HtmlBlockOl
                / HtmlBlockP
                / HtmlBlockPre
                / HtmlBlockTable
                / HtmlBlockUl
                / HtmlBlockDd
                / HtmlBlockDt
                / HtmlBlockFrameset
                / HtmlBlockLi
                / HtmlBlockTbody
                / HtmlBlockTd
                / HtmlBlockTfoot
                / HtmlBlockTh
                / HtmlBlockThead
                / HtmlBlockTr
                / HtmlBlockScript

HtmlBlock = html:( ( HtmlBlockInTags / HtmlComment / HtmlBlockSelfClosing ) { return _chunk.match } )
            BlankLine+
            { d.add(d.elem_ct(t.pmd_HTML,_chunk,html));
              return t.pmd_HTML; }

HtmlBlockSelfClosing = '<' Spnl HtmlBlockType Spnl HtmlAttribute* '/' Spnl '>'

HtmlBlockType = "address" / "blockquote" / "center" / "dir" / "div" / "dl" / "fieldset" / "form" / "h1" / "h2" / "h3" /
                "h4" / "h5" / "h6" / "hr" / "isindex" / "menu" / "noframes" / "noscript" / "ol" / "p" / "pre" / "table" /
                "ul" / "dd" / "dt" / "frameset" / "li" / "tbody" / "td" / "tfoot" / "th" / "thead" / "tr" / "script" /
                "ADDRESS" / "BLOCKQUOTE" / "CENTER" / "DIR" / "DIV" / "DL" / "FIELDSET" / "FORM" / "H1" / "H2" / "H3" /
                "H4" / "H5" / "H6" / "HR" / "ISINDEX" / "MENU" / "NOFRAMES" / "NOSCRIPT" / "OL" / "P" / "PRE" / "TABLE" /
                "UL" / "DD" / "DT" / "FRAMESET" / "LI" / "TBODY" / "TD" / "TFOOT" / "TH" / "THEAD" / "TR" / "SCRIPT"

// TODO: store style?
StyleOpen =     '<' Spnl ("style" / "STYLE") Spnl HtmlAttribute* '>'
StyleClose =    '<' Spnl '/' ("style" / "STYLE") Spnl '>'
InStyleTags =   StyleOpen (!StyleClose .)* StyleClose
StyleBlock =    InStyleTags
                BlankLine* { return t.pmd_HTML; }

Inlines  =  ( !Endline Inline
              / Endline &Inline )+ 
            Endline? { return _chunk.match }

ListInlines  =  ( !BlankLine Sp
                  !('>' / Bullet / Enumerator) 
                  LineWithMarkup Newline
                )+ 
                { return _chunk.match }                

LineWithMarkup = (Str / UlOrStarLine / Space / Markup)+

Markup = Strong
         / Emph
         / Image
         / Link
         / NoteReference
         / InlineNote
         / Code
         / RawHtml
         / Entity
         / EscapedChar
         / Symbol            

Inline  = Str
        / Endline
        / UlOrStarLine
        / Space
        / Markup

Space = Spacechar+

Str = NormalChar (NormalChar / '_'+ &Alphanumeric)*

EscapedChar =   '\\' !Newline [-\\`|*_{}[\]()#+.!><]

Entity =    ( HexEntity / DecEntity / CharEntity )
            { d.add(d.elem_c(t.pmd_HTML_ENTITY,_chunk)) }

Endline =   ( LineBreak / TerminalEndline / NormalEndline )

NormalEndline =   Sp Newline !BlankLine !'>' !AtxStart
                  !(Line ("===" '='* / "---" '-'*) Newline)

TerminalEndline = Sp Newline Eof

LineBreak = "  " NormalEndline

Symbol =    SpecialChar

// This keeps the parser from getting bogged down on long strings of '*' or '_',
// or strings of '*' or '_' with space on each side:
UlOrStarLine =  (UlLine / StarLine)
StarLine =      "****" '*'* / Spacechar '*'+ &Spacechar
UlLine   =      "____" '_'* / Spacechar '_'+ &Spacechar

Emph =      ( EmphStar / EmphUl )
            { d.add(d.elem_cn(t.pmd_EMPH,_chunk,1)) }

OneStarOpen  =  !StarLine '*' !Spacechar !Newline
OneStarClose =  !Spacechar !Newline Inline !StrongStar '*'

EmphStar =  OneStarOpen
            ( !OneStarClose Inline )*
            OneStarClose

OneUlOpen  =  !UlLine '_' !Spacechar !Newline
OneUlClose =  !Spacechar !Newline Inline !StrongUl '_' !Alphanumeric

EmphUl =    OneUlOpen
            ( !OneUlClose Inline )*
            OneUlClose

Strong = ( StrongStar / StrongUl )
         { d.add(d.elem_cn(t.pmd_STRONG,_chunk,2)) }

TwoStarOpen =   !StarLine "**" !Spacechar !Newline
TwoStarClose =  !Spacechar !Newline Inline "**"

StrongStar =    TwoStarOpen
                ( !TwoStarClose Inline )*
                TwoStarClose

TwoUlOpen =     !UlLine "__" !Spacechar !Newline
TwoUlClose =    !Spacechar !Newline Inline "__" !Alphanumeric

StrongUl =  TwoUlOpen
            ( !TwoUlClose Inline )*
            TwoUlClose

Image = "!" lnk:( ExplicitLink / ReferenceLink )
        { d.add(d.elem_cz(t.pmd_IMAGE,_chunk),lnk); }

Link =  ( ExplicitLink / ReferenceLink / AutoLink )

ReferenceLink = ReferenceLinkDouble / ReferenceLinkSingle

ReferenceLinkDouble =  txt:Label Spnl !"[]" lbl:Label {
                          var lnk_elem = d.elem_ct(t.pmd_LINK,_chunk,txt);
                          d.wait_ref( lbl, function (ref) {
                              d.add( lnk_elem,
                                 { 'label': lbl,
                                   'text': txt,
                                   'title': (ref ? ref.data.title : null),
                                   'source': (ref ? ref.data.source : null) });
                          });
                          return lnk_elem;
                       }

ReferenceLinkSingle =  txt:Label (Spnl "[]")? {
                          var lnk_elem = d.elem_ct(t.pmd_LINK,_chunk,txt);
                          d.wait_ref( txt, function (ref) {
                              d.add( lnk_elem,
                                  { 'label': txt,
                                    'text': txt,
                                    'title': (ref ? ref.data.title : null),
                                    'source': (ref ? ref.data.source : null) });
                          });
                          return lnk_elem;
                       }

ExplicitLink = txt:Label Spnl '(' Sp src:Source Spnl ttl:Title Sp ')' {
                    var lnk_elem = d.elem_ct(t.pmd_LINK,_chunk,txt);
                    d.add( lnk_elem, { 'label': null,
                                       'text': txt,
                                       'title': ttl,
                                       'source': src });
                    return lnk_elem;
                }

Source  = ( '<' txt:( SourceContents ) '>' )
          / txt:( SourceContents ) { return txt }

SourceContents = ( ( !'(' !')' !'>' Nonspacechar )+ / '(' SourceContents ')' )* { return _chunk.match }

Title = title:( TitleSingle / TitleDouble / ("" { return '' } ) ) { return title }

TitleSingle = '\'' title:( ( !( '\'' Sp ( ')' / Newline ) ) . )* { return _chunk.match } ) '\'' { return title }

TitleDouble = '"' title:( ( !( '"' Sp ( ')' / Newline ) ) . )* { return _chunk.match } ) '"' { return title }

AutoLink = AutoLinkUrl / AutoLinkEmail

AutoLinkUrl =  '<' src:( [A-Za-z]+ "://" ( !Newline !'>' . )+ { return _chunk.match } ) '>' {
                   d.add(d.elem_ct(t.pmd_AUTO_LINK_URL,_chunk,src));
                   return { 'src': src }
               }

AutoLinkEmail = '<' src:( [-A-Za-z0-9+_.]+ '@' ( !Newline !'>' . )+ { return _chunk.match } ) '>' {
                   d.add(d.elem_cz(t.pmd_AUTO_LINK_URL,_chunk,src));
                   return { 'src': src }
               }

Reference = NonindentSpace !"[]" lbl:Label ':' Spnl src:RefSrc ttl:RefTitle BlankLine+ {
                var el = d.elem_cz(t.pmd_REFERENCE,_chunk);
                d.add(el,{ 'label': lbl, 'source': src, 'title': ttl });
                d.save_ref(lbl,el);
                return t.pmd_REFERENCE;
            }

//Label = '[' ( !'^' &{ d.ext(e.pmd_EXT_FOOTNOTES) } / &. &{ !d.ext(e.pmd_EXT_FOOTNOTES) } )
Label = '[' !'^'
        txt:( ( !']' Inline )* { return _chunk.match } )
        ']'
        { return txt }

RefSrc = Nonspacechar+ { return _chunk.match }

RefTitle =  ( RefTitleSingle / RefTitleDouble / RefTitleParens / EmptyTitle )

EmptyTitle = "" { return '' }

RefTitleSingle = Spnl '\'' title:( ( !('\'' Sp Newline / Newline ) . )* { return _chunk.match } ) '\'' { return title }

RefTitleDouble = Spnl '"' title:( ( !('"' Sp Newline / Newline) . )* { return _chunk.match } ) '"' { return title }

RefTitleParens = Spnl '(' title:( ( !(')' Sp Newline / Newline) . )* { return _chunk.match } ) ')' { return title }

// Starting point for parsing only references:
References = ( Reference / SkipBlock )*

Ticks1 = "`" !'`' { return 1 }
Ticks2 = "``" !'`' { return 2 }
Ticks3 = "```" !'`' { return 3 }
Ticks4 = "````" !'`' { return 4 }
Ticks5 = "`````" !'`' { return 5 }

Code = cnt:(
         ( s:Ticks1 Sp ( ( !'`' Nonspacechar )+ / !Ticks1 '`'+ / !( Sp Ticks1 ) ( Spacechar / Newline !BlankLine ) )+ Sp Ticks1 ) { return s }
       / ( s:Ticks2 Sp ( ( !'`' Nonspacechar )+ / !Ticks2 '`'+ / !( Sp Ticks2 ) ( Spacechar / Newline !BlankLine ) )+ Sp Ticks2 ) { return s }
       / ( s:Ticks3 Sp ( ( !'`' Nonspacechar )+ / !Ticks3 '`'+ / !( Sp Ticks3 ) ( Spacechar / Newline !BlankLine ) )+ Sp Ticks3 ) { return s }
       / ( s:Ticks4 Sp ( ( !'`' Nonspacechar )+ / !Ticks4 '`'+ / !( Sp Ticks4 ) ( Spacechar / Newline !BlankLine ) )+ Sp Ticks4 ) { return s }
       / ( s:Ticks5 Sp ( ( !'`' Nonspacechar )+ / !Ticks5 '`'+ / !( Sp Ticks5 ) ( Spacechar / Newline !BlankLine ) )+ Sp Ticks5 ) { return s }
       )
       { d.add(d.elem_cn(t.pmd_CODE,_chunk,cnt)); }

RawHtml =   (HtmlComment / HtmlBlockScript / HtmlTag)

BlankLine =     Sp Newline

Quoted =        '"' (!'"' .)* '"' / '\'' (!'\'' .)* '\''
HtmlAttribute = (AlphanumericAscii / '-')+ Spnl ('=' Spnl (Quoted / (!'>' Nonspacechar)+))? Spnl
HtmlComment =   "<!--" (!"-->" .)* "-->"
                { d.add(d.elem_cz(t.pmd_COMMENT,_chunk)) }
HtmlTag =       '<' Spnl '/'? AlphanumericAscii+ Spnl HtmlAttribute* '/'? Spnl '>'
Eof =           !.
Spacechar =     ' ' / '\t'
Nonspacechar =  !Spacechar !Newline .
Newline =       '\n' / '\r' '\n'?
Sp =            Spacechar*
Spnl =          Sp (Newline Sp)?
SpecialChar =   '*' / '_' / '`' / '&' / '[' / ']' / '(' / ')' / '<' / '!' / '#' / '\\' / '\'' / '"' / ExtendedSpecialChar
NormalChar =    !( SpecialChar / Spacechar / Newline ) .
// Not used anywhere in grammar:
// NonAlphanumeric = [\000-\057\072-\100\133-\140\173-\177]
// TODO: check if that numbers fit
Alphanumeric = [0-9A-Za-z] / "\\200" / "\\201" / "\\202" / "\\203" / "\\204" / "\\205" / "\\206" / "\\207" / "\\210" / "\\211" / "\\212" / "\\213" / "\\214" / "\\215" / "\\216" / "\\217" / "\\220" / "\\221" / "\\222" / "\\223" / "\\224" / "\\225" / "\\226" / "\\227" / "\\230" / "\\231" / "\\232" / "\\233" / "\\234" / "\\235" / "\\236" / "\\237" / "\\240" / "\\241" / "\\242" / "\\243" / "\\244" / "\\245" / "\\246" / "\\247" / "\\250" / "\\251" / "\\252" / "\\253" / "\\254" / "\\255" / "\\256" / "\\257" / "\\260" / "\\261" / "\\262" / "\\263" / "\\264" / "\\265" / "\\266" / "\\267" / "\\270" / "\\271" / "\\272" / "\\273" / "\\274" / "\\275" / "\\276" / "\\277" / "\\300" / "\\301" / "\\302" / "\\303" / "\\304" / "\\305" / "\\306" / "\\307" / "\\310" / "\\311" / "\\312" / "\\313" / "\\314" / "\\315" / "\\316" / "\\317" / "\\320" / "\\321" / "\\322" / "\\323" / "\\324" / "\\325" / "\\326" / "\\327" / "\\330" / "\\331" / "\\332" / "\\333" / "\\334" / "\\335" / "\\336" / "\\337" / "\\340" / "\\341" / "\\342" / "\\343" / "\\344" / "\\345" / "\\346" / "\\347" / "\\350" / "\\351" / "\\352" / "\\353" / "\\354" / "\\355" / "\\356" / "\\357" / "\\360" / "\\361" / "\\362" / "\\363" / "\\364" / "\\365" / "\\366" / "\\367" / "\\370" / "\\371" / "\\372" / "\\373" / "\\374" / "\\375" / "\\376" / "\\377"
AlphanumericAscii = [A-Za-z0-9]

HexEntity =     '&' '#' [Xx] [0-9a-fA-F]+ ';'
DecEntity =     '&' '#' [0-9]+ ';'
CharEntity =    '&' [A-Za-z0-9]+ ';'

NonindentSpace =    "   " / "  " / " " / ""
Indent =            "\t" / "    "
Indents =           ind:Indent+ { return ind.length; }
AnyIndent =         ind:Indent* { return ind.length; }
IndentedLine =      Indent txt:Line { return txt }
OptionallyIndentedLine = Indent? txt:Line { return txt }

// Not used anywhere in grammar:
// StartList = &.

Line =  RawLine { return _chunk.match }

RawLine = ( (!'\r' !'\n' .)* Newline / .+ Eof )

SkipBlock = ( !BlankLine RawLine )+ BlankLine*
          / BlankLine+

// Syntax extensions

ExtendedSpecialChar = &{ d.ext(e.pmd_EXT_FOOTNOTES) } ( '^' )

NoteReference = &{ d.ext(e.pmd_EXT_FOOTNOTES) }
                RawNoteReference

RawNoteReference = "[^" ( !Newline !']' . )+ ']'

Note =          &{ d.ext(e.pmd_EXT_FOOTNOTES) }
                NonindentSpace RawNoteReference ':' Sp
                ( RawNoteBlock )
                ( &Indent RawNoteBlock )* {
                    return t.pmd_NOTE;
                }

InlineNote =    &{ d.ext(e.pmd_EXT_FOOTNOTES) }
                "^["
                ( !']' Inline )+
                ']'

// Not used anywhere in grammar:
// Notes =         ( Note / SkipBlock )*

RawNoteBlock =  ( !BlankLine OptionallyIndentedLine )+
                ( BlankLine* )

