Extension { #name : 'PCRE2Matcher' }

{ #category : '*PCRE2-Tools' }
PCRE2Matcher >> openDebugger [

	^ PCRE2DebuggerPresenter openOnPattern: self pattern
]

{ #category : '*PCRE2-Tools' }
PCRE2Matcher >> openDebuggerOn: subjectString [

	^ PCRE2DebuggerPresenter openOnPattern: self pattern subject: subjectString
]
