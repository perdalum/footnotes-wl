# footnotes-wl

Wolfram Language implementation of the [Clear-Text Footnotes](https://github.com/perdalum/footnotes) specification. It targets specification version 2.0.0 and follows the earlier implementation decisions in [`footnotes-go`](https://github.com/perdalum/footnotes-go) where they still apply.

## Load in a notebook

Evaluate:

```wl
Get["/path/to/Footnotes.wl"]
```

Then use the exported functions:

```wl
FootnoteRender["Wikipedia ƒ(https://wikipedia.org) is mentioned."]
FootnoteUnrender["Wikipedia¹ is mentioned.\n\n---\n1) https://wikipedia.org"]
```

For package-style loading, put the directory on `$Path` and evaluate:

```wl
Needs["Footnotes`"]
```

## API

- `FootnoteRender[text_String]` renders source annotations `ƒ(note)` to superscript references and appends a rendered footnote block. Horizontal whitespace immediately before a marker is collapsed when the marker follows same-line body text, so `word ƒ(note)` renders as `word¹`.
- `FootnoteUnrender[text_String]` reverses rendered inline references and the final rendered block back to source annotations. When a rendered reference is attached directly to preceding body text, the generated source annotation is separated with one space, so `word¹` unrenders as `word ƒ(note)`.

Malformed input returns a `Failure[...]` object with `Kind`, `Message`, `Line`, `Column`, and `Position` metadata. Successful transformations return a string and do not add an extra final newline.

## Test

```sh
wolframscript -wstpserver -continueprofile /Users/au15929/wstp-profile -file FootnotesTests.wls
```

The tests cover the portable scenarios from the upstream specification plus strict final-separator handling, reference ordering, unrelated superscripts, source-annotation skipping, horizontal whitespace in block entries, render-time marker-spacing collapse, and unrender-time marker-spacing insertion.
