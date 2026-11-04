"
Substitution on the Pharo backend, the implementation of PCRE2-Substitution: `PCRE2ReplacementExpander` expands PCRE2 replacement strings, and the backend runs the substitution callouts and case callouts of the match context.
"
Class {
	#name : 'ManifestPCRE2PharoBackendSubstitution',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-PharoBackend-Substitution-Manifest',
	#package : 'PCRE2-PharoBackend-Substitution',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2PharoBackendSubstitution class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
