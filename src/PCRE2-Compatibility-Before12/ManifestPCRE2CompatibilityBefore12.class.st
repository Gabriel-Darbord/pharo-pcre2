"
What the tools use of Pharo 12 and later, for the versions before it: Semaphore>>waitTimeoutMilliseconds:. The baseline loads it on Pharo 10 and 11 only, and nothing else in the project depends on a newer Pharo.
"
Class {
	#name : 'ManifestPCRE2CompatibilityBefore12',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-Compatibility-Before12-Manifest',
	#package : 'PCRE2-Compatibility-Before12',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2CompatibilityBefore12 class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
