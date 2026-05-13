Extension { #name : 'PCRE2MatchTrace' }

{ #category : '*PCRE2-Tools' }
PCRE2MatchTrace >> inspectionDebugger [

	<inspectorPresentationOrder: 0 title: 'Debugger'>
	^ PCRE2TracePresenter on: self
]
