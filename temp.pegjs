start = idn:indent &{ console.log(idn); return true; } w:words nl? { console.log(w); }

indent = ("    " / "\t") { return _chunk.match.length; }

words = w:( [a-z]+ / [A-Z]+ ) { return w.join(''); }

nl = "\n"

