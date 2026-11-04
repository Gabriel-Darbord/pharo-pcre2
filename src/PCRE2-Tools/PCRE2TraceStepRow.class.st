"
I am one row of the trace presenter: a single step, or a run of consecutive automatic progress steps grouped to keep the table easy to scan. The trace itself is unchanged.
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
	^ String streamContents: [ :stream | stream << self firstStep index asString << '-' << self lastStep index asString ]
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
	^ String streamContents: [ :stream | stream << self firstStep debuggerKindLabel << ' x' << self size asString ]
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
	"Match by index, since a live recorder rebuilds its step objects."

	^ steps detect: [ :step | step index = aTraceStep index ] ifNone: absentBlock
]

{ #category : 'accessing' }
PCRE2TraceStepRow >> steps [

	^ steps
]
