"
Tests of the shared API and the C binding. Every case runs on the FFI backend, whatever backend the image defaults to.
"
Class {
	#name : 'ManifestPCRE2Tests',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-Tests-Manifest',
	#package : 'PCRE2-Tests',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2Tests class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
