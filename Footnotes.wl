(* ::Package:: *)

(* Compatibility loader for direct Get[".../Footnotes.wl"] usage.
   The paclet source lives in Kernel/Footnotes.wl. *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "Kernel", "Footnotes.wl"}]];
