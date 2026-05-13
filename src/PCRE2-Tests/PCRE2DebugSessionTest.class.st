"
Tests for the PCRE2-Tools debugger session and presenter wiring.

These tests stay headless: they verify the model and presenter objects without opening Morphic windows.
"
Class {
	#name : 'PCRE2DebugSessionTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebuggerPresenterUsesSession [

	| presenter session |
	session := PCRE2DebugSession pattern: 'cat' subject: 'cat'.
	presenter := PCRE2DebuggerPresenter on: session.
	self assert: presenter session equals: session.
	presenter runTrace.
	self assert: session hasTrace.
	self assert: session selectedStep notNil.
	self assert: session selectedStepIndex equals: 1.
	self assert: presenter tracePresenter trace equals: session trace
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testRunTraceBuildsTraceAndPersistentMatch [

	| session |
	session := PCRE2DebugSession pattern: 'c(a)t' subject: 'cat'.
	session runTrace.
	self deny: session hasError.
	self assert: session hasTrace.
	self assert: session stepCount > 0.
	self assert: session selectedStep notNil.
	self assert: session trace isMatch.
	self assert: session trace matchedString equals: 'cat'.
	self assert: session trace match offsets isArray
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testRunTraceCapturesCompileError [

	| session |
	session := PCRE2DebugSession pattern: '(' subject: 'cat'.
	session runTrace.
	self assert: session hasError.
	self deny: session hasTrace.
	self assert: session selectedStep isNil.
	self assert: (session statusString includesSubstring: 'Error:')
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterAcceptsTraceModel [

	| presenter session |
	session := PCRE2DebugSession pattern: 'cat' subject: 'cat'.
	session runTrace.
	presenter := PCRE2TracePresenter on: session trace.
	self assert: presenter trace equals: session trace.
	self assert: presenter selectedStep notNil.
	self
		assert: presenter stepsTable items size
		equals: session trace steps size
]
