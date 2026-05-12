"
Shared UFFI type aliases used by the PCRE2 binding.

The holder classes model pointer-out parameters used by PCRE2, such as `int *`, `uint32_t *`, and `PCRE2_SIZE *`, without making those helper names global application classes.
"
Class {
	#name : 'PCRE2Types',
	#superclass : 'SharedPool',
	#classVars : [
		'IntHolder',
		'SizeTHolder',
		'UInt32Holder'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'class initialization' }
PCRE2Types class >> initialize [

	SizeTHolder := FFIExternalValueHolder ofType: 'size_t'.
	IntHolder := FFIExternalValueHolder ofType: 'int'.
	UInt32Holder := FFIExternalValueHolder ofType: 'uint32'
]
