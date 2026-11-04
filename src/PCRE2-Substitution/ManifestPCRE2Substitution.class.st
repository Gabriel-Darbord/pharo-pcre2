"
The shared API of substitution: `PCRE2Matcher>>substitute:with:` and its variants, which use PCRE2's replacement syntax, the substitution callouts and case callouts of the match context, and the events they receive. PCRE2-PharoBackend-Substitution implements it on the Pharo backend, and the C library on the FFI backend.
"
Class {
	#name : 'ManifestPCRE2Substitution',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-Substitution-Manifest',
	#package : 'PCRE2-Substitution',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2Substitution class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
