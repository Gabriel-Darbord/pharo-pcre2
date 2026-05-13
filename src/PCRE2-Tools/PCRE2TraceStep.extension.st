Extension { #name : 'PCRE2TraceStep' }

{ #category : '*PCRE2-Tools' }
PCRE2TraceStep >> debuggerCalloutLabel [

	| calloutEvent |
	calloutEvent := self event.
	calloutEvent isAutomatic ifTrue: [ ^ 'auto' ].
	calloutEvent string ifNotNil: [ :string |
		^ calloutEvent number asString , ' ' , string ].
	^ calloutEvent number asString
]

{ #category : '*PCRE2-Tools' }
PCRE2TraceStep >> debuggerKindLabel [

	^ self kind asString
]

{ #category : '*PCRE2-Tools' }
PCRE2TraceStep >> debuggerPatternRangeLabel [

	^ self debuggerRangeLabelFor: self patternRange
]

{ #category : '*PCRE2-Tools' }
PCRE2TraceStep >> debuggerRangeLabelFor: anIntervalOrNil [

	anIntervalOrNil ifNil: [ ^ '' ].
	anIntervalOrNil isEmpty ifTrue: [
		^ anIntervalOrNil first asString , ' (empty)' ].
	^ anIntervalOrNil first asString , '-'
	  , anIntervalOrNil last asString
]

{ #category : '*PCRE2-Tools' }
PCRE2TraceStep >> debuggerSubjectRangeLabel [

	^ self debuggerRangeLabelFor: self subjectRange
]
