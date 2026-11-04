"
The shared API of DFA matching: `PCRE2Matcher>>dfaMatch:` and `dfaMatches:`, which follow every alternative at once and answer every match that starts at the first position where one does. PCRE2-PharoBackend-DFA implements it on the Pharo backend, and the C library on the FFI backend.
"
Class {
	#name : 'ManifestPCRE2DFA',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-DFA-Manifest',
	#package : 'PCRE2-DFA',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2DFA class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
