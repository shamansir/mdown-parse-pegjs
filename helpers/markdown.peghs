{-# OPTIONS_GHC -fglasgow-exts #-}

{- Markdown.hs - Haskell implementation of markdown using PEG grammar.
   (c) 2008 John MacFarlane
   Released under the GPL
-}

import Text.Parsers.Frisby
import Text.Parsers.Frisby.Char
import Text.Pandoc.XML
import Data.Char (toUpper)
import Text.PrettyPrint.HughesPJ hiding (text, char, (<>), empty)
import qualified Text.PrettyPrint.HughesPJ as P (text, char, (<>), empty)
import System.Environment

-- Uncomment the following two lines for UTF8 support (requires utf8-string library):
-- import System.IO.UTF8
-- import Prelude hiding (getContents, putStrLn, readFile)

main :: IO ()
main = do
  argv <- getArgs
  c <- if null argv
          then getContents
          else mapM readFile argv >>= return . unlines
  let (blocks, remaining) = runPeg doc $ tabFilter tabStop (c ++ "\n")
  if (not . null) remaining
     then error $ "Parse failed at:  " ++ take 35 remaining
     else do
       -- extract link references first, then convert to HTML
       let refs = map (\(Reference l (Src (s,t))) -> (l, (s,t))) $ filter isReference blocks 
       putStrLn $ render $ vcat $ map (blockToHtml refs) blocks

-- | A link target:  a URL and title, or a reference, or nothing.
data Target = Src (String, String)  -- ^ (URL, title)
            | Ref [Inline] String   -- ^ the string contains spaces before the reference: e.g. " " in "[label] [ref]"
            | Null                  -- ^ this is used for shortcut references:  "[label]"
            deriving (Show, Read, Eq)

-- | An inline (span-level) element.
data Inline =
    Text String
  | Entity String           -- ^ an entity reference without the '&' and ';'
  | Space
  | LineBreak
  | Emph [Inline]
  | Strong [Inline]
  | Code String
  | Link [Inline] Target
  | Image [Inline] Target
  | Html String             -- ^ raw HTML
  deriving (Show, Read, Eq)

-- | A block element.
data Block =
    Para [Inline]
  | Plain [Inline]
  | Heading Int [Inline]
  | BlockQuote [Block]
  | BulletList [[Block]]
  | OrderedList [[Block]]
  | HtmlBlock String
  | Verbatim String 
  | HorizontalRule
  | Reference [Inline] Target  -- ^ a link reference:  e.g. [label]: /url "title"
  | Markdown String            -- ^ unprocessed markdown, to be parsed into blocks
  deriving (Show, Read, Eq)

{- Reading the grammar:

   Standard PEG   Frisby
   ------------   -----------------------
   A*             many A
   A+             many1 A
   A?             optional A (returns () if no match)
                  option B A (same thing but returns B if no match)
   !A             doesNotMatch A
   &A             peek A
   A / B          A // B
   [abc]          oneOf "abc"
   [^abc]         noneOf "abc"
   'a'            char 'a'
   "abc"          text "abc"
   A B            A <> B     -- parses A, then B, and returns a pair (A, B)
                  A ->> B    -- parses A, then B, and returns A
                  A <<- B    -- parses A, then B, and returns B
                  A <++> B   -- parses A, then B, and returns concatenation of A and B
   eof            eof
   A <- B         A <- newRule $ B

   Other Frisby peculiarities:

   X ## f     -- parses X and passes the result through function f
   X ##> a    -- parses X and returns constant a

-}

-- | The PEG grammar definition for Markdown.
doc :: forall s . PM s (P s ([Block], String))
doc = mdo

  -- characters and tokens
  spaceChar   <- newRule $ oneOf " \t"
  newline     <- newRule $ text "\n"
  sp          <- newRule $ many spaceChar
  spnl        <- newRule $ sp <++> option "" (newline <++> sp)
  specialChar <- newRule $ oneOf "*_`&[]<!\\"
  normalChar  <- newRule $ escapedChar // (doesNotMatch (specialChar // spaceChar) ->> doesNotMatch newline ->> anyChar)
  escapedChar <- newRule $ char '\\' ->> anyChar

  -- strings
  nonindentSpace <- newRule $ option "" (text "   " // text "  " // text " ")
  indent         <- newRule $ text "\t" // text "    "
  indentedLine   <- newRule $ indent ->> anyline
  optionallyIndentedLine <- newRule $ indent ->> anyline
  anyline        <- newRule $ many (doesNotMatch newline ->> doesNotMatch eof ->> anyChar) <++> option "" newline
  blankline      <- newRule $ sp <++> newline
  blockquoteLine <- newRule $ nonindentSpace ->> char '>' ->> optional (char ' ') ->> anyline
  quoted         <- newRule $ (text "\"" <++> many (noneOf "\"") <++> text "\"") // 
                              (text "'"  <++> many (noneOf "'") <++>  text "'")
  htmlAttribute  <- newRule $ many1 alphaNum <++> spnl <++> option "" (text "=" <++> spnl <++> 
                                (quoted // many1 (doesNotMatch spaces ->> anyChar))) <++> spnl
  htmlComment    <- newRule $ text "<!--" <++> many (doesNotMatch (text "-->") ->> anyChar) <++> text "-->"
  htmlTag        <- newRule $ text "<" <++> spnl <++> option "" (text "/") <++> many1 alphaNum <++>
                              spnl <++> (many htmlAttribute ## concat) <++> option "" (text "/") <++> text ">"

  -- inlines 
  inline      <- newRule $ strong // emph // code // endline // spaces // link // image // autolink //
                      rawHtml // str // entity // special

  emph        <- newRule $ emphStar // emphUl
  oneStar     <- newRule $ char '*' <<- doesNotMatch oneStar
  emphStar    <- newRule $ oneStar ->> doesNotMatch spaceChar ->> doesNotMatch newline ->>
                           many1 (strong // (doesNotMatch (spnl ->> oneStar) ->> inline)) <<- oneStar ## Emph
  oneUl       <- newRule $ char '_' <<- doesNotMatch oneUl
  emphUl      <- newRule $ oneUl ->> doesNotMatch spaceChar ->> doesNotMatch newline ->>
                           many1 (strong // (doesNotMatch (spnl ->> oneUl) ->> inline)) <<- oneUl <<-
                           doesNotMatch alphaNum ## Emph

  strong      <- newRule $ strongStar // strongUl
  twoStar     <- newRule $ text "**" <<- doesNotMatch twoStar
  twoUl       <- newRule $ text "__" <<- doesNotMatch twoStar
  strongStar  <- newRule $ twoStar ->> doesNotMatch spaceChar ->> doesNotMatch newline ->>
                           many1 (doesNotMatch (spnl ->> twoStar) ->> inline) <<- twoStar ## Strong
  strongUl    <- newRule $ twoUl ->> doesNotMatch spaceChar ->> doesNotMatch newline ->>
                           many1 (doesNotMatch (spnl ->> twoUl) ->> inline) <<- twoUl <<-
                           doesNotMatch alphaNum ## Strong
  
  let ticks n        = text (replicate n '`') <<- doesNotMatch (char '`')
  let betweenTicks n = ticks n ->> many1 (many1 (noneOf "`") // doesNotMatch (ticks n) ->> many1 (char '`')) <<- 
                         ticks n ## lrstrip ' ' . concat
  code        <- newRule $ peek (char '`') ->> choice (map betweenTicks $ reverse [1..10]) ## Code

  rawHtml     <- newRule $ (htmlComment // htmlTag) ## Html

  str         <- newRule $ many1 normalChar ## Text
  special     <- newRule $ specialChar ## Text . (: [])
  spaces      <- newRule $ many1 spaceChar ##> Space
  endline     <- newRule $ optional (text " ") <> newline <> doesNotMatch blankline <> doesNotMatch eof ##> Space 
  linebreak   <- newRule $ text "  " ->> sp ->> endline ##> LineBreak
  entity      <- newRule $ char '&' ->> (text "#" <++> (text "x" // text "X") <++> many1 hexDigit // 
                             text "#" <++> many1 digit // many1 alphaNum) <<- char ';' ## Entity 

  label          <- newRule $ char '[' ->> many (doesNotMatch (char ']') ->> inline) <<- char ']'
  title          <- newRule $ char '"' ->> many (doesNotMatch (char '"' <> sp <> (text ")" // newline)) ->>
                               doesNotMatch newline ->> anyChar) <<- char '"' //
                               char '\'' ->> many (doesNotMatch (char '\'' <> sp <> (text ")" // newline)) ->>
                               doesNotMatch newline ->> anyChar) <<- char '\''
  source         <- newRule $ char '<' ->> source' <<- char '>' // source'
  source'        <- newRule $ many (many1 (noneOf "()> \n\t") // (text "(" <++> source' <++> text ")") //
                                      (text "<" <++> source' <++> text ">")) ## concat
  sourceAndTitle <- newRule $ char '(' ->> sp ->> source <<- spnl <> option "" title <<- sp <<- char ')'
  explicitLink   <- newRule $ label <> spnl ->> sourceAndTitle ## (\(l, s) -> Link l (Src s))
  autolinkUrl    <- newRule $ char '<' ->> many1 alpha <++> text "://" <++> 
                              many1 (doesNotMatch newline ->> doesNotMatch (char '>') ->> anyChar) <<- char '>' ##
                              (\s -> Link [Text s] (Src (s, "")))
  autolinkEmail  <- newRule $ char '<' ->> many1 alpha <++> text "@" <++> 
                              many1 (doesNotMatch newline ->> doesNotMatch (char '>') ->> anyChar) <<- char '>' ##
                              (\s -> Link [Text s] (Src ("mailto:" ++ s, "")))
  autolink       <- newRule $ autolinkUrl // autolinkEmail
  referenceLink  <- newRule $ label <> spnl <> label ## (\((l1,s), l2) -> Link l1 (Ref l2 s)) //
                             label ## (\l -> Link l Null)

  link   <- newRule $ explicitLink // referenceLink 
  image  <- newRule $ char '!' ->> link ## (\(Link x y) -> Image x y)

  -- blocks
  block      <- newRule $ blockquote // verbatim // reference // htmlBlock // heading // list // horizontalRule // 
                            para // plain
  para       <- newRule $ many1 inline <<- newline <<- many1 blankline ## Para
  plain      <- newRule $ many1 inline <<- optional blankline ## Plain
  blockquote <- newRule $ many1 (many1 blockquoteLine <++> many (doesNotMatch blankline ->> anyline) <++>
                                 many blankline ## concat) ## (\ls -> BlockQuote [Markdown $ concat ls ++ "\n"])
  
  let setextHeadingWith lev c = many1 (doesNotMatch endline ->> inline) <<- newline <<-
                                text (replicate 3 c) <<- (many (char c)) <<- newline ## Heading lev
  setextHeading <- newRule $ setextHeadingWith 1 '=' // setextHeadingWith 2 '-'

  let atxHeadingFor lev = text (replicate lev '#') ->> 
                          many1 (doesNotMatch endline ->> doesNotMatch (char '#') ->> inline) <<-
                          many (oneOf "# \t") <<- newline ## Heading lev
  atxHeading    <- newRule $ choice $ map atxHeadingFor [6, 5..1]

  heading       <- newRule $ (atxHeading // setextHeading) <<- many blankline

  let horizontalRuleWith c = nonindentSpace ->> char c ->> sp ->> char c ->> sp ->> char c ->> 
                             many (sp ->> char c) ->> sp ->> newline ->> many1 blankline ##> HorizontalRule
  horizontalRule <- newRule $ choice $ map horizontalRuleWith ['*', '_', '-']

  verbatim       <- newRule $ many1 (doesNotMatch blankline ->> indentedLine) <++> 
                              (many (many1 (optional indent ->> blankline) <++> 
                              many1 (doesNotMatch blankline ->> indentedLine)) ## concat) <<- 
                              many blankline ## Verbatim . concat

  list             <- newRule $ bulletList // orderedList

  bullet           <- newRule $ nonindentSpace ->> oneOf "+*-" <<- many1 spaceChar ## (: [])
  bulletList       <- newRule $ bulletListTight // bulletListLoose
  bulletListTight  <- newRule $ many1 (bulletListItem ## (\s -> [Markdown s])) <<- many blankline <<- 
                                 doesNotMatch bulletListLoose ## BulletList
  bulletListLoose  <- newRule $ many1 ((bulletListItem <<- many blankline) ## (\s -> [Markdown $ s ++ "\n\n"])) ## 
                                 BulletList
  bulletListItem   <- newRule $ doesNotMatch horizontalRule ->> bullet ->> 
                                  listBlock <++> (many listContinuationBlock ## concat)
  listBlock        <- newRule $ anyline <++> (many (doesNotMatch (optional indent ->> (bulletListItem // orderedListItem))
                                    ->> doesNotMatch blankline ->> doesNotMatch (indent ->> (bullet // enumerator)) ->>
                                    optionallyIndentedLine) ## concat)
  listContinuationBlock <- newRule $ ((many1 blankline ## concat) // unit "\0") <++>
                                     (many1 (indent ->> listBlock) ## concat)

  enumerator       <- newRule $ nonindentSpace ->> many1 digit <<- char '.' <<- many1 spaceChar
  orderedList      <- newRule $ orderedListTight // orderedListLoose
  orderedListTight <- newRule $ many1 (orderedListItem ## (\s -> [Markdown s])) <<- many blankline <<- 
                                doesNotMatch orderedListLoose ## OrderedList
  orderedListLoose <- newRule $ many1 ((orderedListItem <<- many blankline) ## (\s -> [Markdown $ s ++ "\n\n"])) ## 
                                OrderedList
  orderedListItem  <- newRule $ enumerator ->> listBlock <++> (many listContinuationBlock ## concat)


  let htmlBlockOpening tag = text "<" <++> spnl <++> text tag <++> spnl <++> (many htmlAttribute ## concat)
  let htmlBlockSolo    tag = htmlBlockOpening tag <++> text "/" <++> spnl <++> text ">"
  let htmlBlockWithEnd tag = htmlBlockOpening tag <++> text ">" <++> 
                             (many (doesNotMatch (htmlBlockEndFor tag) ->>
                                   (htmlBlockAny // many1 (noneOf "<") // text "<")) ## concat) <++>
                             htmlBlockEndFor tag
  let htmlBlockEndFor  tag = text "<" <++> spnl <++> text "/" <++> text tag <++> spnl <++> text ">"
  let htmlBlockFor     tag = htmlBlockSolo tag // htmlBlockWithEnd tag
  let blockTags            = ["address", "blockquote", "center", "dir", "div", "dl", "fieldset", "form", "h1", "h2", "h3",
                              "h4", "h5", "h6", "hr", "isindex", "menu", "noframes", "noscript", "ol", "p", "pre", "table",
                              "ul", "dd", "dt", "frameset", "li", "tbody", "td", "tfoot", "th", "thead", "tr", "script"]

  htmlBlockAny   <- newRule $ choice $ map htmlBlockFor (blockTags ++ map (map toUpper) blockTags)
  htmlBlock      <- newRule $ nonindentSpace <++> (htmlComment // htmlBlockAny) ## HtmlBlock

  -- references
  reference      <- newRule $ nonindentSpace ->> label <> char ':' ->> spnl ->> 
                                many1 (doesNotMatch spaceChar ->> doesNotMatch newline ->> anyChar) <> 
                                spnl ->> option "" title <<- many blankline ## (\((l,s),t) -> Reference l (Src (s,t)))

  -- document - returns (block list, unparsed text)
  document       <- newRule $ (many (many blankline ->> block) <<- many blankline) <> rest <<- eof
  return document

--
-- Convert inlines and blocks to HTML
--

-- | Convert inline element to HTML.
inlineToHtml :: [([Inline],(String, String))]  -- ^ list of link references
             -> Inline                         -- ^ inline element
             -> Doc
inlineToHtml refs i = 
  case i of
    Text s              -> P.text (escapeStringForXML s)
    Entity s            -> P.char '&' P.<> P.text s P.<> P.char ';'
    Space               -> P.char ' '
    LineBreak           -> selfClosingTag "br" []
    Code s              -> inTagsSimple "code" $ P.text $ escapeStringForXML s
    Emph xs             -> inTagsSimple "em" $ hcat $ map (inlineToHtml refs) xs
    Strong xs           -> inTagsSimple "strong" $ hcat $ map (inlineToHtml refs) xs
    Html s              -> P.text s
    -- an autolink <http://google.com> or [explicit link](google.com) with no title
    Link l (Src (u,"")) -> inTags False "a" [("href", u)] $ hcat $ map (inlineToHtml refs) l
    -- an explicit link with a title:  [like this](google.com "title")
    Link l (Src (u,t))  -> inTags False "a" [("href", u), ("title", t)] $ hcat $ map (inlineToHtml refs) l 
    -- a shortcut-style reference link:  [like this]
    Link l Null         -> case lookup l refs of
                                Just (u, "") -> inTags False "a" [("href", u)] $ hcat $ map (inlineToHtml refs) l 
                                Just (u, t) -> inTags False "a" [("href", u), ("title", t)] $ hcat $ 
                                                 map (inlineToHtml refs) l 
                                Nothing     -> hcat $ map (inlineToHtml refs) $ [Text "["] ++ l ++ [Text "]"]
    -- a regular reference link: [like][this] or [like] [this]
    Link l (Ref r s)    -> let r' = if null r then l else r 
                           in  case lookup r' refs of
                                 Just (u, "") -> inTags False "a" [("href", u)] $ hcat $ map (inlineToHtml refs) l 
                                 Just (u, t)  -> inTags False "a" [("href", u), ("title", t)] $ hcat $
                                                  map (inlineToHtml refs) l 
                                 Nothing      -> hcat $ map (inlineToHtml refs) $ [Text "["] ++ l ++ 
                                                          [Text $ "]" ++ s ++ "["] ++ r ++ [Text "]"]
    Image l (Src (u,t)) -> selfClosingTag "img" [("src", u), ("title", t), 
                                  ("alt", render $ hcat $ map (inlineToHtml refs) l)]
    -- a shortcut-style reference link:  ![like this]
    Image l Null        -> case lookup l refs of
                                Just (u, t) -> inlineToHtml refs $ Image l (Src (u,t))
                                Nothing     -> hcat $ map (inlineToHtml refs) $ [Text "!["] ++ l ++ [Text "]"]
    -- a regular reference link: ![like][this] or ![like] [this]
    Image l (Ref r s)   -> let r' = if null r then l else r 
                           in  case lookup r' refs of
                                 Just (u, t) -> inlineToHtml refs $ Image l (Src (u, t))
                                 Nothing     -> hcat $ map (inlineToHtml refs) $ [Text "!["] ++ l ++ 
                                                          [Text $ "]" ++ s ++ "["] ++ r ++ [Text "]"]

-- | Convert block element to HTML.
blockToHtml :: [([Inline],(String, String))]  -- ^ list of link references
            -> Block                          -- ^ block element to convert
            -> Doc
blockToHtml refs block =
  case block of
    Para xs           -> inTagsSimple "p" $ wrap refs $ lrstrip Space xs
    Plain xs          -> wrap refs $ lrstrip Space xs
    Heading lev xs    -> inTagsSimple ("h" ++ show lev) $ hcat $ map (inlineToHtml refs) $ lrstrip Space xs
    HorizontalRule    -> selfClosingTag "hr" []
    BlockQuote xs     -> inTagsIndented "blockquote" $ vcat $ map (blockToHtml refs) xs
    Verbatim s        -> inTagsSimple "pre" $ inTagsSimple "code" $ P.text $ escapeStringForXML s
    BulletList items  -> inTagsIndented "ul" $ vcat $ 
                           map (\item -> inTagsSimple "li" $ vcat $ map (blockToHtml refs) item) items 
    OrderedList items -> inTagsIndented "ol" $ vcat $
                           map (\item -> inTagsSimple "li" $ vcat $ map (blockToHtml refs) item) items 
    Markdown s        -> -- handle a raw chunk of markdown, e.g. a list item or block quote contents
                         -- if the chunk contains \0, it is split at that point into two chunks that
                         -- are parsed separately.  This allows correct handling of lists like:
                         -- - item
                         --     - sub
                         --     - sub
                         let (a, b) = break (=='\0') s
                             (parsed, remaining) = runPeg doc a
                             first = vcat $ map (blockToHtml refs) parsed 
                         in  if null remaining
                                then if null b
                                        then first
                                        else first $$ blockToHtml refs (Markdown $ tail b)
                                else error $ "Parse failed at:  " ++ take 35 remaining
    Reference _ _     -> P.empty
    HtmlBlock s       -> P.text s

--
-- Wrapping code and other utilities from pandoc
--

-- | Take list of inline elements and return wrapped doc.
wrap :: [([Inline],(String, String))] -> [Inline] -> Doc
wrap refs lst = fsep $ map (hcat . map (inlineToHtml refs)) (splitBy Space lst)

-- | Split list by groups of one or more sep.
splitBy :: (Eq a) => a -> [a] -> [[a]]
splitBy _ [] = []
splitBy s lst =
  let (x, xs) = break (== s) lst
      xs'     = dropWhile (== s) xs
  in  x:(splitBy s xs')

-- | Strip leading and trailing elements.
lrstrip :: (Eq a) => a -> [a] -> [a]
lrstrip x = reverse . dropWhile (== x) . reverse . dropWhile (== x)

tabStop :: Int
tabStop = 4

tabFilter :: Int -> String -> String
tabFilter _ [] = ""
tabFilter _ ('\r':'\n':xs) = '\n' : tabFilter tabStop xs
tabFilter _ ('\r':xs) = '\n' : tabFilter tabStop xs
tabFilter _ ('\n':xs) = '\n' : tabFilter tabStop xs 
tabFilter spsToNextStop ('\t':xs) = replicate spsToNextStop ' ' ++ tabFilter tabStop xs 
tabFilter 1 (x:xs) = x:(tabFilter tabStop xs)
tabFilter spsToNextStop (x:xs) = x:(tabFilter (spsToNextStop - 1) xs)

isReference :: Block -> Bool
isReference (Reference _ _) = True
isReference _ = False
