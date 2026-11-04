Class {
	#name : 'ManifestPCRE2FFIBackend',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-FFIBackend-Manifest',
	#package : 'PCRE2-FFIBackend',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2FFIBackend class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
