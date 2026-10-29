Class {
	#name : 'PCRE2LookaroundEndNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'position',
		'previousAssertions',
		'previousAlternations'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2LookaroundEndNode >> acceptIn: engine state: state [

	self executeIn: engine state: state.
	^ true
]

{ #category : 'matching' }
PCRE2LookaroundEndNode >> dfaKey [

	^ {
		  self class.
		  position }
]

{ #category : 'matching' }
PCRE2LookaroundEndNode >> executeIn: engine state: state [

	state
		position: position;
		assertions: previousAssertions;
		alternations: previousAlternations.
	^ state
]

{ #category : 'matching' }
PCRE2LookaroundEndNode >> position: offset [

	position := offset
]

{ #category : 'matching' }
PCRE2LookaroundEndNode >> position: offset assertions: assertions alternations: alternatives [

	position := offset.
	previousAssertions := assertions.
	previousAlternations := alternatives
]

{ #category : 'matching' }
PCRE2LookaroundEndNode >> runtimeStorageSize [

	^ self sizeInMemory
]
