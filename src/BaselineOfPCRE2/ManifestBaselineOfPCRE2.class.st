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
