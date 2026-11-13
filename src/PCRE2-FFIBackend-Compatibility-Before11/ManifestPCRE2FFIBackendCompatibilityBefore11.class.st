"
What the C binding uses of Pharo 11 and later, for Pharo 10: registering a callback with the worker of a process-local runner. The baseline loads it on Pharo 10 with PCRE2-FFIBackend.
"
Class {
	#name : 'ManifestPCRE2FFIBackendCompatibilityBefore11',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-FFIBackend-Compatibility-Before11-Manifest',
	#package : 'PCRE2-FFIBackend-Compatibility-Before11',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2FFIBackendCompatibilityBefore11 class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
