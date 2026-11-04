"
The shared API of PCRE2 regular expressions: compilers, matchers, matches, compile and match contexts, callouts, inputs and errors for UTF-8 patterns and subjects, and the `String` extensions. It implements no engine: a backend compiles and matches, PCRE2-PharoBackend in Pharo or PCRE2-FFIBackend with the C library. PCRE2-Substitution, PCRE2-DFA, PCRE2-Wide and PCRE2-Trace extend it.
"
Class {
	#name : 'ManifestPCRE2',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-Manifest',
	#package : 'PCRE2',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2 class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
