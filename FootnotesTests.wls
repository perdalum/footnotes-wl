Get["/Users/au15929/src/footnotes-wl/Footnotes.wl"];

ClearAll[check, checkFailure];
$failures = 0;
check[name_, actual_, expected_] := If[actual === expected,
    Print["PASS: ", name],
    $failures++; Print["FAIL: ", name, "\n  got:  ", InputForm[actual], "\n  want: ", InputForm[expected]]
];
checkFailure[name_, actual_, kind_] := If[MatchQ[actual, Failure[kind, _Association]],
    Print["PASS: ", name],
    $failures++; Print["FAIL: ", name, "\n  got: ", InputForm[actual], "\n  want Failure[", kind, ", ...]"]
];

R = Footnotes`FootnoteRender;
U = Footnotes`FootnoteUnrender;

check["render no footnotes",
    R["Plain text without markers."],
    "Plain text without markers."
];

check["render one source footnote with optional marker spacing",
    R["Wikipedia \:0192(https://wikipedia.org) is mentioned."],
    "Wikipedia\:00b9 is mentioned.\n\n---\n1) https://wikipedia.org"
];

check["render multiple source footnotes in encounter order",
    R["A\:0192(first) B\:0192(second) C\:0192(third)"],
    "A\:00b9 B\:00b2 C\:00b3\n\n---\n1) first\n2) second\n3) third"
];

check["render collapses whitespace before the marker",
    R["word \:0192(note) end"],
    "word\:00b9 end\n\n---\n1) note"
];

check["render collapses tab before the marker",
    R["word\t\:0192(note) end"],
    "word\:00b9 end\n\n---\n1) note"
];

check["render does not collapse across line breaks",
    R["word \n \:0192(note) end"],
    "word \n \:00b9 end\n\n---\n1) note"
];

check["render trims footnote text in the block",
    R["word\:0192(  note with spaces  )"],
    "word\:00b9\n\n---\n1) note with spaces"
];

check["render supports balanced parentheses inside footnote text",
    R["See this\:0192(RFC 3986 (URLs))."],
    "See this\:00b9.\n\n---\n1) RFC 3986 (URLs)"
];

check["render superscript references above 9",
    R["\:0192(n1) \:0192(n2) \:0192(n3) \:0192(n4) \:0192(n5) \:0192(n6) \:0192(n7) \:0192(n8) \:0192(n9) \:0192(n10)"],
    "\:00b9 \:00b2 \:00b3 \:2074 \:2075 \:2076 \:2077 \:2078 \:2079 \:00b9\:2070\n\n---\n1) n1\n2) n2\n3) n3\n4) n4\n5) n5\n6) n6\n7) n7\n8) n8\n9) n9\n10) n10"
];

check["render trims transformed body trailing whitespace before block",
    R["word\:0192(note)   "],
    "word\:00b9\n\n---\n1) note"
];

check["reverse rendered footnotes",
    U["When I was a child\:00b9, I loved sci-fi and the first tv-show, that I remember, is Space: 1999\:00b2, that aired on the Danish National Broadcast Service\:00b3.\n\n---\n1) born in 1968\n2) https://en.wikipedia.org/wiki/Space:_1999\n3) DR, https://dr.dk, and https://lex.dk/DR"],
    "When I was a child \:0192(born in 1968), I loved sci-fi and the first tv-show, that I remember, is Space: 1999 \:0192(https://en.wikipedia.org/wiki/Space:_1999), that aired on the Danish National Broadcast Service \:0192(DR, https://dr.dk, and https://lex.dk/DR)."
];

check["reverse inserts marker spacing",
    U["word\:00b9.\n\n---\n1) note"],
    "word \:0192(note)."
];

check["reverse preserves existing marker spacing",
    U["word \:00b9.\n\n---\n1) note"],
    "word \:0192(note)."
];

check["reverse ignores existing source annotations",
    U["A\:00b9 and B\:0192(new source note).\n\n---\n1) old rendered note"],
    "A \:0192(old rendered note) and B\:0192(new source note)."
];

check["render mixed input normalizes to one block",
    R["A\:00b9 and B\:0192(new source note).\n\n---\n1) old rendered note"],
    "A\:00b9 and B\:00b2.\n\n---\n1) old rendered note\n2) new source note"
];

check["reverse without rendered footnote block is unchanged",
    U["A\:0192(source note) and plain text."],
    "A\:0192(source note) and plain text."
];

checkFailure["render unclosed source marker fails", R["word\:0192(note"], "UnclosedSourceMarker"];
checkFailure["render source marker interrupted by newline fails", R["word\:0192(note\nstill note)"], "NewlineInSourceNote"];
checkFailure["render empty source footnote fails", R["word\:0192()"], "EmptySourceNote"];
checkFailure["render whitespace-only source footnote fails", R["word\:0192(   )"], "EmptySourceNote"];
checkFailure["reverse malformed rendered block fails", U["A\:00b9.\n\n---\n2) starts at two"], "MalformedRenderedBlock"];
checkFailure["render errors on non-footnote after final separator", R["A\:0192(note)\n\n---\nnot a footnote block"], "MalformedRenderedBlock"];
checkFailure["reverse errors on bare final separator", U["A\:00b9\n\n---"], "MalformedRenderedBlock"];
checkFailure["duplicate reference fails", U["A\:00b9 and again\:00b9.\n\n---\n1) note"], "MalformedRenderedBlock"];
checkFailure["out of order references fail", U["A\:00b2 then B\:00b9.\n\n---\n1) first\n2) second"], "MalformedRenderedBlock"];

check["unrelated superscript ignored",
    U["E = mc\:00b2 and A\:00b9.\n\n---\n1) note"],
    "E = mc\:00b2 and A \:0192(note)."
];

check["superscript inside source annotation ignored",
    U["A\:00b9 and B\:0192(x\:00b2).\n\n---\n1) note"],
    "A \:0192(note) and B\:0192(x\:00b2)."
];

check["block entry horizontal whitespace",
    U["A\:00b9 and B\:00b2.\n\n---\n1)\tnote one\n2)   note two"],
    "A \:0192(note one) and B \:0192(note two)."
];

If[$failures > 0, Print[$failures, " test(s) failed."]; Exit[1], Print["All tests passed."]];
