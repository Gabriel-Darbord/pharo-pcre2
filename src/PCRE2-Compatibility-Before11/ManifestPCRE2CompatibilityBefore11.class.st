"
What the tools use of Pharo 11 and later, for Pharo 10: SpAbstractListPresenter>>whenSelectedItemChangedDo:. The baseline loads it on Pharo 10 only.
"
Class {
	#name : 'ManifestPCRE2CompatibilityBefore11',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-Compatibility-Before11-Manifest',
	#package : 'PCRE2-Compatibility-Before11',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2CompatibilityBefore11 class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
