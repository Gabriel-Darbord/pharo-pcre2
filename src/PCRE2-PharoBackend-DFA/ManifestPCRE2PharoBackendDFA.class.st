"
DFA matching on the Pharo backend, the implementation of PCRE2-DFA: `PCRE2DFAMatchEngine`, and the hooks it asks of the pattern nodes and match states to tell states apart and to refuse what DFA matching cannot do.
"
Class {
	#name : 'ManifestPCRE2PharoBackendDFA',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-PharoBackend-DFA-Manifest',
	#package : 'PCRE2-PharoBackend-DFA',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2PharoBackendDFA class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
