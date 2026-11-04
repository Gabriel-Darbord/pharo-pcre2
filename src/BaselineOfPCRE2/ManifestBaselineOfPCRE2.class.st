"
The Metacello baseline of the project, and `PCRE2Formatter`, the formatter the manifest of every package of the project answers. It lays out `ffiCall:` and callback signatures in the C syntax of the PCRE2 headers, and everything else as the default formatter does, in lines of up to 130 characters.
"
Class {
	#name : 'ManifestBaselineOfPCRE2',
	#superclass : 'PackageManifest',
	#category : 'BaselineOfPCRE2-Manifest',
	#package : 'BaselineOfPCRE2',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestBaselineOfPCRE2 class >> formatter [

	^ PCRE2Formatter new installNewContext: (EFContext new maxLineLength: 130)
]
