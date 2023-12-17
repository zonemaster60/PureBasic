

; Demivec	
; https://www.purebasic.fr/english/viewtopic.php?p=478874

; AZJIO: I removed functions that I did not use so that my program using this file would be slightly smaller. You can download the original from the link above.

;{- Program header
;==Code Header Comment==============================
;        Name/title: AutoDetectTextEncoding.pbi
;           Version: 1.0
;            Author: Demivec
;       Create date: 24/Dec/2015
;  Operating system: Windows  [X]GUI
;  Compiler version: PureBasic 5.41 (x64)
;           License: Free to use/abuse/modify.
;                   // THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
;                   // ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;                   // IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;                   // ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
;                   // FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;                   // DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
;                   // OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;                   // HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
;                   // LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
;                   // OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
;                   // SUCH DAMAGE.
;             Forum: http://www.purebasic.fr/english/viewtopic.php?f=13&t=64180&sid=ec0e244cfabf06876bfd82d3f709cc1c
;                    http://www.purebasic.fr/english/viewtopic.php?f=12&t=64385
;  Tested platforms: Windows
;       Explanation: To detect the file encoding by examining the file content.
;                    Includes detection of Unicode (UTF-8, UTF-16, UTF-32) big and little endian encodings.
;                    UTF-16 also includes UCS-2.  Does not include detection of code page for ASCII.
; ==================================================
;}

;module DetectTextEncoding
DeclareModule dte
  EnableExplicit
  
  ;flags for use with detect encoding functions
  EnumerationBinary
    #disallowNulls     ;don't allow Nulls to be in ASCII or a unicode encoding (UTF-8, UTF-16, and UTF-32)
    #enforceProperSurrogateCodes ;surrogate codes need to be paired in a proper lead/tail fashion
    #restrictSurrogateCodesToUTF16 ;allow surrogate codes only in UTF-16 encodings
  EndEnumeration
  
  ;constants for custom decoding results, usually errors
  #err_detectionProcessFailedToStart = -1 ;error given for memmory or filename errors in detection process
  #err_emptyFile = -2 ;error given for an empty file
  #encodingUndetermined = 0
  
  #maxLength = $10000 ;64k is the maximum to read from a file for detection purposes
  
  Declare.i isNativePureBasicFormat(type) ;Returns #True if 'type' is a name PureBasic format
  
  ;Each of the detection functions returns a constant for the type if successful, #encodingUndetermined if
  ;not successful, or #err_detectionProcessFailedToStart if an error was encountered.
  Declare.i detectTextEncodingInBuffer(*buffer, length, flags = 0) ;returns type
EndDeclareModule

Module dte
  Enumeration
    #bigEndian = 0
    #littleEndian = 1
  EndEnumeration
  
  Procedure isNativePureBasicFormat(type)  ;Returns #True if 'type' is a name PureBasic format
    Protected result
    Select type
      Case #PB_Ascii, #PB_Unicode, #PB_UTF8
        result = #True
      Default ;includes #PB_UTF16BE, #PB_UTF32, #PB_UTF32BE
        result = #False
    EndSelect
    ProcedureReturn result
  EndProcedure
  
;   Procedure.s textForDetectedStringFormat(type) ;translates a detection result into text
;     Protected result.s
;     Select type
;       Case #PB_Ascii
;         result = "ASCII"
;       Case #PB_Unicode
;         result = "Unicode"
;       Case #PB_UTF8
;         result = "UTF-8"
;       Case #PB_UTF16BE
;         result = "UTF-16BE"
;       Case #PB_UTF32
;         result = "UTF-32"
;       Case #PB_UTF32BE
;         result = "UTF-32BE"
;       Case #encodingUndetermined
;         result = "Undetermined"
;       Case #err_emptyFile
;         result = "File is empty"
;       Case #err_detectionProcessFailedToStart
;         result = "Detection process failed to start"
;     EndSelect
;     ProcedureReturn result
;   EndProcedure
  
  Procedure countHigherValueIndex(Array s(1), Array n(1))
    ;increment the index of s() that corresponds to the element of n() that is the highest
    If n(0) > n(1)
      s(0) + 1
    ElseIf n(1) > n(0)
      s(1) + 1
    EndIf
  EndProcedure
  
  Procedure.i detectTextEncodingInBuffer(*buffer, length, flags = 0)
    ;The return value will be one of the BOM for string format types listed
    ;in PureBasic's ReadStringFormat() function or it will return 0
    ;for an undetermined format.
    Protected *bufferPtr.Ascii = *buffer, *endPtr = *buffer + length - 1
    Protected isNotASCII, isNotUTF8, isNotUTF16, isNotUTF32
    Protected remainingUTF8_ByteCount, nonASCII_UTF8_Count, workingByte
    Protected byteParity_2, UTF8_surrogateCheckStatus
    Protected byteParity_4, UTF16_commonCharacterCount, i, result
    Protected disallowNulls = flags & #disallowNulls
    Protected enforceSurrogates = flags & #enforceProperSurrogateCodes
    Protected restrictSurrogates = flags & #restrictSurrogateCodesToUTF16
    
    Dim UTF16_nullCount(1)              ;count of nulls in high bytes for each endianness
    Dim isUTF16_EndiannessEliminated(1) ;boolean values
    Dim UTF16_surrogateEndianness(1)    ;count of surrogates for UTF-16 endianness detection
    Dim UTF16_leadSurrogateAddress(1)   ;buffer address at which leadSurrogate was found for each endianness
    Dim UTF16_codePoint.u(1)            ;complete code point interpretation for each endianness
    Dim UTF16_commonCharacterCount(1)   ;count of common code points (i.e. for Space, Tab, CR, LF) for each endiannness
    Dim UTF16_EndiannessStatisticsEval(2) ;sum of endianness probability, indexes {0,1} relate to each endianness
    Dim UTF32_codePoint.l(1)              ;complete code point interpretation for each endianness
    Dim isUTF32_EndiannessEliminated(1)   ;boolean values
    Dim UTF32_surrogateEndianness(1)      ;count of surrogates for UTF-32 endianness detection
    Dim UTF32_leadSurrogateAddress(1)     ;buffer address at which leadSurrogate was found for each endianness
    
    If Not *buffer
      ProcedureReturn #err_detectionProcessFailedToStart
    EndIf
    
    While *bufferPtr <= *endPtr
      If isNotASCII = #False
        If *bufferPtr\a = 0 And disallowNulls
          isNotASCII = #True
        EndIf   
      EndIf
      
      If isNotUTF8 = #False
        ;This encoding is ruled out if a mismatch of surrogate pairs is found or a Null is found
        ;when it is not allowed.
        
        ;Invalid code points (according to Wikipedia)
        ;According to the UTF-8 definition (RFC 3629) the high and low surrogate
        ;halves used by UTF-16 (U+D800 through U+DFFF) are not legal Unicode
        ;values, and their UTF-8 encoding should be treated as an invalid byte
        ;sequence.
        ;
        ;Whether an actual application should do this is debatable, as it makes it
        ;impossible to store invalid UTF-16 (that is, UTF-16 with unpaired
        ;surrogate halves) in a UTF-8 string. This is necessary to store unchecked
        ;UTF-16 such as Windows filenames as UTF-8. It is also incompatible with
        ;CESU-8 encoding (described below).
        ;
        ;Many programs added UTF-8 conversions for UCS-2 data and did not alter
        ;this UTF-8 conversion when UCS-2 was replaced with the surrogate-pair
        ;using UTF-16. In such programs each half of a UTF-16 surrogate pair is
        ;encoded as its own 3-byte UTF-8 encoding, resulting in 6-byte sequences
        ;rather than 4 bytes for characters outside the Basic Multilingual Plane.
        ;Oracle and MySQL databases use this, as well as Java and Tcl as described
        ;below, and probably many Windows programs where the programmers were
        ;unaware of the complexities of UTF-16. Although this non-optimal encoding
        ;is generally not deliberate, a supposed benefit is that it preserves
        ;UTF-16 binary sorting order when CESU-8 is binary sorted.
        
        Select *bufferPtr\a & %11000000
          Case %00000000 ;ASCII byte
            If remainingUTF8_ByteCount > 0 ;in the middle of a multi-byte code point
              isNotUTF8 = #True
              remainingUTF8_ByteCount = 0 ;start over
            EndIf
            
            If *bufferPtr\a = 0 And disallowNulls
              isNotUTF8 = #True
            EndIf
          Case %10000000 ;continuation byte of a multi-byte code point
            If remainingUTF8_ByteCount = 0
              isNotUTF8 = #True ;error, not looking for any more bytes of a multi-byte code point
            Else
              remainingUTF8_ByteCount - 1
              If enforceSurrogates
                If remainingUTF8_ByteCount = 1 And UTF8_surrogateCheckStatus <> 0
                  ;compare second byte of multi-byte code point to check lead/tail ordering of surrogates
                  Select *bufferPtr\a & %10110000
                    Case %10100000 ;lead surrogate
                      If UTF8_surrogateCheckStatus <> 1 
                        isNotUTF8 = #True ;error, tail surrogate should come after previous lead surrogate
                      Else
                        UTF8_surrogateCheckStatus = 2
                      EndIf
                    Case %10110000 ;tail surrogate
                      If UTF8_surrogateCheckStatus <> 3
                        isNotUTF8 = #True ;error, tail surrogate came before lead surrogate
                      Else
                        UTF8_surrogateCheckStatus = 0 ;proper pairing, reset
                      EndIf
                  EndSelect
                EndIf
              EndIf
              If remainingUTF8_ByteCount = 0
                nonASCII_UTF8_Count + 1
              EndIf
            EndIf
          Case %11000000 ;start byte of multi-byte code point (1 - 3 more bytes)
            If remainingUTF8_ByteCount
              isNotUTF8 = #True ;error, still looking for more bytes of a multi-byte code point
            Else
              ;calculate number of remaining bytes
              workingByte = *bufferPtr\a << 1
              remainingUTF8_ByteCount = 0
              While workingByte & %10000000 > 0
                remainingUTF8_ByteCount + 1
                workingByte << 1
              Wend
              
              ;reject UTF-8 sequences (>4 bytes) and also ones that carry no payload in the first byte
              If remainingUTF8_ByteCount > 3 Or workingByte = 0
                isNotUTF8 = #True ;error for an overlong sequence
              EndIf
              
              If *bufferPtr\a = $ED ;byte starts a sequence for a surrogate encoding 
                If restrictSurrogates
                  isNotUTF8 = #True ;error, invalid
                EndIf
                
                UTF8_surrogateCheckStatus + 1 ;advance status to check next byte for lead/tail code
              EndIf
            EndIf
        EndSelect
      EndIf
      
      If isNotUTF16 = #False
        byteParity_2 = (*bufferPtr - *buffer) % 2 ;byte parity of the offset will equal (1) on a completed code point boundary
        If *bufferPtr\a = 0
          UTF16_nullCount(byteParity_2) + 1
        EndIf
        
        ;build complete code points to test
        UTF16_codePoint(#bigEndian) = UTF16_codePoint(#bigEndian) << 8 + *bufferPtr\a
        UTF16_codePoint(#littleEndian) = UTF16_codePoint(#littleEndian) >> 8 + *bufferPtr\a << 8
        
        If byteParity_2 = 1 ;we're on a code point boundary (byte parity of the offset is 'odd')
          For i = #bigEndian To #littleEndian
            If isUTF16_EndiannessEliminated(i) = #False
              Select UTF16_codePoint(i)
                Case $0020, $000A, $000D, $0009 ;space, LF, CR, Tab
                  UTF16_commonCharacterCount(i) + 1
                Case $0000          ;#Null
                  If disallowNulls
                    isNotUTF16 = #True
                  EndIf               
                Case $D800 To $DBFF ;lead surrogate 
                  If enforceSurrogates
                    If UTF16_leadSurrogateAddress(i)
                      isUTF16_EndiannessEliminated(i) = #True
                      If isUTF16_EndiannessEliminated(i ! 1)
                        isNotUTF16 = #True
                      EndIf
                    EndIf  
                  EndIf
                Case $DC00 To $DFFF ;tail surrogate
                  If enforceSurrogates
                    If UTF16_leadSurrogateAddress(i) = *bufferPtr - SizeOf(Unicode)
                      UTF16_surrogateEndianness(i) + 1
                      UTF16_leadSurrogateAddress(i) = 0 ;reset value
                    Else
                      isUTF16_EndiannessEliminated(i) = #True
                      If isUTF16_EndiannessEliminated(i ! 1)
                        isNotUTF16 = #True
                      EndIf
                    EndIf
                  EndIf
              EndSelect
            EndIf
          Next
        EndIf
      EndIf
      
      If isNotUTF32 = #False
        ;Because surrogate code points are not included in the set of Unicode scalar values,
        ;UTF-32 code units in the range $0000D800..$0000DFFF are ill-formed.
        ;Any UTF-32 code unit greater than $0010FFFF is ill-formed.
        ;
        ;UTF-32 is forbidden from storing the non-character code points that are illegal for
        ;interchange, such as 0xFFFF, 0xFFFE, and the all the surrogates.
        ;UTF is a transport encoding, not an internal one.
        ;
        ;According to stackoverflow.com:
        ;But UTF-32 is easy to detect even without a BOM. This is because the
        ;Unicode code point range is restricted to U+10FFFF, and thus UTF-32 units
        ;always have the pattern 00 {0x|10} xx xx (for BE) or xx xx {0x|10} 00 (for
        ;LE). If the data has a length that's a multiple of 4, and follows one of
        ;these patterns, you can safely assume it's UTF-32. False positives are
        ;nearly impossible due to the rarity of 00 bytes in byte-oriented encodings.
        
        byteParity_4 = (*bufferPtr - *buffer) % 4 ;byte parity of the offset will be 3 on a completed code point boundary
        
        Select byteParity_4
          Case 0
            If *bufferPtr\a <> 0 And isUTF32_EndiannessEliminated(#bigEndian) = #False
              isUTF32_EndiannessEliminated(#bigEndian) = #True
              If isUTF32_EndiannessEliminated(#littleEndian)
                isNotUTF32 = #True
              EndIf
            EndIf
          Case 1
            If *bufferPtr\a > $10 And isUTF32_EndiannessEliminated(#bigEndian) = #False
              isUTF32_EndiannessEliminated(#bigEndian) = #True
              If isUTF32_EndiannessEliminated(#littleEndian)
                isNotUTF32 = #True
              EndIf
            EndIf
            
          Case 2
            If *bufferPtr\a > $10 And isUTF32_EndiannessEliminated(#littleEndian) = #False
              isUTF32_EndiannessEliminated(#littleEndian) = #True
              If isUTF32_EndiannessEliminated(#bigEndian)
                isNotUTF32 = #True
              EndIf
            EndIf
          Case 3
            If *bufferPtr\a <> 0 And isUTF32_EndiannessEliminated(#littleEndian) = #False
              isUTF32_EndiannessEliminated(#littleEndian) = #True
              If isUTF32_EndiannessEliminated(#bigEndian)
                isNotUTF32 = #True
              EndIf
            EndIf
        EndSelect
        
        ;build complete code points to test
        UTF32_codePoint(#bigEndian) = UTF32_codePoint(#bigEndian) << 8 + *bufferPtr\a
        UTF32_codePoint(#littleEndian) = (UTF32_codePoint(#littleEndian) >> 8) & $00FFFFFF
        UTF32_codePoint(#littleEndian) + *bufferPtr\a << 24
        
        If byteParity_4 = 3 ;we're on a code point boundary
          For i = #bigEndian To #littleEndian
            If isUTF32_EndiannessEliminated(i) = #False
              Select UTF32_codePoint(i)
                Case $00000000      ;#Null
                  If disallowNulls
                    isNotUTF32 = #True
                  EndIf               
                Case $0000D800 To $0000DFFF ;lead surrogate and tail surrogates for UTF16
                  If restrictSurrogates
                    isUTF32_EndiannessEliminated(i) = #True ;error, found a surrogate code
                    If isUTF32_EndiannessEliminated(i ! 1)
                      isNotUTF32 = #True
                    EndIf
                  ElseIf enforceSurrogates
                    ;need to test for lead/tail ordering and unmatched pairs
                    If UTF32_codePoint(i) <$0000DC00 ;lead surrogate
                      If UTF32_leadSurrogateAddress(i)
                        isUTF32_EndiannessEliminated(i) = #True
                        If isUTF32_EndiannessEliminated(i ! 1)
                          isNotUTF32 = #True
                        EndIf
                      EndIf  
                    Else                             ;tail surrogate
                      If UTF32_leadSurrogateAddress(i) = *bufferPtr - SizeOf(Unicode)
                        UTF32_surrogateEndianness(i) + 1
                        UTF32_leadSurrogateAddress(i) = 0 ;reset value
                      Else
                        isUTF32_EndiannessEliminated(i) = #True
                        If isUTF32_EndiannessEliminated(i ! 1)
                          isNotUTF32 = #True
                        EndIf
                      EndIf
                    EndIf
                  EndIf
                Case $0000FFFE To $0000FFFF ;forbidden non-character code points
                  isUTF32_EndiannessEliminated(i) = #True
                  If isUTF32_EndiannessEliminated(i ! 1)
                    isNotUTF32 = #True
                  EndIf
              EndSelect
            EndIf
          Next
        EndIf
      EndIf
      
      *bufferPtr + SizeOf(Ascii)
    Wend

    ;Examine statics and determine most likely encoding type.
    ;Detection order is UTF-8, UTF-32 (both endians), UTF-16 (both endians), ASCII, else undetermined (a.k.a binary).
    countHigherValueIndex(UTF16_EndiannessStatisticsEval(), UTF16_nullCount())
    countHigherValueIndex(UTF16_EndiannessStatisticsEval(), UTF16_commonCharacterCount())
    countHigherValueIndex(UTF16_EndiannessStatisticsEval(), UTF16_surrogateEndianness())
    If isNotUTF8 = #False And nonASCII_UTF8_Count > 0
      result = #PB_UTF8
    ElseIf isNotUTF32 = #False
      If isUTF32_EndiannessEliminated(#bigEndian) = #False
        result = #PB_UTF32BE ;default
      Else
        result = #PB_UTF32 ;little endian
      EndIf
    ElseIf isNotUTF16 = #False And (UTF16_EndiannessStatisticsEval(#bigEndian) + UTF16_EndiannessStatisticsEval(#littleEndian)) > 0; And (UTF16_commonCharacterCount / length) > 0.05 ;percentage is arbitrary
      
      If isUTF16_EndiannessEliminated(#bigEndian) = #True
        result = #PB_Unicode
      ElseIf isUTF16_EndiannessEliminated(#littleEndian) = #True
        result = #PB_UTF16BE
      Else
        ;still undecided, examine statistics to settle it
        If UTF16_EndiannessStatisticsEval(#bigEndian) < UTF16_EndiannessStatisticsEval(#littleEndian)
          result = #PB_Unicode    
        Else
          result = #PB_UTF16BE ;default
        EndIf
      EndIf
      
    ElseIf isNotASCII = #False
      result = #PB_Ascii
    Else
      result = #encodingUndetermined ;is either binary type (because of detected nulls) or is non-determined
    EndIf
    
    ProcedureReturn result
  EndProcedure


   
EndModule
; IDE Options = PureBasic 6.00 LTS (Windows - x64)
; CursorPosition = 54
; FirstLine = 40
; Folding = --
; EnableAsm
; EnableXP