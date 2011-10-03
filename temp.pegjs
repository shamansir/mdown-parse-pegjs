start = idn:(indent) &{ console.log(idn); return true; } words nl

indent = "    " / "\t"

words = w:( [a-z]+ / [A-Z]+ ) { return w.join(''); }

nl = "\n"

