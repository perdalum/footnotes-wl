# footnotes-wl

Wolfram Language implementation of the [Clear-Text Footnotes](https://github.com/perdalum/footnotes) specification, following the implementation decisions in [`footnotes-go`](https://github.com/perdalum/footnotes-go).

## Load in a notebook

Evaluate:

```wl
Get["/path/to/Footnotes.wl"]
```

Then use the exported functions:

```wl
FootnoteRender["Wikipediaƒ(https://wikipedia.org) is mentioned."]
FootnoteUnrender["Wikipedia¹ is mentioned.\n\n---\n1) https://wikipedia.org"]
```

For package-style loading, put the directory on `$Path` and evaluate:

```wl
Needs["Footnotes`"]
```

## API

- `FootnoteRender[text_String]` renders source annotations `ƒ(note)` to superscript references and appends a rendered footnote block.
- `FootnoteUnrender[text_String]` reverses rendered inline references and the final rendered block back to source annotations.

Malformed input returns a `Failure[...]` object with `Kind`, `Message`, `Line`, `Column`, and `Position` metadata. Successful transformations return a string and do not add an extra final newline.

## Test

```sh
wolframscript -wstpserver -continueprofile /Users/au15929/wstp-profile -file FootnotesTests.wls
```

The tests cover the portable scenarios from the upstream specification plus the stricter Go implementation decisions around final separators, reference ordering, unrelated superscripts, source-annotation skipping, and horizontal whitespace in block entries.
