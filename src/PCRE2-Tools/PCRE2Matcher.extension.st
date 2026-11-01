Extension { #name : 'PCRE2Matcher' }

{ #category : '*PCRE2-Tools' }
PCRE2Matcher >> openDebugger [
	"Open a standalone debugger on this pattern, leaving the subject to be typed into the window."

	^ PCRE2DebuggerPresenter openOnPattern: self pattern
]

{ #category : '*PCRE2-Tools' }
PCRE2Matcher >> openDebuggerOn: subjectString [
	"Open a standalone debugger for this pattern and subject."

	^ PCRE2DebuggerPresenter openOnPattern: self pattern subject: subjectString
]
