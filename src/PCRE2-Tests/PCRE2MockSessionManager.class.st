"
Test double for `PCRE2SessionManager`.

It exposes lifecycle state and failure modes without requiring real image shutdown or startup.
"
Class {
	#name : 'PCRE2MockSessionManager',
	#superclass : 'PCRE2SessionManager',
	#instVars : [
		'injectedMatchersToRestore'
	],
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'accessing' }
PCRE2MockSessionManager class >> useSerialization: aBoolean [

	useSerialization := aBoolean
]

{ #category : 'enumerating' }
PCRE2MockSessionManager >> findMatchersToRestore [
	"Tests inject matchers directly with matchersToRestore:."

	matchersToRestore := Dictionary new.
	injectedMatchersToRestore ifNotNil: [ :matchers |
			matchers do: [ :matcher |
				(matchersToRestore at: matcher codeUnitWidth ifAbsentPut: [ OrderedCollection new ]) add: matcher bePersistent ] ]
]

{ #category : 'accessing' }
PCRE2MockSessionManager >> matchersToRestore: aCollection [

	injectedMatchersToRestore := aCollection.
	self findMatchersToRestore
]

{ #category : 'accessing' }
PCRE2MockSessionManager >> serializedMatchers [

	^ serializedMatchers
]

{ #category : 'accessing' }
PCRE2MockSessionManager >> serializedMatchers: anObject [

	serializedMatchers := anObject
]
