"
The Unicode properties Pharo has no table for, pinned at Unicode 17.0.0 with the property names of PCRE2 10.49: scripts and script extensions, bidi classes, binary properties, grapheme cluster breaks for `\X`, and script runs. Without this package, the Pharo backend refuses the patterns that use them.
"
Class {
	#name : 'ManifestPCRE2UnicodeProperties',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-UnicodeProperties-Manifest',
	#package : 'PCRE2-UnicodeProperties',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2UnicodeProperties class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
