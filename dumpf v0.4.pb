; Dumpf by Flaith (dump & disassemble)
; 20/09/07 : V0.1
; 22/09/07 : V0.2
; 05/10/07 : V0.3.1 : Adding Disassembling function
; 14/10/07 : V0.4   : Adding Disassembling immediate value
; 15/10/07 : V0.4.1 : Adding #x86_IsThirdOpCode
; 18/10/07 : V0.4.2 : Adding #x86_IsAddREG_Value & #x86_IsAddREG_1_Value
; Last modification : 18/10/07

; TODO :
; ----
;
; - Get PE Header & GNU/Linux Header to set the "Count_EIP"
; - More accurate "Emit Instruction" function
; -   "      "    "Argv" function
;      -> dumpf -d 00012b5c44220f
;      -> dumpf file.exe -d > file_dis.asm
;      -> dumpf -d file.exe > file_dis.asm
;      -> dumpf file.exe -t8 -f16
;                  -f : format 8, 16, 32 or 64 Bits (default : 32)

#VERSION = "0.4.2"
#Prefix = "0x"
#QUOTE = Chr(34)
#LINE_4 = 4
#LINE_8 = 8
#ffile = 0
#DebugFile = 100

#BROWN        = 6

Enumeration 
  #REGISTER_BYTE
  #REGISTER_WORD
  #REGISTER_DWORD
  #REGISTER_QUADWORD
EndEnumeration

Enumeration $0100
  #x86_None
  #x86_IsRegister
  #x86_IsPointer
  #x86_IsJump
  #x86_IsJumpPtr
  #x86_IsAdress
  #x86_IsDblAdress
  #x86_IsSecondOpCode
  #x86_IsThirdOpCode
  #x86_IsAddREG
  #x86_IsSubREG
  #x86_IsAddREG_1_Value
  #x86_IsAddREG_Value
  #x86_IsSubREG_Value
EndEnumeration

Enumeration 
  #EAX
  #ECX
  #EDX
  #EBX
  #ESP
  #EBP
  #ESI
  #EDI
EndEnumeration

Structure HDUMP
  hex.s
  chr.s
EndStructure

Structure HDISASS
  OpCode.s
EndStructure

Structure LINEDISASS
  Line.s
EndStructure

Global Dim argv.s(10)
Global Dim TAB_Register.s(#EDI,#REGISTER_QUADWORD)
Global length.l = 0, _VAL = #False, _DISASSEMBLING = #False, _IMMEDIATE_VALUE = #False
Global OpCode.s, Instruction.s, Register.s, count_EIP.l
Global *Buffer
Global NewList Dumpf.HDUMP()
Global NewList Disassm.HDISASS()
Global NewList DisassLine.LINEDISASS()
Global REGISTER_TYPE.l = #REGISTER_DWORD

; Extern function
Procedure HexVal(Txt.s) ; Convertir une chaine hexadécimal en valeur numérique par "LeSoldatInconnu"
  Protected Val.l, n.l, Caractere.w
  Txt = LCase(Trim(RemoveString(Txt, "$")))
  Val = 0
  For n = 0 To Len(Txt) - 1
    Caractere = Asc(Mid(Txt, Len(Txt) - n ,1))
    If Caractere >= 97 And Caractere <= 102
      Val = Val | ((Caractere - 87) << (4 * n))
    ElseIf Caractere >= 48 And Caractere <= 57
      Val = Val | ((Caractere - 48) << (4 * n))
    EndIf
  Next
  ProcedureReturn Val
EndProcedure

;Self made functions
Procedure.l GET_Argv()
Protected txt.s, i.l

  i = 0
  txt = ProgramParameter()

  While txt <> ""
    argv(i) = txt
    i+1
    txt = ProgramParameter()
  Wend
  ProcedureReturn i
EndProcedure

Procedure Add_Buffer(taille.l)

  i = 0 : counter = 0 : a$ = "" : b$ = "" : disass$ = ""
  
  a = PeekB(*Buffer+i) & $FF
  
  If a>31 And a<127
    b$ + Chr(a)
  Else
    b$ + "."
  EndIf

  disass$ = RSet(Hex(a),2,"0")
  a$ = disass$ + " "
  
  i+1
  
  While i < length
    
    If _DISASSEMBLING = #True
      AddElement(Disassm())
        Disassm()\OpCode = Disass$
    EndIf
    
    If i % taille = 0
      AddElement(DumpF())
        DumpF()\hex = RSet(Hex(counter),#LINE_8,"0")+ ":" +a$
        DumpF()\chr = b$
      a$ = "": b$ = "" : counter = i
    EndIf
    a = PeekB(*Buffer+i) & $FF
    If a>31 And a<127
      b$ + Chr(a)
    Else
      b$ + "."
    EndIf
    
    disass$ = RSet(Hex(a),2,"0")
    a$ + disass$ + " "
    
    i+1
  Wend

  z = taille - (length-counter)
  sp$ = Space(z+z*2)

  AddElement(DumpF())
    DumpF()\hex = RSet(Hex(counter),#LINE_8,"0") + ":" + a$ + sp$
    DumpF()\chr = b$
EndProcedure

Procedure DebugPrintN(str.s)
  EIP$ = RSet(Hex(Count_EIP),#LINE_8,"0")
  WriteStringN(#DebugFile,EIP$ + "-" + str)
EndProcedure

Procedure.l load_file(file.s,taille.l)
Protected fd.l, bytes.l
  
  If _IMMEDIATE_VALUE = #False
    fd = ReadFile(#ffile,file)
    If fd
      length = Lof(#ffile)
      *Buffer = AllocateMemory(length)
      If *Buffer
        bytes = ReadData(#ffile, *Buffer, length)
        Add_Buffer(taille)
      Else
        PrintN("Allocation Memory Error")
        End
      EndIf
	  Else
      ProcedureReturn -1
	  EndIf
	
	  CloseFile(#ffile)
	  FreeMemory(*Buffer)
	Else
	  *Buffer = AllocateMemory(Len(file)/2)
	  str$ = Mid(file,3,Len(file)-2)
    j.l = 0
	  For i = 1 To Len(str$) Step 2
	    a.l = HexVal(Mid(str$,i,2))
      PokeB(*buffer+j,a)
      j+1
    Next i
    PrintN("Disassembling immediate value")
    length = j+1
    Add_Buffer(j)
	EndIf
	
  ProcedureReturn 0
EndProcedure

Procedure.s GetNextOpCode()

  NextElement(Disassm())
    ProcedureReturn Disassm()\OpCode

EndProcedure

Procedure.s GetPrevOpCode()

  Count_EIP - 1
  PreviousElement(Disassm())
    ProcedureReturn Disassm()\OpCode

EndProcedure

Procedure Emit_Instr(instr.s,nb_instr.l=0,value.l=#x86_None,rem$="")

  If value = #x86_IsSecondOpCode
    Second_Instr$ = instr+" "+GetNextOpCode()
    Count_EIP + 1
    Opcode = Second_Instr$
    Select Second_Instr$
      Case "01 05" : Instr = "add    " : nb_instr = 4 : value = #x86_IsAdress : Register = ", eax"
      Case "01 14" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "01 54" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "01 DD" : Instr = "add    ebp, ebx"

      Case "03 05" : Instr = "add    eax, " : nb_instr = 4 : value = #x86_IsPointer
      Case "03 0D" : Instr = "add    ecx, " : nb_instr = 4 : value = #x86_IsPointer
      Case "03 15" : Instr = "add    edx, " : nb_instr = 4 : value = #x86_IsPointer
      Case "03 45" : Instr = "add    eax, [ebp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"

      Case "03 5C" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "03 7C" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      
      Case "09 C0" : Instr = "or     eax, eax"
      Case "09 FB" : Instr = "or     ebx, edi"

      Case "0F 84" : Instr = "je     " : nb_instr = 4 : value = #x86_IsJump
      Case "0F 85" : Instr = "jne    " : nb_instr = 4 : value = #x86_IsJump
      Case "0F 8C" : Instr = "jl     " : nb_instr = 4 : value = #x86_IsJump
      Case "0F 8D" : Instr = "jge    " : nb_instr = 4 : value = #x86_IsJump
      Case "0F 8F" : Instr = "jg     " : nb_instr = 4 : value = #x86_IsJump

      Case "21 C0" : Instr = "and    eax, eax"
      Case "21 DB" : Instr = "and    ebx, ebx"
      Case "29 FB" : Instr = "sub    ebx, edi"

      Case "31 C0" : Instr = "xor    eax, eax"
      Case "31 C9" : Instr = "xor    ecx, ecx"
      Case "31 D2" : Instr = "xor    edx, edx"
      Case "31 DB" : Instr = "xor    ebx, ebx"
      Case "31 F6" : Instr = "xor    esi, esi"

      Case "39 11" : Instr = "cmp    [ecx], edx"
      Case "39 D0" : Instr = "cmp    eax, edx"
      
      Case "3B 04" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "3B 1C" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "3B 1D" : Instr = "cmp    ebx, " : nb_instr = 4 : value = #x86_IsPointer
      Case "3B 44" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "3B 5C" : GetPrevOpCode() : value = #x86_IsThirdOpCode

      Case "6B 45" : Instr = "imul   [ebp+" : nb_instr = 2 : value = #x86_IsAddREG_Value : Register = "]"

      Case "81 FB" : Instr = "cmp    ebx, "
      
      Case "83 05" : Instr = "add    " : nb_instr = 5 : value = #x86_IsDblAdress
      Case "83 38" : Instr = "cmp    [eax]," : nb_instr = 1
      Case "83 7C" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "83 7D" : Instr = "cmp    [ebp+" : nb_instr = 2 : value = #x86_IsAddREG_Value : Register = "]"

      Case "83 C0" : Instr = "add    eax, " : nb_instr = 1
      Case "83 C1" : Instr = "add    ecx, " : nb_instr = 1
      Case "83 C2" : Instr = "add    edx, " : nb_instr = 1
      Case "83 C3" : Instr = "add    ebx, -" : nb_instr = 1 : value = #x86_IsSubREG

      Case "83 C4" : Instr = "add    esp, " : nb_instr = 1
      Case "83 C6" : Instr = "add    esi, " : nb_instr = 1
      Case "83 C7" : Instr = "add    edi, " : nb_instr = 1
      Case "83 E4" : Instr = "and    esp, " : nb_instr = 1
      Case "83 E9" : Instr = "sub    ecx, " : nb_instr = 1
      Case "83 EC" : Instr = "sub    esp, " : nb_instr = 1
      Case "83 F8" : Instr = "cmp    eax, " : nb_instr = 1
      Case "83 FB" : Instr = "cmp    ebx, " : nb_instr = 1
      
      Case "85 C0" : Instr = "test   eax, eax"
      Case "85 D2" : Instr = "test   edx, edx"
      Case "85 F6" : Instr = "test   esi, esi"

      Case "88 88" : Instr = "mov    [eax+" : nb_instr = 4 : value = #x86_IsAddREG : Register = "], cl"

      Case "89 01" : Instr = "mov    [ecx], eax"
      Case "89 04" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "89 10" : Instr = "mov    [eax], edx"
      Case "89 0D" : Instr = "mov    " : nb_instr = 4 : value = #x86_IsAdress : Register = ", ecx"
      Case "89 15" : Instr = "mov    " : nb_instr = 4 : value = #x86_IsAdress : Register = ", edx"
      Case "89 1C" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "89 1D" : Instr = "mov    " : nb_instr = 4 : value = #x86_IsAdress : Register = ", ebx"
      
      Case "89 44" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "89 45" : Instr = "mov    [ebp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "], eax"
      Case "89 4C" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      
      Case "89 54" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "89 5C" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "89 5D" : Instr = "mov    [ebp-" : nb_instr = 1 : value = #x86_IsSubREG : Register = "], ebx"
      
      Case "89 74" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      
      Case "89 75" : Instr = "mov    [ebp-" : nb_instr = 1 : value = #x86_IsSubREG : Register = "], esi"
      Case "89 C2" : Instr = "mov    edx, eax"
      Case "89 C3" : Instr = "mov    ebx, eax"
      Case "89 D3" : Instr = "mov    ebx, edx"
      Case "89 D8" : Instr = "mov    eax, ebx"
      Case "89 E0" : Instr = "mov    eax, esp"
      Case "89 E1" : Instr = "mov    ecx, esp"
      Case "89 E5" : Instr = "mov    ebp, esp"
      Case "89 EC" : Instr = "mov    esp, ebp" 
      Case "89 F1" : Instr = "mov    ecx, esi"

      Case "8A 0B" : Instr = "mov    cl, byte [ebx]"
      
      Case "8B 00" : Instr = "mov    eax, [eax]"
      Case "8B 02" : Instr = "mov    eax, [edx]"
      Case "8B 08" : Instr = "mov    ecx, [eax]"
      Case "8B 0C" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "8B 14" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "8B 15" : Instr = "mov    edx, " : nb_instr = 4 : value = #x86_IsPointer
      Case "8B 1C" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "8B 1D" : Instr = "mov    ebx, " : nb_instr = 4 : value = #x86_IsPointer
      Case "8B 2D" : Instr = "mov    ebp, " : nb_instr = 4 : value = #x86_IsPointer
      Case "8B 44" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "8B 45" : Instr = "mov    eax, [ebp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"
      Case "8B 4D" : Instr = "mov    ecx, [ebp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"
      Case "8B 54" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "8B 55" : Instr = "mov    edx, [ebp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"
      Case "8B 5C" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "8B 5D" : Instr = "mov    ebx, [ebp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"
      Case "8B 75" : Instr = "mov    esi, [ebp-" : nb_instr = 1 : value = #x86_IsSubREG : Register = "]"
      Case "8B 7C" : GetPrevOpCode() : value = #x86_IsThirdOpCode

      Case "8D 0C" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "8D 0D" : Instr = "lea    ecx, " : nb_instr = 4
      Case "8D 4C" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "8D 4D" : Instr = "lea    ecx, [ebp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"

      Case "8D 5D" : Instr = "lea    ebx, [ebp-" : nb_instr = 1 : value = #x86_IsSubREG : Register = "]"
      Case "8D B6" : Instr = "lea    ecx, [esi+" : nb_instr = 4 : value = #x86_IsAddREG : Register = "]"
      Case "8D BC" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      
      Case "8F 05" : Instr = "pop    " : nb_instr = 4 : value = #x86_IsPointer
      Case "8F 45" : Instr = "pop    [ebp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"

      Case "C1 E3" : Instr = "shl    ebx, " : nb_instr = 1
      
      Case "C6 00" : Instr = "mov    byte [eax], " : nb_instr = 1
      Case "C6 46" : Instr = "mov    byte [esi+" : nb_instr = 2 : value = #x86_IsAddREG_Value : Register = "]"
      Case "C6 80" : Instr = "mov    byte [eax+" : nb_instr = 5 : value = #x86_IsAddREG_1_Value : Register = "]"

      Case "C7 00" : Instr = "mov    [eax], " : nb_instr = 4
      Case "C7 04" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "C7 05" : Instr = "mov    " : nb_instr = 8 : value = #x86_IsDblAdress
      Case "C7 40" : Instr = "mov    [eax+" : nb_instr = 5 : value = #x86_IsAddREG_Value : Register = "]"
      Case "C7 44" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      
      Case "C7 45" : Instr = "mov    [ebp+" : nb_instr = 5 : value = #x86_IsAddREG_Value : Register = "]"

      Case "D9 E1" : Instr = "fabs"

      Case "F0 A2" : Instr = "cpuid"
      Case "F3 AA" : Instr = "rep    stos                     ;Byte ptr ES:[edi]"
      
      Case "F7 F1" : Instr = "div    ecx"
      Case "F7 FB" : Instr = "div    ebx"
      
      Case "FF 05" : Instr = "inc    " : nb_instr = 4 : value = #x86_IsPointer
      Case "FF 0D" : Instr = "dec    " : nb_instr = 4 : value = #x86_IsPointer

      Case "FF 15" : Instr = "call   " : nb_instr = 4 : value = #x86_IsJumpPtr
      Case "FF 30" : Instr = "push   [eax]"
      Case "FF 34" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "FF 35" : Instr = "push   " : nb_instr = 4 : value = #x86_IsPointer
      Case "FF 44" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "FF 4C" : GetPrevOpCode() : value = #x86_IsThirdOpCode

      Case "FF 73" : Instr = "push    [ebx+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"
      Case "FF 74" : GetPrevOpCode() : value = #x86_IsThirdOpCode
      Case "FF 75" : Instr = "push   [ebp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"

      Case "FF D0" : Instr = "call   eax"
      Default : Instr = "db     " + ReplaceString(OpCode," ",",")
    EndSelect
  EndIf

  If value = #x86_IsThirdOpCode
    Third_Instr$ = instr+" "+GetNextOpCode()+" "+GetNextOpCode()
    Count_EIP + 2
    Opcode = Third_Instr$
    Select Third_Instr$
      Case "01 14 24" : Instr = "add    [esp], edx"
      Case "01 54 24" : Instr = "add    [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "], edx"

      Case "03 5C 24" : Instr = "add    ebx, [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"
      Case "03 7C 24" : Instr = "add    edi, [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"

      Case "2B 5C 24" : Instr = "sub    ebx, [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"

      Case "3B 04 24" : Instr = "cmp    eax, [esp]"
      Case "3B 1C 24" : Instr = "cmp    ebx, [esp]"
      Case "3B 44 24" : Instr = "cmp    eax, [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"
      Case "3B 5C 24" : Instr = "cmp    ebx, [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"

      Case "83 7C 24" : Instr = "cmp    [esp+" : nb_instr = 2 : value = #x86_IsAddREG_Value : Register = "]"

      Case "89 04 24" : Instr = "mov    [esp], eax"
      Case "89 1C 24" : Instr = "add    [esp], ebx"

      Case "89 44 24" : Instr = "mov    [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "], eax"
      Case "89 4C 24" : Instr = "mov    [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "], ecx"
      Case "89 54 24" : Instr = "mov    [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "], edx"
      Case "89 5C 24" : Instr = "mov    [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "], ebx"
      Case "89 74 24" : Instr = "mov    [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "], esi"

      Case "8B 0C 24" : Instr = "mov    ecx, [esp]"
      Case "8B 1C 24" : Instr = "mov    ebx, [esp]"
      Case "8B 14 24" : Instr = "mov    edx, [esp]"

      Case "8B 44 24" : Instr = "mov    eax, [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"
      Case "8B 54 1D" : Instr = "mov    edx, [ebx+ebp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"
      Case "8B 54 24" : Instr = "mov    edx, [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"
      Case "8B 5C 24" : Instr = "mov    ebx, [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"
      Case "8B 7C 24" : Instr = "mov    edi, [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"

      Case "8D 0C 24" : Instr = "lea    ecx, [esp]"
      Case "8D 4C 1D" : Instr = "lea    ecx, [ebx+esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"
      Case "8D 4C 24" : Instr = "lea    ecx, [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"

      Case "8D BC 27" : Instr = "lea    edi, [edi+" : nb_instr = 4 : value = #x86_IsAddREG : Register = "]"
      
      Case "C7 04 24" : Instr = "mov    [esp], " : nb_instr = 4
      Case "C7 44 24" : Instr = "mov    [esp+" : nb_instr = 5 : value = #x86_IsAddREG_Value : Register = "]"

      Case "DB 44 24" : Instr = "fild   [esp-" : nb_instr = 1 : value = #x86_IsSubREG : Register = "]"
      Case "DB 5C 24" : Instr = "fistp  [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"

      Case "FF 34 24" : Instr = "push   [esp]"
      Case "FF 44 24" : Instr = "inc    [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"
      Case "FF 4C 24" : Instr = "dec    [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"

      Case "FF 74 1D" : Instr = "push   [ebx+ebp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"
      Case "FF 74 24" : Instr = "push   [esp+" : nb_instr = 1 : value = #x86_IsAddREG : Register = "]"

      Default : Instr = "db     " + ReplaceString(OpCode," ",",")
    EndSelect
  EndIf
  
  Select nb_instr

    Case 0 :
      Instruction = instr
    Case 1 :
      Count_EIP + 1
      Instruction = instr
      OpCode1$ = GetNextOpCode()
      
      If value = #x86_IsRegister
        Select OpCode1$
          Case "00" : register$ = TAB_Register(#EAX,REGISTER_TYPE)
          Case "01" : register$ = TAB_Register(#ECX,REGISTER_TYPE)
          Case "02" : register$ = TAB_Register(#EDX,REGISTER_TYPE)
          Case "03" : register$ = TAB_Register(#ECX,REGISTER_TYPE)
          Case "04" : register$ = TAB_Register(#ESP,REGISTER_TYPE)
          Case "05" : register$ = TAB_Register(#EBP,REGISTER_TYPE)
          Case "06" : register$ = TAB_Register(#ESI,REGISTER_TYPE)
          Case "07" : register$ = TAB_Register(#EDI,REGISTER_TYPE)
          Default: register$ = "???"
        EndSelect
        ;register$ = UCase(register$)
        Instruction + "    [" + register$ + "], al"
        OpCode + " " + OpCode1$
      Else
        Instruction + #Prefix + OpCode1$
        OpCode + " " + OpCode1$
      EndIf
      
      If value = #x86_IsSubREG
        vTmp = HexVal(OpCode1$)
        vTmp = $FF - vTmp + 1
        OpCode1$ = #Prefix + RSet(Hex(vTmp),2,"0")
        Instruction = Instr + OpCode1$ + Register
      EndIf

      If value = #x86_IsAddREG
        vTmp = HexVal(OpCode1$)
        OpCode1$ = #Prefix + RSet(Hex(vTmp),2,"0")
        Instruction = Instr + OpCode1$ + Register
      EndIf

      If value = #x86_IsJump
        vTmp = HexVal(OpCode1$)
        If vTmp > $7F
          vTmp = Count_EIP - ($FF - vTmp)
        Else
          vTmp + Count_EIP + 1          ;ajout 1 pour l'instruction
        EndIf
        OpCode1$ = #Prefix + RSet(Hex(vTmp),8,"0")
        Instruction = Instr + OpCode1$
      EndIf
    Case 2 :
      Count_EIP + 2
      Instruction = instr
      OpCode1$ = GetNextOpCode()
      OpCode2$ = GetNextOpCode()
      OpCode + " " + OpCode1$ + " " + OpCode2$
      Instruction + #Prefix + OpCode2$ + OpCode1$

      If value = #x86_IsAddREG_Value
        Instruction = Instr + #Prefix+ OpCode1$ + register + ", " + #Prefix + OpCode2$
      EndIf
    Case 3 :
      Count_EIP + 3
      Instruction = instr
      OpCode1$ = GetNextOpCode()
      OpCode2$ = GetNextOpCode()
      OpCode3$ = GetNextOpCode()
      OpCode + " " + OpCode1$ + " " + OpCode2$ + " " + OpCode3$ + " "
      Instruction + #Prefix + OpCode3$ + OpCode2$ + OpCode1$

      If value = #x86_IsAddREG_Value
        Instruction = Instr + #Prefix + OpCode1$ + OpCode2$ + ", " + #Prefix + OpCode3$ + Rem$
      EndIf
    Case 4 :
      Count_EIP + 4
      Instruction = instr
      OpCode1$ = GetNextOpCode()
      OpCode2$ = GetNextOpCode()
      OpCode3$ = GetNextOpCode()
      OpCode4$ = GetNextOpCode()
      OpCode + " " + OpCode1$ + " " + OpCode2$ + " " + OpCode3$ + " " + OpCode4$
      vTmp$ = OpCode4$ + OpCode3$ + OpCode2$ + OpCode1$
      Instruction + #Prefix + vTmp$
      
      If value = #x86_IsSubREG
        vTmp = HexVal(vTmp$)
        vTmp = $FFFFFFFF - vTmp + 1
        vTmp$ = #Prefix + RSet(Hex(vTmp),8,"0")
        Instruction = Instr + vTmp$ + Register
      EndIf

      If value = #x86_IsAddREG
        vTmp = HexVal(vTmp$)
        vTmp$ = #Prefix + RSet(Hex(vTmp),8,"0")
        Instruction = Instr + vTmp$ + Register
      EndIf

      If value = #x86_IsJump Or value = #x86_IsJumpPtr
        vTmp = HexVal(vTmp$)
        If vTmp > $7FFFFFFF
          vTmp = Count_EIP - ($FFFFFFFF - vTmp)
        Else
          vTmp + Count_EIP + 1          ;ajout 1 pour l'instruction
        EndIf
        vTmp$ = RSet(Hex(vTmp),8,"0")
        If value = #x86_IsJumpPtr : vTmp$ = OpCode4$ + OpCode3$ + OpCode2$ + OpCode1$ : EndIf
        Instruction = Instr + #Prefix + vTmp$
      EndIf
      
      If Value = #x86_IsAdress
        Instruction = Instr + "[" + #Prefix + vTmp$ + "]" + Register
      EndIf
      
      If Value = #x86_IsPointer Or value = #x86_IsJumpPtr
        Instruction = Instr + "[" + #Prefix + vTmp$ + "]"
      EndIf
      
    Case 5 :
      Count_EIP + 5
      Instruction = instr
      OpCode1$ = GetNextOpCode()
      OpCode2$ = GetNextOpCode()
      OpCode3$ = GetNextOpCode()
      OpCode4$ = GetNextOpCode()
      OpCode5$ = GetNextOpCode()
      
      OpCode + " " + OpCode1$ + " " + OpCode2$ + " " + OpCode3$ + " " + OpCode4$ + " " + OpCode5$
      Instruction + #Prefix + OpCode5$ + OpCode4$ + OpCode3$ + OpCode2$ + OpCode1$

      If value = #x86_IsAddREG_Value
        Instruction = Instr + #Prefix+ OpCode1$ + register + ", " + #Prefix + OpCode5$ + OpCode4$ + OpCode3$ + OpCode2$
      EndIf

      If value = #x86_IsAddREG_1_Value
        Instruction = Instr + #Prefix+ OpCode4$ + OpCode3$ + OpCode2$ + Opcode1$ + "], " + #Prefix + OpCode5$
      EndIf

      If value = #x86_IsDblAdress
        Instruction = Instr + "[" + #Prefix + OpCode4$ + OpCode3$ + OpCode2$ + OpCode1$ + "]" + ", "
        Instruction + #Prefix + OpCode5$
      EndIf
    Case 6 :
      Count_EIP + 6
      Instruction = instr
      OpCode1$ = GetNextOpCode()
      OpCode2$ = GetNextOpCode()
      OpCode3$ = GetNextOpCode()
      OpCode4$ = GetNextOpCode()
      OpCode5$ = GetNextOpCode()
      OpCode6$ = GetNextOpCode()
      vTmp$ = ""
      OpCode + " " + OpCode1$ + " " + OpCode2$ + " " + OpCode3$ + " " + OpCode4$ + " " + OpCode5$ + " " + OpCode6$
      Instruction + #Prefix + OpCode6$ + OpCode5$ + OpCode4$ + OpCode3$ + OpCode2$ + OpCode1$
    Case 8 :
      Count_EIP + 8
      Instruction = instr
      OpCode1$ = GetNextOpCode()
      OpCode2$ = GetNextOpCode()
      OpCode3$ = GetNextOpCode()
      OpCode4$ = GetNextOpCode()
      OpCode5$ = GetNextOpCode()
      OpCode6$ = GetNextOpCode()
      OpCode7$ = GetNextOpCode()
      OpCode8$ = GetNextOpCode()
      OpCode + " " + OpCode1$ + " " + OpCode2$ + " " + OpCode3$ + " " + OpCode4$ + " "
      OpCode + OpCode5$ + " " + OpCode6$ + " " + OpCode7$ + " " + OpCode8$
      Instruction + "[" + #Prefix + OpCode4$ + OpCode3$ + OpCode2$ + OpCode1$ + "]" + ", "
      Instruction + #Prefix + OpCode8$ + OpCode7$ + OpCode6$ + OpCode5$
    Default :
      Instruction = instr
  EndSelect
  
EndProcedure

Procedure Dump()

  If _DISASSEMBLING = #False
    ResetList(DumpF())
    ForEach DumpF()
      PrintN(DumpF()\hex+"- "+DumpF()\chr)
    Next
  Else
    ResetList(Disassm())
    ForEach Disassm()
      OpCode = Disassm()\OpCode
      Register = ""
      
      EIP$ = RSet(Hex(Count_EIP),#LINE_8,"0") + ":"
      
      Select OpCode
        Case "00" : Emit_Instr("add",1,#x86_IsRegister)
        Case "01" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        Case "03" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        Case "04" : Emit_Instr("add    al, ",1)
        Case "05" : Emit_Instr("add    ax, ",2)
        Case "06" : Emit_Instr("push   es")
        Case "07" : Emit_Instr("pop    es")
        Case "09" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        Case "0D" : Emit_Instr("or     ax,",2)
        Case "0E" : Emit_Instr("push   cs")
        Case "0F" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        Case "1F" : Emit_Instr("pop    ds")
        Case "21" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        Case "25" : Emit_Instr("and    eax, ",4)
        Case "29" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        Case "2B" : Emit_Instr(OpCode,0,#x86_IsThirdOpCode)

        Case "31" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        Case "39" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)

        Case "3B" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)

        Case "3D" : Emit_Instr("cmp    eax, ",4)
        
        Case "40" : Emit_Instr("inc    eax")
        Case "41" : Emit_Instr("inc    ecx")
        Case "42" : Emit_Instr("inc    edx")
        Case "43" : Emit_Instr("inc    ebx")
        Case "44" : Emit_Instr("inc    esp")
        Case "45" : Emit_Instr("inc    ebp")
        Case "46" : Emit_Instr("inc    esi")
        Case "47" : Emit_Instr("inc    edi")
        
        Case "48" : Emit_Instr("dec    eax")
        Case "49" : Emit_Instr("dec    ecx")
        Case "4A" : Emit_Instr("dec    edx")
        Case "4B" : Emit_Instr("dec    ebx")
        Case "4C" : Emit_Instr("dec    esp")
        Case "4D" : Emit_Instr("dec    ebp")
        Case "4E" : Emit_Instr("dec    esi")
        Case "4F" : Emit_Instr("dec    edi")
        
        Case "50" : Emit_Instr("push   eax")
        Case "51" : Emit_Instr("push   ecx")
        Case "52" : Emit_Instr("push   edx")
        Case "53" : Emit_Instr("push   ebx")
        Case "54" : Emit_Instr("push   esp")
        Case "55" : Emit_Instr("push   ebp")
        Case "56" : Emit_Instr("push   esi")
        Case "57" : Emit_Instr("push   edi")
        
        Case "58" : Emit_Instr("pop    eax")
        Case "59" : Emit_Instr("pop    ecx")
        Case "5A" : Emit_Instr("pop    edx")
        Case "5B" : Emit_Instr("pop    ebx")
        Case "5C" : Emit_Instr("pop    esp")
        Case "5D" : Emit_Instr("pop    ebp")
        Case "5E" : Emit_Instr("pop    esi")
        Case "5F" : Emit_Instr("pop    edi")
        
        Case "6A" : Emit_Instr("push   ",1)
        Case "6B" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        Case "68" : Emit_Instr("push   ",4)
        
        Case "72" : Emit_Instr("jc     ",1,#x86_IsJump)
        Case "73" : Emit_Instr("jnb    ",1,#x86_IsJump)
        Case "74" : Emit_Instr("je     ",1,#x86_IsJump)
        Case "75" : Emit_Instr("jne    ",1,#x86_IsJump)
        Case "76" : Emit_Instr("jna    ",1,#x86_IsJump)
        Case "77" : Emit_Instr("jnbe   ",1,#x86_IsJump)
        Case "7C" : Emit_Instr("jnge   ",1,#x86_IsJump)
        Case "7D" : Emit_Instr("jnl    ",1,#x86_IsJump)
        Case "7E" : Emit_Instr("jng    ",1,#x86_IsJump)
        Case "7F" : Emit_Instr("jnle   ",1,#x86_IsJump)
        
        Case "81" : Emit_Instr(OpCode,4,#x86_IsSecondOpCode)
        Case "83" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        Case "85" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        Case "88" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        Case "89" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        
        Case "8A" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        Case "8B" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        Case "8D" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        Case "8F" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        
        Case "90" : Emit_Instr("nop")
        Case "99" : Emit_Instr("cltd")
        
        Case "A1" : Emit_Instr("mov    eax, ",4,#x86_IsPointer)
        Case "A3" : Register = ", eax" : Emit_Instr("mov    ",4,#x86_IsAdress)
        
        Case "B0" : Emit_Instr("mov    al, ",1)
        Case "B8" : Emit_Instr("mov    eax, ",4)
        Case "B9" : Emit_Instr("mov    ecx, ",4)
        Case "BA" : Emit_Instr("mov    edx, ",4)
        Case "BB" : Emit_Instr("mov    ebx, ",4)
        Case "BE" : Emit_Instr("mov    esi, ",4)
        Case "BF" : Emit_Instr("mov    edi, ",4)
        
        Case "C1" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        Case "C2" : Emit_Instr("ret    ",2)
        Case "C3" : Emit_Instr("ret")
        
        Case "C6" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        Case "C7" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        
        Case "C8" : Emit_Instr("enter  ",3,#x86_IsAddREG_Value,Chr(9)+Chr(9)+";Creates a stack frame for a procedure (HLL)")
        Case "C9" : Emit_Instr("leave")
        Case "CD" : Emit_Instr("int    ",1)
        
        Case "D9" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)

        Case "DB" : Emit_Instr(OpCode,0,#x86_IsThirdOpCode)

        Case "E8" : Emit_Instr("call   ",4,#x86_IsJump)
        Case "E9" : Emit_Instr("jmp    ",4,#x86_IsJump)
        Case "EB" : Emit_Instr("jmp    ",1,#x86_IsJump)
        
        Case "F3" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)

        Case "F7" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        Case "F8" : Emit_Instr("clc")
        Case "FA" : Emit_Instr("cli")
        Case "FC" : Emit_Instr("cld")
        Case "FF" : Emit_Instr(OpCode,0,#x86_IsSecondOpCode)
        Default   : Emit_Instr("db     " + OpCode)
      EndSelect
      
      Count_EIP + 1

      t$ = Chr(9) + Chr(9) + Chr(9) + Chr(9)
      If Len(OpCode) > 6 : t$ = Chr(9) + Chr(9) + Chr(9) : EndIf
      If Len(OpCode) > 14 : t$ = Chr(9) + Chr(9) : EndIf
      If Len(OpCode) > 20 : t$ = Chr(9) : EndIf
      
      AddElement(DisassLine())
        DisassLine()\Line = EIP$ + OpCode + t$ + Instruction
        
    Next
    
    ResetList(DisassLine())
      ForEach DisassLine()
        PrintN(DisassLine()\Line)
      Next
      
  EndIf
  
EndProcedure

Procedure Print_Version()
  PrintN("Dumpf "+#VERSION+" : Dump file in hexa")
EndProcedure

Procedure Print_Usage()
  PrintN("usage: dumpf [OPTION] file")
  PrintN("")
  PrintN("  Option :")
  PrintN("    -h               : this help")
  PrintN("    -v               : program version")
  PrintN("    -l               : print the licence")
  PrintN("")
  PrintN("    -t [VAL]         : Dump to [VAL] bytes per line (default = 16)")
  PrintN("    -d               : Disassemble")
  PrintN("    -d 0x00F00501... : Disassemble immediate value")
  PrintN("                       (It's important to start with "+#QUOTE+"0x"+#QUOTE+")")
EndProcedure

Procedure print_licence()
 	CompilerIf #PB_Compiler_OS = #PB_OS_Windows
 	  ConsoleColor(#BROWN,0)
    HG$ = Chr(218) : MH$ = Chr(196) :HD$ = Chr(191)
    MV$ = Chr(179)
    BG$ = Chr(192) : BD$ = Chr(217)
  CompilerElse
    HG$ = "+" : MH$ = "-" :HD$ = "+"
    MV$ = "|"
    BG$ = "+" : BD$ = "+" 
  CompilerEndIf

  Print(HG$):For i = 1 To 69:Print(MH$):Next i:PrintN(HD$)
  Print(MV$+" "):Print("                                                                   "):PrintN(" "+MV$)
  Print(MV$+" "):Print(" Flaith (Nicolas Djurovic) - 2007                                  "):PrintN(" "+MV$)
  Print(MV$+" "):Print("                                                                   "):PrintN(" "+MV$)
  Print(MV$+" "):Print(" This software is provided 'as-is', without any express or implied "):PrintN(" "+MV$)
  Print(MV$+" "):Print(" warranty. In no event will the author be held liable for any      "):PrintN(" "+MV$)
  Print(MV$+" "):Print(" damages arising from the use of this software.                    "):PrintN(" "+MV$)
  Print(MV$+" "):Print("                                                                   "):PrintN(" "+MV$)
  Print(MV$+" "):Print(" Permission is granted to anyone to use this software for any      "):PrintN(" "+MV$)
  Print(MV$+" "):Print(" purpose, including commercial applications, and to alter it and   "):PrintN(" "+MV$)
  Print(MV$+" "):Print(" redistribute it freely, subject to the following restrictions:    "):PrintN(" "+MV$)
  Print(MV$+" "):Print("                                                                   "):PrintN(" "+MV$)
  Print(MV$+" "):Print("     1. The origin of this software must not be misrepresented;    "):PrintN(" "+MV$)
  Print(MV$+" "):Print("        you must not claim that you wrote the original software.   "):PrintN(" "+MV$)
  Print(MV$+" "):Print("        If you use this software in a product, an acknowledgment   "):PrintN(" "+MV$)
  Print(MV$+" "):Print("        in the product documentation would be appreciated but is   "):PrintN(" "+MV$)
  Print(MV$+" "):Print("        not required.                                              "):PrintN(" "+MV$)
  Print(MV$+" "):Print("                                                                   "):PrintN(" "+MV$)
  Print(MV$+" "):Print("     2. Altered source versions must be plainly marked as such,    "):PrintN(" "+MV$)
  Print(MV$+" "):Print("        and must not be misrepresented as being the original       "):PrintN(" "+MV$)
  Print(MV$+" "):Print("        software.                                                  "):PrintN(" "+MV$)
  Print(MV$+" "):Print("                                                                   "):PrintN(" "+MV$)
  Print(MV$+" "):Print("     3. This notice may not be removed or altered from any source  "):PrintN(" "+MV$)
  Print(MV$+" "):Print("        distribution.                                              "):PrintN(" "+MV$)
  Print(MV$+" "):Print("                                                                   "):PrintN(" "+MV$)
  Print(BG$):For i = 1 To 69:Print(MH$):Next i:PrintN(BD$)

  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  	ConsoleColor(15,0)
  CompilerEndIf
EndProcedure

Procedure Main(taille.l=16)
Protected file.s							        ; Nom du fichier à ouvrir
Protected argc.l

  _VAL = #False
  _DISASSEMBLING = #False
  _IMMEDIATE_VALUE = #False
  argc = GET_Argv()
  file = argv(0)
  Count_EIP = $00400C00  ; le désassemblage commence à ... 4197376
  
  If argv(0) = ""                       ; Pas d'autres arguments
    Print_Version()
    Print_Usage()
    End
  Else                                  ; il y a d'autres arguments
    For i = 0 To argc
      If Left(argv(i),1) <> "-"         ; ce n'est pas une option
        Break
      EndIf
      Select LCase(Mid(argv(i),2,1))    ; c'est une option
        Case "t"
          _VAL = #True
          taille = Val(argv(1))
          file = argv(2)
          If taille <= 0 : taille = 1 : EndIf
        Case "d"
          _DISASSEMBLING = #True
          _VAL = #False
          file = argv(1)
        Case "v"
          Print_Version()
          End
        Case "h"
          Print_Version()
          Print_Usage()
          End
        Case "l"
          print_licence()
          End
        Default
          PrintN(">>> ERROR : Unknow option "+#QUOTE+Mid(argv(i),2,Len(argv(i))-1)+#QUOTE)
          Print_Usage()
          End
      EndSelect
	  Next i
  EndIf
  
  Restore dRegister
  For nb_Type = 0 To #REGISTER_QUADWORD
    For nb_Reg = 0 To #EDI
      Read dRegister$
      TAB_Register(nb_Reg,nb_Type) = dRegister$
      ;PrintN(Str(nb_Reg)+" "+Str(nb_Type)+" = "+dRegister$)
    Next
  Next
  
;   If CreateFile(#DebugFile,"DEBUG.LOG")
;     WriteStringN(#DebugFile,"DEBUG LOG :"+FormatDate("%dd/%mm/%yy - %hh:%ii:%ss",Date()))
;     WriteStringN(#DebugFile,"----")
;   EndIf

  If file = "" : PrintN("You must specify a filename or an immediate value") : End : EndIf
  
  If UCase(Left(file,2)) = "0X" And _DISASSEMBLING = #True
    _IMMEDIATE_VALUE = #True
  EndIf
  
  If Load_File(file,taille) = -1 And _IMMEDIATE_VALUE = #False
    PrintN("Error loading file:"+file)
    End
  Else
    Dump()
  EndIf

;   CloseFile(#DebugFile)
   
EndProcedure

OpenConsole()
Main()
CloseConsole()
End

DataSection
  dRegister:
    Data.s "al", "cl", "dl", "bl", "ah", "ch", "dh", "bh"
    Data.s "ax", "cx", "dx", "bx", "sp", "bp", "si", "di"
    Data.s "eax","ecx","edx","ebx","esp","ebp","esi","edi"
    Data.s "rax","rcx","rdx","rbx","",   "",   "",   ""
EndDataSection
; IDE Options = PureBasic 4.10 Beta 3 (Linux - x86)
; CursorPosition = 889
; FirstLine = 851
; Folding = ---
; DisableDebugger