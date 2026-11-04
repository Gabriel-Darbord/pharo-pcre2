"
Public match-context facade. Obtain contexts from a matcher to preserve backend and code-unit width. Runtime limits and optional callout/JIT facilities are supplied by the selected backend.
"
Class {
	#name : 'PCRE2MatchContext',
	#superclass : 'PCRE2Context',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'testing' }
PCRE2MatchContext class >> isAbstract [

	^ self == PCRE2MatchContext
]

{ #category : 'accessing' }
PCRE2MatchContext >> calloutBlock: aBlock [

	backend calloutBlock: aBlock
]

{ #category : 'accessing' }
PCRE2MatchContext >> clearCallout [

	backend clearCallout
]

{ #category : 'accessing' }
PCRE2MatchContext >> clearJITStack [

	backend clearJITStack
]

{ #category : 'accessing' }
PCRE2MatchContext >> codeUnitWidth [

	^ backend codeUnitWidth
]

{ #category : 'accessing' }
PCRE2MatchContext >> depthLimit [

	^ backend depthLimit
]

{ #category : 'accessing' }
PCRE2MatchContext >> depthLimit: anInteger [

	backend depthLimit: anInteger
]

{ #category : 'accessing' }
PCRE2MatchContext >> heapLimit [

	^ backend heapLimit
]

{ #category : 'accessing' }
PCRE2MatchContext >> heapLimit: anInteger [

	backend heapLimit: anInteger
]

{ #category : 'accessing' }
PCRE2MatchContext >> jitStack [

	^ backend jitStack
]

{ #category : 'accessing' }
PCRE2MatchContext >> jitStack: aJITStack [

	^ backend jitStack: aJITStack
]

{ #category : 'accessing' }
PCRE2MatchContext >> matchLimit [

	^ backend matchLimit
]

{ #category : 'accessing' }
PCRE2MatchContext >> matchLimit: anInteger [

	backend matchLimit: anInteger
]

{ #category : 'accessing' }
PCRE2MatchContext >> offsetLimit [

	^ backend offsetLimit
]

{ #category : 'accessing' }
PCRE2MatchContext >> offsetLimit: anInteger [

	backend offsetLimit: anInteger
]

{ #category : 'accessing' }
PCRE2MatchContext >> privateCopy [

	^ backend privateCopy
]

{ #category : 'accessing' }
PCRE2MatchContext >> restoreAfterStartup [

	backend restoreAfterStartup
]

{ #category : 'accessing' }
PCRE2MatchContext >> setCalloutCallback: callback [

	^ backend setCalloutCallback: callback
]

{ #category : 'accessing' }
PCRE2MatchContext >> setDepthLimit: value [

	^ backend setDepthLimit: value
]

{ #category : 'accessing' }
PCRE2MatchContext >> setHeapLimit: value [

	^ backend setHeapLimit: value
]

{ #category : 'accessing' }
PCRE2MatchContext >> setJITStack: aJITStack [

	^ backend setJITStack: aJITStack
]

{ #category : 'accessing' }
PCRE2MatchContext >> setMatchLimit: value [

	^ backend setMatchLimit: value
]

{ #category : 'accessing' }
PCRE2MatchContext >> setOffsetLimit: value [

	^ backend setOffsetLimit: value
]

{ #category : 'accessing' }
PCRE2MatchContext >> unsetCalloutCallback [

	^ backend unsetCalloutCallback
]

{ #category : 'accessing' }
PCRE2MatchContext >> unsetJITStack [

	^ backend unsetJITStack
]
