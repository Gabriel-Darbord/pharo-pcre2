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
PCRE2MockSessionManager >> codesToRestore [

	^ codesToRestore
]

{ #category : 'accessing' }
PCRE2MockSessionManager >> codesToRestore: aCollection [

	codesToRestore := aCollection
]

{ #category : 'system startup' }
PCRE2MockSessionManager >> findCodesToRestore [
	"Codes are given with the setter.
	Mock the behavior of the super method that makes the codes persistent."

	codesToRestore do: [ :code | code bePersistent ]
]

{ #category : 'accessing' }
PCRE2MockSessionManager >> serializedCodes [

	^ serializedCodes
]

{ #category : 'accessing' }
PCRE2MockSessionManager >> serializedCodes: aByteArray [

	serializedCodes := aByteArray
]
