# Changelog

All notable changes to this project will be documented in this file.

This project follows documented release tags.

## version-2.0.0 - 2026-06-05

### Changed

- Updated rendering for Clear-Text Footnotes specification 2.0.0: horizontal whitespace immediately before a source footnote marker is collapsed when the marker follows same-line body text.
- Updated unrendering to insert a space before generated source annotations when a rendered inline reference was attached directly to preceding body text.
- Updated regression tests for the new spacing behavior.

### Breaking

- Inputs such as `word ƒ(note)` now render as `word¹` instead of `word ¹`.

## version-1.0.0 - 2026-06-05

### Added

- Initial Wolfram Language package implementation in `Footnotes.wl`.
- Public notebook-loadable API:
  - `FootnoteRender[text]`
  - `FootnoteUnrender[text]`
- Rendering of Clear-Text Footnotes source annotations `ƒ(note)` to superscript references and rendered footnote blocks.
- Reversal of rendered footnote blocks back to source annotations.
- Mixed input normalization matching the upstream specification and Go implementation behavior.
- Conservative rendered-block validation, including final separator handling, contiguous numbering, and exactly-once increasing references.
- Error reporting through Wolfram `Failure[...]` values with kind, message, line, column, and position metadata.
- Portable and Go-behavior regression tests in `FootnotesTests.wls`.
- MIT license.
