#!/usr/bin/env wolframscript

projectRoot = DirectoryName[$InputFileName];

Print["Running tests..."];
testResult = RunProcess[{"wolframscript", "-file", FileNameJoin[{projectRoot, "Tests", "FootnotesTests.wls"}]}, All];
WriteString[$Output, testResult["StandardOutput"]];
If[testResult["ExitCode"] =!= 0,
    WriteString[$Output, testResult["StandardError"]];
    Exit[testResult["ExitCode"]]
];

outputDir = FileNameJoin[{projectRoot, "PacletBuild"}];
If[DirectoryQ[outputDir], DeleteDirectory[outputDir, DeleteContents -> True]];

stagingDir = CreateDirectory[];
temporaryOutputDir = CreateDirectory[];

Scan[
    CopyFile[FileNameJoin[{projectRoot, #}], FileNameJoin[{stagingDir, #}], OverwriteTarget -> True] &,
    {"PacletInfo.wl", "README.md", "LICENSE", "CHANGELOG.md", "Footnotes.wl"}
];
Scan[
    CopyDirectory[FileNameJoin[{projectRoot, #}], FileNameJoin[{stagingDir, #}]] &,
    {"Kernel", "Tests"}
];

Print["Creating paclet archive..."];
paclet = CreatePacletArchive[stagingDir, temporaryOutputDir];
If[! DirectoryQ[outputDir], CreateDirectory[outputDir]];
finalPaclet = FileNameJoin[{outputDir, FileNameTake[paclet]}];
CopyFile[paclet, finalPaclet, OverwriteTarget -> True];
DeleteDirectory[stagingDir, DeleteContents -> True];
DeleteDirectory[temporaryOutputDir, DeleteContents -> True];
Print[finalPaclet];
