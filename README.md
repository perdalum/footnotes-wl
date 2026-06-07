# footnotes-wl

Wolfram Language implementation of the [Clear-Text Footnotes](https://github.com/perdalum/footnotes) specification. It targets specification version 2.0.0 and follows the earlier implementation decisions in [`footnotes-go`](https://github.com/perdalum/footnotes-go) where they still apply.

## Load in a notebook

Evaluate:

```wl
Get["/path/to/footnotes-wl/Footnotes.wl"]
```

Then use the exported functions:

```wl
FootnoteRender["Wikipedia ƒ(https://wikipedia.org) is mentioned."]
FootnoteUnrender["Wikipedia¹ is mentioned.\n\n---\n1) https://wikipedia.org"]
```

For package-style loading from a checkout, load the paclet directory and evaluate:

```wl
PacletDirectoryLoad["/path/to/footnotes-wl"]
Needs["PerDalum`Footnotes`"]
```

or to install locally:

```wl
PacletInstall["/path/to/footnotes-wl/PacletBuild/PerDalum__Footnotes-2.0.0.paclet", ForceVersionInstall -> True]
```

and then

```wl
Needs["PerDalum`Footnotes`"]
```


## Paclet layout

This repository is ready to build as a Wolfram paclet:

- `PacletInfo.wl` contains the paclet metadata.
- `Kernel/init.wl` is the paclet kernel entrypoint.
- `Kernel/Footnotes.wl` contains the ``PerDalum`Footnotes` `` package source.
- `Tests/FootnotesTests.wls` contains the regression tests.
- `Footnotes.wl` remains as a compatibility loader for direct `Get` usage.

Build and test the paclet with:

```sh
./Build.wls
```

or from Wolfram Language:

```wl
CreatePacletArchive["/path/to/footnotes-wl", "/path/to/footnotes-wl/PacletBuild"]
```

Install the resulting `.paclet` file with:

```wl
PacletInstall["/path/to/footnotes-wl/PacletBuild/PerDalum__Footnotes-2.0.0.paclet"]
Needs["PerDalum`Footnotes`"]
```

## API

- `FootnoteRender[text_String]` renders source annotations `ƒ(note)` to superscript references and appends a rendered footnote block. Horizontal whitespace immediately before a marker is collapsed when the marker follows same-line body text, so `word ƒ(note)` renders as `word¹`.
- `FootnoteUnrender[text_String]` reverses rendered inline references and the final rendered block back to source annotations. When a rendered reference is attached directly to preceding body text, the generated source annotation is separated with one space, so `word¹` unrenders as `word ƒ(note)`.

Malformed input returns a `Failure[...]` object with `Kind`, `Message`, `Line`, `Column`, and `Position` metadata. Successful transformations return a string and do not add an extra final newline.

## Test

```sh
wolframscript -file Tests/FootnotesTests.wls
```

The tests cover the portable scenarios from the upstream specification plus strict final-separator handling, reference ordering, unrelated superscripts, source-annotation skipping, horizontal whitespace in block entries, render-time marker-spacing collapse, and unrender-time marker-spacing insertion.
