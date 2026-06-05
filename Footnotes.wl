(* ::Package:: *)

BeginPackage["Footnotes`"];

FootnoteRender::usage = "FootnoteRender[text] renders Clear-Text Footnotes source annotations of the form \!\(\*StyleBox[\"\\:0192(note)\", \"Input\"]\) into superscript references and a collected footnote block. Mixed input with an existing rendered block is normalized first.";
FootnoteUnrender::usage = "FootnoteUnrender[text] reverses a rendered Clear-Text Footnotes block back into inline source annotations of the form \!\(\*StyleBox[\"\\:0192(note)\", \"Input\"]\).";

Begin["`Private`"];

$superByDigit = <|
    "0" -> "\:2070", "1" -> "\:00b9", "2" -> "\:00b2", "3" -> "\:00b3", "4" -> "\:2074",
    "5" -> "\:2075", "6" -> "\:2076", "7" -> "\:2077", "8" -> "\:2078", "9" -> "\:2079"
|>;

$digitBySuper = AssociationThread[Values[$superByDigit] -> Range[0, 9]];

failureQ[expr_] := MatchQ[expr, _Failure];

lineColumn[input_String, pos_Integer] := Module[
    {chars = Characters[input], i = 1, line = 1, col = 1, limit},
    limit = Max[1, Min[pos, Length[chars] + 1]];
    While[i < limit,
        Which[
            chars[[i]] === "\r",
                line++; col = 1;
                If[i < Length[chars] && chars[[i + 1]] === "\n", i += 2, i++],
            chars[[i]] === "\n",
                line++; col = 1; i++,
            True,
                col++; i++
        ]
    ];
    {line, col}
];

makeFailure[kind_String, message_String, input_String, pos_Integer : 1] := Module[
    {lc = lineColumn[input, pos]},
    Failure[kind, <|
        "MessageTemplate" -> message,
        "Message" -> message,
        "Kind" -> kind,
        "Line" -> lc[[1]],
        "Column" -> lc[[2]],
        "Position" -> pos
    |>]
];

charSlice[chars_List, first_Integer, last_Integer] :=
    If[first > last || last < 1 || first > Length[chars], "", StringJoin[chars[[Max[1, first] ;; Min[Length[chars], last]]]]];

lineBreakQ[c_String] := c === "\n" || c === "\r";
whitespaceQ[c_String] := StringTrim[c] === "";
horizontalWhitespaceQ[c_String] := ! lineBreakQ[c] && whitespaceQ[c];
asciiDigitQ[c_String] := Module[{code = First[ToCharacterCode[c, "Unicode"]]}, 48 <= code <= 57];

trimRightWhitespace[str_String] := Module[{chars = Characters[str], i},
    i = Length[chars];
    While[i >= 1 && whitespaceQ[chars[[i]]], i--];
    charSlice[chars, 1, i]
];

startsSourceMarkerQ[chars_List, i_Integer] :=
    i < Length[chars] && chars[[i]] === "\:0192" && chars[[i + 1]] === "(";

superscript[n_Integer?Positive] := StringJoin[Lookup[$superByDigit, Characters[IntegerString[n]]]];

decodeSuperscriptAt[chars_List, start_Integer] := Module[
    {i = start, n = 0, matched = False, d},
    While[i <= Length[chars] && KeyExistsQ[$digitBySuper, chars[[i]]],
        matched = True;
        d = $digitBySuper[chars[[i]]];
        n = 10 n + d;
        i++
    ];
    If[matched && n > 0, {n, i, True}, {0, start, False}]
];

sourceAnnotationEnd[chars_List, start_Integer] := Module[
    {i = start + 2, depth = 1},
    While[i <= Length[chars],
        If[lineBreakQ[chars[[i]]], Return[Missing["NotFound"]]];
        Switch[chars[[i]],
            "(", depth++,
            ")", depth--; If[depth === 0, Return[i + 1]]
        ];
        i++
    ];
    Missing["NotFound"]
];

parseSourceAnnotation[input_String, chars_List, start_Integer] := Module[
    {i = start + 2, contentStart = start + 2, depth = 1, raw, trimmed},
    While[i <= Length[chars],
        If[lineBreakQ[chars[[i]]],
            Return[makeFailure["NewlineInSourceNote", "newline in source footnote", input, start]]
        ];
        Switch[chars[[i]],
            "(", depth++,
            ")",
                depth--;
                If[depth === 0,
                    raw = charSlice[chars, contentStart, i - 1];
                    trimmed = StringTrim[raw];
                    If[trimmed === "",
                        Return[makeFailure["EmptySourceNote", "empty source footnote", input, start]]
                    ];
                    Return[<|"Text" -> trimmed, "Next" -> i + 1|>]
                ]
        ];
        i++
    ];
    makeFailure["UnclosedSourceMarker", "unclosed footnote marker", input, start]
];

splitLogicalLines[input_String] := Module[
    {chars = Characters[input], lines = {}, start = 1, i = 1},
    While[i <= Length[chars],
        If[lineBreakQ[chars[[i]]],
            AppendTo[lines, <|"Text" -> charSlice[chars, start, i - 1], "Start" -> start, "End" -> i|>];
            If[chars[[i]] === "\r" && i < Length[chars] && chars[[i + 1]] === "\n", i += 2, i++];
            start = i,
            i++
        ]
    ];
    AppendTo[lines, <|"Text" -> charSlice[chars, start, Length[chars]], "Start" -> start, "End" -> Length[chars] + 1|>];
    lines
];

parseBlockEntry[line_String] := Module[
    {chars = Characters[line], i = 1, n, sepStart, text},
    If[Length[chars] === 0, Return[{0, "", False}]];
    While[i <= Length[chars] && asciiDigitQ[chars[[i]]], i++];
    If[i === 1 || i > Length[chars] || chars[[i]] =!= ")", Return[{0, "", False}]];
    n = ToExpression[StringJoin[chars[[1 ;; i - 1]]]];
    If[n <= 0, Return[{0, "", False}]];
    i++;
    If[i > Length[chars], Return[{0, "", False}]];
    sepStart = i;
    While[i <= Length[chars] && horizontalWhitespaceQ[chars[[i]]], i++];
    If[i === sepStart, Return[{0, "", False}]];
    text = StringTrim[charSlice[chars, i, Length[chars]]];
    If[text === "", Return[{0, "", False}]];
    {n, text, True}
];

malformedRenderedBlock[input_String, pos_Integer, message_String] :=
    makeFailure["MalformedRenderedBlock", message, input, pos];

validateInlineReferences[body_String, entries_List, fullInput_String] := Module[
    {chars = Characters[body], i = 1, seen = ConstantArray[0, Length[entries]], lastMatched = 0,
     end, decoded, n, next},
    While[i <= Length[chars],
        If[startsSourceMarkerQ[chars, i],
            end = sourceAnnotationEnd[chars, i];
            If[IntegerQ[end], i = end; Continue[]]
        ];
        decoded = decodeSuperscriptAt[chars, i];
        If[decoded[[3]],
            {n, next} = decoded[[1 ;; 2]];
            If[1 <= n <= Length[entries],
                If[n <= lastMatched,
                    Return[malformedRenderedBlock[fullInput, i, "rendered inline references must appear once in increasing order"]]
                ];
                seen[[n]]++;
                lastMatched = n
            ];
            i = next; Continue[]
        ];
        i++
    ];
    Do[
        If[seen[[n]] =!= 1,
            Return[malformedRenderedBlock[fullInput, 1, "rendered inline reference " <> ToString[n] <> " must appear exactly once"]]
        ],
        {n, Length[entries]}
    ];
    Null
];

detectRenderedBlock[input_String] := Module[
    {lines = splitLogicalLines[input], last, sep, entries = {}, parsed, number, text, ok,
     body, validation, chars = Characters[input]},
    last = Length[lines];
    While[last >= 1 && StringTrim[lines[[last, "Text"]]] === "", last--];
    If[last < 1, Return[<|"Found" -> False|>]];

    sep = 0;
    Do[
        If[StringTrim[lines[[i, "Text"]]] === "---", sep = i; Break[]],
        {i, last, 1, -1}
    ];
    If[sep === 0, Return[<|"Found" -> False|>]];

    If[sep === last,
        Return[malformedRenderedBlock[input, lines[[sep, "Start"]], "rendered footnote block has no entries"]]
    ];

    Do[
        parsed = parseBlockEntry[lines[[i, "Text"]]];
        {number, text, ok} = parsed;
        If[! TrueQ[ok],
            Return[malformedRenderedBlock[input, lines[[i, "Start"]], "invalid rendered footnote entry"]]
        ];
        If[number =!= Length[entries] + 1,
            Return[malformedRenderedBlock[input, lines[[i, "Start"]], "rendered footnote entries must be contiguous and start at 1"]]
        ];
        AppendTo[entries, text],
        {i, sep + 1, last}
    ];

    If[Length[entries] === 0,
        Return[malformedRenderedBlock[input, lines[[sep, "Start"]], "rendered footnote block has no entries"]]
    ];

    body = trimRightWhitespace[charSlice[chars, 1, lines[[sep, "Start"]] - 1]];
    validation = validateInlineReferences[body, entries, input];
    If[failureQ[validation], Return[validation]];

    <|"Found" -> True, "Body" -> body, "Entries" -> entries|>
];

reverseWithBlock[block_Association] := Module[
    {body = block["Body"], entries = block["Entries"], chars, out = {}, i = 1,
     end, decoded, n, next},
    chars = Characters[body];
    While[i <= Length[chars],
        If[startsSourceMarkerQ[chars, i],
            end = sourceAnnotationEnd[chars, i];
            If[IntegerQ[end],
                AppendTo[out, charSlice[chars, i, end - 1]];
                i = end; Continue[]
            ]
        ];
        decoded = decodeSuperscriptAt[chars, i];
        If[decoded[[3]],
            {n, next} = decoded[[1 ;; 2]];
            If[1 <= n <= Length[entries],
                AppendTo[out, "\:0192(" <> entries[[n]] <> ")"],
                AppendTo[out, charSlice[chars, i, next - 1]]
            ];
            i = next; Continue[]
        ];
        AppendTo[out, chars[[i]]];
        i++
    ];
    StringJoin[out]
];

renderSource[input_String] := Module[
    {chars = Characters[input], out = {}, notes = {}, i = 1, parsed, body, blockLines},
    While[i <= Length[chars],
        If[startsSourceMarkerQ[chars, i],
            parsed = parseSourceAnnotation[input, chars, i];
            If[failureQ[parsed], Return[parsed]];
            AppendTo[notes, parsed["Text"]];
            AppendTo[out, superscript[Length[notes]]];
            i = parsed["Next"]; Continue[]
        ];
        AppendTo[out, chars[[i]]];
        i++
    ];

    If[Length[notes] === 0, Return[input]];

    body = trimRightWhitespace[StringJoin[out]];
    blockLines = MapIndexed[ToString[First[#2]] <> ") " <> #1 &, notes];
    body <> "\n\n---\n" <> StringRiffle[blockLines, "\n"]
];

FootnoteRender[text_String] := Module[{block, reversed},
    block = detectRenderedBlock[text];
    If[failureQ[block], Return[block]];
    If[TrueQ[block["Found"]],
        reversed = reverseWithBlock[block];
        Return[renderSource[reversed]]
    ];
    renderSource[text]
];

FootnoteUnrender[text_String] := Module[{block},
    block = detectRenderedBlock[text];
    If[failureQ[block], Return[block]];
    If[! TrueQ[block["Found"]], Return[text]];
    reverseWithBlock[block]
];

FootnoteRender[other_] := Failure["InvalidInput", <|"MessageTemplate" -> "FootnoteRender expects a string.", "Input" -> HoldForm[other]|>];
FootnoteUnrender[other_] := Failure["InvalidInput", <|"MessageTemplate" -> "FootnoteUnrender expects a string.", "Input" -> HoldForm[other]|>];

End[];
EndPackage[];
