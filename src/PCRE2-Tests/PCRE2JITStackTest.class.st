"
Tests for explicit PCRE2 JIT stack ownership and match-context assignment.
"
Class {
	#name : 'PCRE2JITStackTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'private' }
PCRE2JITStackTest >> skipUnlessJITSupported [

	LibPCRE2 supportsJIT ifFalse: [ ^ true ].
	^ false
]

{ #category : 'tests' }
PCRE2JITStackTest >> testDefaultStackUsesUTF8Defaults [

	| stack |
	self skipUnlessJITSupported ifTrue: [ ^ self ].

	stack := PCRE2JITStack default.

	self assert: stack class equals: PCRE2UTF8JITStack.
	self assert: stack startSize equals: PCRE2JITStack defaultStartSize.
	self assert: stack maxSize equals: PCRE2JITStack defaultMaxSize
]

{ #category : 'tests' }
PCRE2JITStackTest >> testMatchContextCopyKeepsJITStackReference [

	| context copy stack |
	self skipUnlessJITSupported ifTrue: [ ^ self ].

	stack := PCRE2JITStack default.
	context := 'a' asPerlCompatibleRegex context.
	context jitStack: stack.
	copy := context copy.
	[
		self assert: copy jitStack identicalTo: stack.
		copy clearJITStack.
		self assert: copy jitStack isNil.
		self assert: context jitStack identicalTo: stack ] ensure: [ copy free ]
]

{ #category : 'tests' }
PCRE2JITStackTest >> testRejectsMismatchedCodeUnitWidth [

	| stack regex |
	self skipUnlessJITSupported ifTrue: [ ^ self ].
	LibPCRE2 supports16BitCodeUnitWidth ifFalse: [ ^ self ].

	regex := 'a' asPerlCompatibleRegex.
	stack := PCRE2UTF16JITStack default.

	self should: [ regex context jitStack: stack ] raise: PCRE2Error.
	self assert: regex context jitStack isNil
]

{ #category : 'tests' }
PCRE2JITStackTest >> testStackCanBeAssignedToJITMatchContext [

	| regex stack |
	self skipUnlessJITSupported ifTrue: [ ^ self ].

	stack := PCRE2JITStack default.
	regex := 'a+' asPerlCompatibleRegex.
	regex compileJIT.
	regex context jitStack: stack.

	self assert: regex context jitStack identicalTo: stack.
	self assert: (regex find: 'baaa') equals: 'aaa'.

	regex context clearJITStack.
	self assert: regex context jitStack isNil.
	self assert: (regex find: 'baaa') equals: 'aaa'
]
