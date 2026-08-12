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

{ #category : 'code-critics' }
ManifestPCRE2 class >> ruleLiteralArrayContainsCommaRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGPackageDefinition #(#PCRE2)) #'2026-08-11T00:00:00.0+00:00') )
]
