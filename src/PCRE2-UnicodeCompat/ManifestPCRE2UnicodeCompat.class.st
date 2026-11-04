"
General categories, simple case folding and decimal digits at Unicode 17.0.0, for the Pharo backend on Pharo 14 and older, whose Unicode tables are 9.0. The baseline loads it with the backend on those versions only; Pharo 15 carries the tables at Unicode 18.0.
"
Class {
	#name : 'ManifestPCRE2UnicodeCompat',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-UnicodeCompat-Manifest',
	#package : 'PCRE2-UnicodeCompat',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2UnicodeCompat class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
