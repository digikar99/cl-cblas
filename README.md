# cl-cblas

[C2FFI](https://github.com/rpav/c2ffi/) / [cl-autowrap](https://github.com/rpav/cl-autowrap) based wrapper for [CBLAS](http://www.netlib.org/blas/cblas.h).

Recommended installation: [OpenBLAS](http://www.openblas.net/), which should also be provided with your package manager. See [specs/cblas.h](src/cblas.h) for the API (taken from [netlib](https://netlib.org/blas/cblas.h)).

As opposed to the FORTRAN `blas` bindings, `cblas` provide C bindings, and these can be easier to work with given (i) a LAYOUT parameter for functions operating on matrices allowing for both row-major or column-major matrices (ii) the absence of WORK parameters in several high level functions.

In addition, the cl-autowrap generated bindings expect pointer arguments which translate naturally to displaced arrays which both [numcl](https://github.com/numcl/numcl) and [dense-numericals](https://github.com/digikar99/numericals) rely on.

## Other Solutions

CBLAS is only especially useful for small sized arrays (10-100 sized) when the overhead of runtime dispatch or function calls is comparable to the cost of computation itself. For larger arrays, some of the following well-established libraries should be sufficient.

- [clml](#clml)
- [gsl](#gsl)
- [gsll](#gsll)
- [magicl](#magicl)

### clml

[clml](https://github.com/mmaul/clml) also ships with BLAS bindings, but these can introduce a fair amount of code bloat even after inlining, as is evident through the following disassembly:

```lisp
CL-USER> (declaim (inline array-storage)
                  (ftype (function (cl:array) (cl:simple-array * 1))))
(defun array-storage (array)
  (declare (ignorable array)
           (optimize speed))
  (loop :with array := array
        :do (locally (declare #+sbcl (sb-ext:muffle-conditions sb-ext:compiler-note))
              (typecase array
                ((cl:simple-array * (*)) (return array))
                (cl:simple-array (return #+sbcl (sb-ext:array-storage-vector array)
                                         #+ccl (ccl::%array-header-data-and-offset array)
                                         #-(or sbcl ccl)
                                         (error "Don't know how to obtain ARRAY-STORAGE on ~S"
                                                (lisp-implementation-type))))
                (t (setq array (cl:array-displacement array)))))))
ARRAY-STORAGE
CL-USER> (disassemble (lambda (x)
                        (declare (optimize speed)
                                 (type (array double-float 1) x))
                        (cffi:with-pointer-to-vector-data (ptrx (array-storage x))
                          (cblas:dasum (array-total-size x) ptrx 1))))
; disassembly for (LAMBDA (X))
; Size: 324 bytes. Origin: #x53E3D304                         ; (LAMBDA (X))
; 304:       488BD6           MOV RDX, RSI
; 307:       EB42             JMP L3
; 309:       0F1F8000000000   NOP
; 310: L0:   4C8D72F1         LEA R14, [RDX-15]
; 314:       41F6C60F         TEST R14B, 15
; 318:       750B             JNE L1
; 31A:       458A36           MOV R14B, [R14]
; 31D:       4180EE81         SUB R14B, -127
; 321:       4180FE65         CMP R14B, 101
; 325: L1:   0F82E0000000     JB L15
; 32B:       80FA17           CMP DL, 23
; 32E:       0F84CF000000     JEQ L14
; 334:       488B4A19         MOV RCX, [RDX+25]
; 338:       4881F917011050   CMP RCX, #x50100117             ; NIL
; 33F:       0F85B5000000     JNE L13
; 345:       488BC1           MOV RAX, RCX
; 348: L2:   488BD0           MOV RDX, RAX
; 34B: L3:   4C8D72F1         LEA R14, [RDX-15]
; 34F:       41F6C60F         TEST R14B, 15
; 353:       750B             JNE L4
; 355:       458A36           MOV R14B, [R14]
; 358:       4180EE85         SUB R14B, -123
; 35C:       4180FE61         CMP R14B, 97
; 360: L4:   73AE             JNB L0
; 362:       488BDA           MOV RBX, RDX
; 365: L5:   448B73F1         MOV R14D, [RBX-15]
; 369:       4180EE8D         SUB R14B, -115
; 36D:       4180FE58         CMP R14B, 88
; 371:       0F8780000000     JNBE L12
; 377:       488D4B01         LEA RCX, [RBX+1]
; 37B:       448B76F1         MOV R14D, [RSI-15]
; 37F:       4180FE81         CMP R14B, -127
; 383:       7406             JEQ L6
; 385:       4180FEE9         CMP R14B, -23
; 389:       7263             JB L11
; 38B: L6:   488B4629         MOV RAX, [RSI+41]
; 38F:       48D1F8           SAR RAX, 1
; 392: L7:   4C63F0           MOVSX R14, EAX
; 395:       4939C6           CMP R14, RAX
; 398:       7551             JNE L10
; 39A:       4C8BF4           MOV R14, RSP
; 39D:       4883E4F0         AND RSP, -16
; 3A1:       488BF8           MOV RDI, RAX
; 3A4:       488BF1           MOV RSI, RCX
; 3A7:       BA01000000       MOV EDX, 1
; 3AC:       31C0             XOR EAX, EAX
; 3AE:       FF142548220050   CALL QWORD PTR [#x50002248]     ; cblas_dasum
; 3B5:       498BE6           MOV RSP, R14
; 3B8:       4D896D28         MOV [R13+40], R13               ; thread.pseudo-atomic-bits
; 3BC:       498B5570         MOV RDX, [R13+112]              ; thread.mixed-tlab
; 3C0:       4883C210         ADD RDX, 16
; 3C4:       493B5578         CMP RDX, [R13+120]
; 3C8:       7771             JNBE L17
; 3CA:       49895570         MOV [R13+112], RDX              ; thread.mixed-tlab
; 3CE:       4883C2FF         ADD RDX, -1
; 3D2: L8:   66C742F11D01     MOV WORD PTR [RDX-15], 285
; 3D8:       4D316D28         XOR [R13+40], R13               ; thread.pseudo-atomic-bits
; 3DC:       7402             JEQ L9
; 3DE:       CC09             INT3 9                          ; pending interrupt trap
; 3E0: L9:   F20F1142F9       MOVSD [RDX-7], XMM0
; 3E5:       488BE5           MOV RSP, RBP
; 3E8:       F8               CLC
; 3E9:       5D               POP RBP
; 3EA:       C3               RET
; 3EB: L10:  CC63             INT3 99                         ; OBJECT-NOT-SIGNED-BYTE-32-ERROR
; 3ED:       02               BYTE #X02                       ; RAX(s)
; 3EE: L11:  488B46F9         MOV RAX, [RSI-7]
; 3F2:       48D1F8           SAR RAX, 1
; 3F5:       EB9B             JMP L7
; 3F7: L12:  CC49             INT3 73                         ; OBJECT-NOT-SIMPLE-SPECIALIZED-VECTOR-ERROR
; 3F9:       0C               BYTE #X0C                       ; RBX(d)
; 3FA: L13:  488B4209         MOV RAX, [RDX+9]
; 3FE:       E945FFFFFF       JMP L2
; 403: L14:  B817011050       MOV EAX, #x50100117             ; NIL
; 408:       CC59             INT3 89                         ; OBJECT-NOT-ARRAY-ERROR
; 40A:       00               BYTE #X00                       ; RAX(d)
; 40B: L15:  488975F8         MOV [RBP-8], RSI
; 40F:       4883EC10         SUB RSP, 16
; 413:       B902000000       MOV ECX, 2
; 418:       48892C24         MOV [RSP], RBP
; 41C:       488BEC           MOV RBP, RSP
; 41F:       B8E24E3650       MOV EAX, #x50364EE2             ; #<FDEFN ARRAY-STORAGE-VECTOR>
; 424:       FFD0             CALL RAX
; 426:       488B75F8         MOV RSI, [RBP-8]
; 42A:       488BDA           MOV RBX, RDX
; 42D:       E933FFFFFF       JMP L5
; 432: L16:  FF24256800A052   JMP QWORD PTR [#x52A00068]      ; SB-VM::ALLOC-TRAMP
; 439:       CC10             INT3 16                         ; Invalid argument count trap
; 43B: L17:  6A10             PUSH 16
; 43D:       E8F0FFFFFF       CALL L16
; 442:       5A               POP RDX
; 443:       80CA0F           OR DL, 15
; 446:       EB8A             JMP L8
NIL
CL-USER> (disassemble (lambda (x)
                        (declare (optimize speed)
                                 (type (simple-array double-float 1) x))
                        (clml.blas:dasum (array-total-size x) x 1)))
; disassembly for (LAMBDA (X))
; Size: 990 bytes. Origin: #x53BB6FE4                         ; (LAMBDA (X))
; 6FE4:       4C8B5AF9         MOV R11, [RDX-7]
; 6FE8:       498BC3           MOV RAX, R11
; 6FEB:       48D1F8           SAR RAX, 1
; 6FEE:       4C63C0           MOVSX R8, EAX
; 6FF1:       4939C0           CMP R8, RAX
; 6FF4:       0F858A030000     JNE L25
; 6FFA:       4C895DF0         MOV [RBP-16], R11
; 6FFE:       4D8BF3           MOV R14, R11
; 7001:       4C8975F8         MOV [RBP-8], R14
; 7005:       4883EC10         SUB RSP, 16
; 7009:       B902000000       MOV ECX, 2
; 700E:       48892C24         MOV [RSP], RBP
; 7012:       488BEC           MOV RBP, RSP
; 7015:       B8C2BD4750       MOV EAX, #x5047BDC2            ; #<FDEFN F2CL-LIB::FIND-ARRAY-DATA>
; 701A:       FFD0             CALL RAX
; 701C:       7208             JB L0
; 701E:       BF17011050       MOV EDI, #x50100117            ; NIL
; 7023:       488BDC           MOV RBX, RSP
; 7026: L0:   488BE3           MOV RSP, RBX
; 7029:       4C8B5DF0         MOV R11, [RBP-16]
; 702D:       4C8B75F8         MOV R14, [RBP-8]
; 7031:       488BDA           MOV RBX, RDX
; 7034:       488BF7           MOV RSI, RDI
; 7037:       4C8D43F1         LEA R8, [RBX-15]
; 703B:       41F6C00F         TEST R8B, 15
; 703F:       7504             JNE L1
; 7041:       418038D5         CMP BYTE PTR [R8], -43
; 7045: L1:   0F8536030000     JNE L24
; 704B:       4C8BC6           MOV R8, RSI
; 704E:       49D1F8           SAR R8, 1
; 7051:       4D63C8           MOVSX R9, R8D
; 7054:       4D39C1           CMP R9, R8
; 7057:       7504             JNE L2
; 7059:       40F6C601         TEST SIL, 1
; 705D: L2:   0F851B030000     JNE L23
; 7063:       31D2             XOR EDX, EDX
; 7065:       4531D2           XOR R10D, R10D
; 7068:       31FF             XOR EDI, EDI
; 706A:       660F57C9         XORPD XMM1, XMM1
; 706E:       488B1513FFFFFF   MOV RDX, [RIP-237]             ; 0.0
; 7075:       660F57C9         XORPD XMM1, XMM1
; 7079:       4D85DB           TEST R11, R11
; 707C:       0F8E28020000     JLE L9
; 7082:       48B900000000ABAAAA2A MOV RCX, 3074457347049914368
; 708C:       498BC3           MOV RAX, R11
; 708F:       48F7E1           MUL RAX, RCX
; 7092:       4883E2FE         AND RDX, -2
; 7096:       486BD206         IMUL RDX, RDX, 6
; 709A:       498BC3           MOV RAX, R11
; 709D:       4829D0           SUB RAX, RDX
; 70A0:       4C8BD0           MOV R10, RAX
; 70A3:       4585D2           TEST R10D, R10D
; 70A6:       0F8550020000     JNE L18
; 70AC: L3:   498D4202         LEA RAX, [R10+2]
; 70B0:       488BF8           MOV RDI, RAX
; 70B3:       498BC6           MOV RAX, R14
; 70B6:       4829F8           SUB RAX, RDI
; 70B9:       4883C00C         ADD RAX, 12
; 70BD:       488BC8           MOV RCX, RAX
; 70C0:       48D1F9           SAR RCX, 1
; 70C3:       4C63C1           MOVSX R8, ECX
; 70C6:       4939C8           CMP R8, RCX
; 70C9:       0F8527020000     JNE L17
; 70CF:       48D1F8           SAR RAX, 1
; 70D2:       48B900000000ABAAAA2A MOV RCX, 3074457347049914368
; 70DC:       48F7E9           IMUL RCX
; 70DF:       48D1E2           SHL RDX, 1
; 70E2:       488BC2           MOV RAX, RDX
; 70E5:       85D2             TEST EDX, EDX
; 70E7:       B900000000       MOV ECX, 0
; 70EC:       480F4FC8         CMOVNLE RCX, RAX
; 70F0:       4C8BC9           MOV R9, RCX
; 70F3:       488BD7           MOV RDX, RDI
; 70F6:       E975010000       JMP L5
; 70FB:       0F1F440000       NOP
; 7100: L4:   488D42FE         LEA RAX, [RDX-2]
; 7104:       488D3C06         LEA RDI, [RSI+RAX]
; 7108:       483B7BF9         CMP RDI, [RBX-7]
; 710C:       0F8384020000     JNB L27
; 7112:       F20F1054BB01     MOVSD XMM2, [RBX+RDI*4+1]
; 7118:       660F541580FEFFFF ANDPD XMM2, [RIP-384]          ; [#x53BB6FA0]
; 7120:       F20F58D1         ADDSD XMM2, XMM1
; 7124:       488D4202         LEA RAX, [RDX+2]
; 7128:       488BC8           MOV RCX, RAX
; 712B:       48D1F9           SAR RCX, 1
; 712E:       4C63C1           MOVSX R8, ECX
; 7131:       4939C8           CMP R8, RCX
; 7134:       0F85B6010000     JNE L16
; 713A:       4883C0FE         ADD RAX, -2
; 713E:       488D3C06         LEA RDI, [RSI+RAX]
; 7142:       483B7BF9         CMP RDI, [RBX-7]
; 7146:       0F834E020000     JNB L28
; 714C:       F20F105CBB01     MOVSD XMM3, [RBX+RDI*4+1]
; 7152:       660F541D46FEFFFF ANDPD XMM3, [RIP-442]          ; [#x53BB6FA0]
; 715A:       F20F58DA         ADDSD XMM3, XMM2
; 715E:       488D4204         LEA RAX, [RDX+4]
; 7162:       488BC8           MOV RCX, RAX
; 7165:       48D1F9           SAR RCX, 1
; 7168:       4C63C1           MOVSX R8, ECX
; 716B:       4939C8           CMP R8, RCX
; 716E:       0F8576010000     JNE L15
; 7174:       4883C0FE         ADD RAX, -2
; 7178:       488D3C06         LEA RDI, [RSI+RAX]
; 717C:       483B7BF9         CMP RDI, [RBX-7]
; 7180:       0F8318020000     JNB L29
; 7186:       F20F1064BB01     MOVSD XMM4, [RBX+RDI*4+1]
; 718C:       660F54250CFEFFFF ANDPD XMM4, [RIP-500]          ; [#x53BB6FA0]
; 7194:       F20F58E3         ADDSD XMM4, XMM3
; 7198:       488D4206         LEA RAX, [RDX+6]
; 719C:       488BC8           MOV RCX, RAX
; 719F:       48D1F9           SAR RCX, 1
; 71A2:       4C63C1           MOVSX R8, ECX
; 71A5:       4939C8           CMP R8, RCX
; 71A8:       0F8536010000     JNE L14
; 71AE:       4883C0FE         ADD RAX, -2
; 71B2:       488D3C06         LEA RDI, [RSI+RAX]
; 71B6:       483B7BF9         CMP RDI, [RBX-7]
; 71BA:       0F83E2010000     JNB L30
; 71C0:       F20F105CBB01     MOVSD XMM3, [RBX+RDI*4+1]
; 71C6:       660F541DD2FDFFFF ANDPD XMM3, [RIP-558]          ; [#x53BB6FA0]
; 71CE:       F20F58DC         ADDSD XMM3, XMM4
; 71D2:       488D4208         LEA RAX, [RDX+8]
; 71D6:       488BC8           MOV RCX, RAX
; 71D9:       48D1F9           SAR RCX, 1
; 71DC:       4C63C1           MOVSX R8, ECX
; 71DF:       4939C8           CMP R8, RCX
; 71E2:       0F85F6000000     JNE L13
; 71E8:       4883C0FE         ADD RAX, -2
; 71EC:       488D3C06         LEA RDI, [RSI+RAX]
; 71F0:       483B7BF9         CMP RDI, [RBX-7]
; 71F4:       0F83AC010000     JNB L31
; 71FA:       F20F1064BB01     MOVSD XMM4, [RBX+RDI*4+1]
; 7200:       660F542598FDFFFF ANDPD XMM4, [RIP-616]          ; [#x53BB6FA0]
; 7208:       F20F58E3         ADDSD XMM4, XMM3
; 720C:       488D420A         LEA RAX, [RDX+10]
; 7210:       488BC8           MOV RCX, RAX
; 7213:       48D1F9           SAR RCX, 1
; 7216:       4C63C1           MOVSX R8, ECX
; 7219:       4939C8           CMP R8, RCX
; 721C:       0F85B6000000     JNE L12
; 7222:       4883C0FE         ADD RAX, -2
; 7226:       488D3C06         LEA RDI, [RSI+RAX]
; 722A:       483B7BF9         CMP RDI, [RBX-7]
; 722E:       0F8376010000     JNB L32
; 7234:       F20F104CBB01     MOVSD XMM1, [RBX+RDI*4+1]
; 723A:       660F540D5EFDFFFF ANDPD XMM1, [RIP-674]          ; [#x53BB6FA0]
; 7242:       F20F58CC         ADDSD XMM1, XMM4
; 7246:       488D420C         LEA RAX, [RDX+12]
; 724A:       488BC8           MOV RCX, RAX
; 724D:       48D1F9           SAR RCX, 1
; 7250:       4C63C1           MOVSX R8, ECX
; 7253:       4939C8           CMP R8, RCX
; 7256:       757A             JNE L11
; 7258:       488BD0           MOV RDX, RAX
; 725B:       498D41FE         LEA RAX, [R9-2]
; 725F:       488BC8           MOV RCX, RAX
; 7262:       48D1F9           SAR RCX, 1
; 7265:       4C63C1           MOVSX R8, ECX
; 7268:       4939C8           CMP R8, RCX
; 726B:       755F             JNE L10
; 726D:       4C8BC8           MOV R9, RAX
; 7270: L5:   4D85C9           TEST R9, R9
; 7273:       0F8587FEFFFF     JNE L4
; 7279: L6:   4D896D28         MOV [R13+40], R13              ; thread.pseudo-atomic-bits
; 727D:       498B5570         MOV RDX, [R13+112]             ; thread.mixed-tlab
; 7281:       4883C210         ADD RDX, 16
; 7285:       493B5578         CMP RDX, [R13+120]
; 7289:       0F871F010000     JNBE L33
; 728F:       49895570         MOV [R13+112], RDX             ; thread.mixed-tlab
; 7293:       4883C2FF         ADD RDX, -1
; 7297: L7:   66C742F11D01     MOV WORD PTR [RDX-15], 285
; 729D:       4D316D28         XOR [R13+40], R13              ; thread.pseudo-atomic-bits
; 72A1:       7402             JEQ L8
; 72A3:       CC09             INT3 9                         ; pending interrupt trap
; 72A5: L8:   F20F114AF9       MOVSD [RDX-7], XMM1
; 72AA: L9:   BF17011050       MOV EDI, #x50100117            ; NIL
; 72AF:       488BF7           MOV RSI, RDI
; 72B2:       488975F0         MOV [RBP-16], RSI
; 72B6:       488D5D10         LEA RBX, [RBP+16]
; 72BA:       B908000000       MOV ECX, 8
; 72BF:       F9               STC
; 72C0:       488D65F0         LEA RSP, [RBP-16]
; 72C4:       488B6D00         MOV RBP, [RBP]
; 72C8:       FF73F8           PUSH QWORD PTR [RBX-8]
; 72CB:       C3               RET
; 72CC: L10:  48D1F8           SAR RAX, 1
; 72CF:       CC63             INT3 99                        ; OBJECT-NOT-SIGNED-BYTE-32-ERROR
; 72D1:       02               BYTE #X02                      ; RAX(s)
; 72D2: L11:  48D1F8           SAR RAX, 1
; 72D5:       CC63             INT3 99                        ; OBJECT-NOT-SIGNED-BYTE-32-ERROR
; 72D7:       02               BYTE #X02                      ; RAX(s)
; 72D8: L12:  48D1F8           SAR RAX, 1
; 72DB:       CC63             INT3 99                        ; OBJECT-NOT-SIGNED-BYTE-32-ERROR
; 72DD:       02               BYTE #X02                      ; RAX(s)
; 72DE: L13:  48D1F8           SAR RAX, 1
; 72E1:       CC63             INT3 99                        ; OBJECT-NOT-SIGNED-BYTE-32-ERROR
; 72E3:       02               BYTE #X02                      ; RAX(s)
; 72E4: L14:  48D1F8           SAR RAX, 1
; 72E7:       CC63             INT3 99                        ; OBJECT-NOT-SIGNED-BYTE-32-ERROR
; 72E9:       02               BYTE #X02                      ; RAX(s)
; 72EA: L15:  48D1F8           SAR RAX, 1
; 72ED:       CC63             INT3 99                        ; OBJECT-NOT-SIGNED-BYTE-32-ERROR
; 72EF:       02               BYTE #X02                      ; RAX(s)
; 72F0: L16:  48D1F8           SAR RAX, 1
; 72F3:       CC63             INT3 99                        ; OBJECT-NOT-SIGNED-BYTE-32-ERROR
; 72F5:       02               BYTE #X02                      ; RAX(s)
; 72F6: L17:  48D1F8           SAR RAX, 1
; 72F9:       CC63             INT3 99                        ; OBJECT-NOT-SIGNED-BYTE-32-ERROR
; 72FB:       02               BYTE #X02                      ; RAX(s)
; 72FC: L18:  4D8BCA           MOV R9, R10
; 72FF:       BA02000000       MOV EDX, 2
; 7304:       EB58             JMP L20
; 7306:       660F1F840000000000 NOP
; 730F:       90               NOP
; 7310: L19:  488D42FE         LEA RAX, [RDX-2]
; 7314:       488D3C06         LEA RDI, [RSI+RAX]
; 7318:       483B7BF9         CMP RDI, [RBX-7]
; 731C:       0F839C000000     JNB L34
; 7322:       F20F1054BB01     MOVSD XMM2, [RBX+RDI*4+1]
; 7328:       660F541570FCFFFF ANDPD XMM2, [RIP-912]          ; [#x53BB6FA0]
; 7330:       F20F58CA         ADDSD XMM1, XMM2
; 7334:       488D4202         LEA RAX, [RDX+2]
; 7338:       488BC8           MOV RCX, RAX
; 733B:       48D1F9           SAR RCX, 1
; 733E:       4C63C1           MOVSX R8, ECX
; 7341:       4939C8           CMP R8, RCX
; 7344:       7532             JNE L22
; 7346:       488BD0           MOV RDX, RAX
; 7349:       498D41FE         LEA RAX, [R9-2]
; 734D:       488BC8           MOV RCX, RAX
; 7350:       48D1F9           SAR RCX, 1
; 7353:       4C63C1           MOVSX R8, ECX
; 7356:       4939C8           CMP R8, RCX
; 7359:       7517             JNE L21
; 735B:       4C8BC8           MOV R9, RAX
; 735E: L20:  4D85C9           TEST R9, R9
; 7361:       75AD             JNE L19
; 7363:       4983FE0C         CMP R14, 12
; 7367:       0F8C0CFFFFFF     JL L6
; 736D:       E93AFDFFFF       JMP L3
; 7372: L21:  48D1F8           SAR RAX, 1
; 7375:       CC63             INT3 99                        ; OBJECT-NOT-SIGNED-BYTE-32-ERROR
; 7377:       02               BYTE #X02                      ; RAX(s)
; 7378: L22:  48D1F8           SAR RAX, 1
; 737B:       CC63             INT3 99                        ; OBJECT-NOT-SIGNED-BYTE-32-ERROR
; 737D:       02               BYTE #X02                      ; RAX(s)
; 737E: L23:  CC63             INT3 99                        ; OBJECT-NOT-SIGNED-BYTE-32-ERROR
; 7380:       18               BYTE #X18                      ; RSI(d)
; 7381: L24:  CC33             INT3 51                        ; OBJECT-NOT-SIMPLE-ARRAY-DOUBLE-FLOAT-ERROR
; 7383:       0C               BYTE #X0C                      ; RBX(d)
; 7384: L25:  498BC3           MOV RAX, R11
; 7387:       48D1F8           SAR RAX, 1
; 738A:       CC63             INT3 99                        ; OBJECT-NOT-SIGNED-BYTE-32-ERROR
; 738C:       02               BYTE #X02                      ; RAX(s)
; 738D: L26:  FF24256800A052   JMP QWORD PTR [#x52A00068]     ; SB-VM::ALLOC-TRAMP
; 7394:       CC10             INT3 16                        ; Invalid argument count trap
; 7396: L27:  CC24             INT3 36                        ; INVALID-VECTOR-INDEX-ERROR
; 7398:       0C               BYTE #X0C                      ; RBX(d)
; 7399:       1D               BYTE #X1D                      ; RDI(a)
; 739A: L28:  CC24             INT3 36                        ; INVALID-VECTOR-INDEX-ERROR
; 739C:       0C               BYTE #X0C                      ; RBX(d)
; 739D:       1D               BYTE #X1D                      ; RDI(a)
; 739E: L29:  CC24             INT3 36                        ; INVALID-VECTOR-INDEX-ERROR
; 73A0:       0C               BYTE #X0C                      ; RBX(d)
; 73A1:       1D               BYTE #X1D                      ; RDI(a)
; 73A2: L30:  CC24             INT3 36                        ; INVALID-VECTOR-INDEX-ERROR
; 73A4:       0C               BYTE #X0C                      ; RBX(d)
; 73A5:       1D               BYTE #X1D                      ; RDI(a)
; 73A6: L31:  CC24             INT3 36                        ; INVALID-VECTOR-INDEX-ERROR
; 73A8:       0C               BYTE #X0C                      ; RBX(d)
; 73A9:       1D               BYTE #X1D                      ; RDI(a)
; 73AA: L32:  CC24             INT3 36                        ; INVALID-VECTOR-INDEX-ERROR
; 73AC:       0C               BYTE #X0C                      ; RBX(d)
; 73AD:       1D               BYTE #X1D                      ; RDI(a)
; 73AE: L33:  6A10             PUSH 16
; 73B0:       E8D8FFFFFF       CALL L26
; 73B5:       5A               POP RDX
; 73B6:       80CA0F           OR DL, 15
; 73B9:       E9D9FEFFFF       JMP L7
; 73BE: L34:  CC24             INT3 36                        ; INVALID-VECTOR-INDEX-ERROR
; 73C0:       0C               BYTE #X0C                      ; RBX(d)
; 73C1:       1D               BYTE #X1D                      ; RDI(a)
NIL
```

### gsl

[GNU Scientific Library](https://www.gnu.org/software/gsl/doc/html/) is another alternative to (C)BLAS, but its functions operate on [its own data types](https://www.gnu.org/software/gsl/doc/html/vectors.html#data-types), thus introducing an overhead in translating lisp arrays to the GSL-native wrappers.

### gsll

[GSLL](https://gsll.common-lisp.dev/) too ships with BLAS wrapper, but (i) these are generic functions (ii) even if one uses [static-dispatch](https://github.com/alex-gutev/static-dispatch), the wrappers are made with `grid:foreign-array` in mind; thus introducing a level of indirection.

### magicl

[magicl](https://github.com/quil-lang/magicl) ships with BLAS and LAPACK bindings, however these are FORTRAN bindings. In addition, the magicl generated high level bindings through the `magicl/ext-blas` or `magicl/ext-lapack` systems assume that the arguments will be undisplaced `simple-array`.
