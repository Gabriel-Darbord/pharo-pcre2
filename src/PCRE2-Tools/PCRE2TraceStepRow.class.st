"
I am one visible row in the PCRE2 trace presenter.

A row wraps one or more consecutive PCRE2TraceStep objects. Single-step rows keep exact step-by-step navigation, while grouped rows condense long automatic progress runs that would otherwise make the debugger table hard to scan. The raw PCRE2MatchTrace remains unchanged; grouping is only a presentation concern.
"
Class {
	#name : 'PCRE2TraceStepRow',
	#superclass : 'Object',
	#instVars : [
		'steps'
	],
	#category : 'PCRE2-Tools-Debugging',
	#package : 'PCRE2-Tools',
	#tag : 'Debugging'
}

{ #category : 'instance creation' }
PCRE2TraceStepRow class >> steps: traceSteps [

	^ self new initializeSteps: traceSteps
]

{ #category : 'accessing' }
PCRE2TraceStepRow >> firstStep [

	^ steps first
]

{ #category : 'testing' }
PCRE2TraceStepRow >> includesStep: aTraceStep [

	^ steps anySatisfy: [ :step | step index = aTraceStep index ]
]

{ #category : 'accessing' }
PCRE2TraceStepRow >> indexLabel [

	self isGroup ifFalse: [ ^ self firstStep index asString ].
	^ self firstStep index asString , '-' , self lastStep index asString
]

{ #category : 'initialization' }
PCRE2TraceStepRow >> initializeSteps: traceSteps [

	steps := traceSteps asArray.
	steps ifEmpty: [ self error: 'A trace row needs at least one step' ]
]

{ #category : 'testing' }
PCRE2TraceStepRow >> isGroup [

	^ steps size > 1
]

{ #category : 'accessing' }
PCRE2TraceStepRow >> kindLabel [

	self isGroup ifFalse: [ ^ self firstStep debuggerKindLabel ].
	^ self firstStep debuggerKindLabel , ' x' , self size asString
]

{ #category : 'accessing' }
PCRE2TraceStepRow >> lastStep [

	^ steps last
]

{ #category : 'accessing' }
PCRE2TraceStepRow >> representativeStep [
	"Answer the step whose details should be shown when the row is selected."

	^ self firstStep
]

{ #category : 'accessing' }
PCRE2TraceStepRow >> size [

	^ steps size
]

{ #category : 'accessing' }
PCRE2TraceStepRow >> stepMatching: aTraceStep ifAbsent: absentBlock [
	"Answer the row step equivalent to aTraceStep. Step objects may be rebuilt when a live recorder refreshes, so matching by stable index is enough here."

	^ steps detect: [ :step | step index = aTraceStep index ] ifNone: absentBlock
]

{ #category : 'accessing' }
PCRE2TraceStepRow >> steps [

	^ steps
]
