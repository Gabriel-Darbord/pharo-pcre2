"
The backend that compiles and matches in Pharo and needs no library: the pattern parser, the pattern nodes, the backtracking engine, and the matching method it writes for each pattern it can. It reads general categories, case folding and digits through `PCRE2UnicodeData`, from the image's own Unicode tables unless PCRE2-UnicodeCompat replaces them. Substitution and DFA matching come with PCRE2-PharoBackend-Substitution and PCRE2-PharoBackend-DFA.
"
Class {
	#name : 'ManifestPCRE2PharoBackend',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-PharoBackend-Manifest',
	#package : 'PCRE2-PharoBackend',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2PharoBackend class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
