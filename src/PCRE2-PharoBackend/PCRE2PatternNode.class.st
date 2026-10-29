Class {
	#name : 'PCRE2PatternNode',
	#superclass : 'Object',
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2PatternNode >> lookbehindBranches [

	^ { self }
]

{ #category : 'matching' }
PCRE2PatternNode >> maximumLength [

	^ nil
]

{ #category : 'matching' }
PCRE2PatternNode >> minimumLength [

	^ 0
]

{ #category : 'parsing' }
PCRE2PatternNode >> repeatMinimum: minimum maximum: maximum greedy: greedy [

	^ PCRE2RepeatNode new
		  child: self;
		  minimum: minimum;
		  maximum: maximum;
		  greedy: greedy
]
