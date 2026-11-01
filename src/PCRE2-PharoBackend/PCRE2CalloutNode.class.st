"
Callout. Hands its callout site to the engine, which invokes the callout block and obeys the integer the block answers.
"
Class {
	#name : 'PCRE2CalloutNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'site'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'testing' }
PCRE2CalloutNode >> canBeRepeated [

	^ false
]

{ #category : 'matching' }
PCRE2CalloutNode >> executeIn: engine state: state [

	^ engine callout: site state: state
]

{ #category : 'optimization' }
PCRE2CalloutNode >> isSignificantForStart [

	^ false
]

{ #category : 'accessing' }
PCRE2CalloutNode >> maximumLength [

	^ 0
]

{ #category : 'accessing' }
PCRE2CalloutNode >> site: calloutSite [

	site := calloutSite
]

{ #category : 'optimization' }
PCRE2CalloutNode >> startPredicate [

	^ [ :character | false ]
]
