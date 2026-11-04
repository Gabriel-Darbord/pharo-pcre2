"
The debugger and trace tools: a debugging session that records an instrumented match with PCRE2-Trace, and the presenters that walk it step by step. They run on either backend.
"
Class {
	#name : 'ManifestPCRE2Tools',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-Tools-Manifest',
	#package : 'PCRE2-Tools',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2Tools class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
