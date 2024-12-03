Class {
	#name : 'PCRE2MockSessionManager',
	#superclass : 'PCRE2SessionManager',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'accessing' }
PCRE2MockSessionManager class >> useSerialization: aBoolean [

	useSerialization := aBoolean
]

{ #category : 'accessing' }
PCRE2MockSessionManager >> MatchersToRestore [

	^ matchersToRestore
]

{ #category : 'system startup' }
PCRE2MockSessionManager >> findMatchersToRestore [
	"Codes are given with the setter.
	Mock the behavior of the super method that makes the codes persistent."

	matchersToRestore do: [ :code | code bePersistent ]
]

{ #category : 'accessing' }
PCRE2MockSessionManager >> matchersToRestore: aCollection [

	matchersToRestore := aCollection
]

{ #category : 'accessing' }
PCRE2MockSessionManager >> serializedMatchers [

	^ serializedMatchers
]

{ #category : 'accessing' }
PCRE2MockSessionManager >> serializedMatchers: aByteArray [

	serializedMatchers := aByteArray
]
