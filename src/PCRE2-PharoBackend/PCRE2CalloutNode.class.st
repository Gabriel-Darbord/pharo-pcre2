Class {
	#name : 'PCRE2CalloutNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'site'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2CalloutNode >> executeIn: engine state: state [

	^ engine callout: site state: state
]

{ #category : 'matching' }
PCRE2CalloutNode >> maximumLength [

	^ 0
]

{ #category : 'matching' }
PCRE2CalloutNode >> site: calloutSite [

	site := calloutSite
]

{ #category : 'matching' }
PCRE2CalloutNode >> startPredicate [

	^ [ :character | false ]
]
