"
Restores the enclosing subject boundary after a non-atomic scan-substring assertion.
"
Class {
	#name : 'PCRE2ScanSubstringEndNode',
	#superclass : 'PCRE2LookaroundEndNode',
	#instVars : [
		'previousSubject'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2ScanSubstringEndNode >> executeIn: engine state: state [

	state subjectText: previousSubject.
	^ super executeIn: engine state: state
]

{ #category : 'accessing' }
PCRE2ScanSubstringEndNode >> previousSubject: aSubject [

	previousSubject := aSubject
]
