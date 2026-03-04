; English to Metric Converter
; Converts common English measurements to metric units

EnableExplicit

#APP_NAME = "UnitCalc"

Global version.s = "v1.0.0.1"
Global AppPath.s = GetPathPart(ProgramFilename())
If AppPath = "" : AppPath = GetCurrentDirectory() : EndIf
SetCurrentDirectory(AppPath)

; --- Constants and Structures ---

Structure ConversionUnit
  Name.s
  Units.s  ; Pipe-separated list of recognized units
  Factor.f ; Factor to base unit (m, kg, L, C, etc)
  Offset.f ; Offset for temperature
EndStructure

Structure ConversionGroup
  GroupName.s
  BaseUnit.s
  List English.ConversionUnit()
  List Metric.ConversionUnit()
EndStructure

Global NewList ConversionGroups.ConversionGroup()

; --- Initialization ---

Procedure AddUnit(List TargetList.ConversionUnit(), Name.s, Units.s, Factor.f, Offset.f = 0.0)
  AddElement(TargetList())
  TargetList()\Name = Name
  TargetList()\Units = Units
  TargetList()\Factor = Factor
  TargetList()\Offset = Offset
EndProcedure

Procedure InitConversions()
  ; Length
  AddElement(ConversionGroups())
  ConversionGroups()\GroupName = "Length"
  ConversionGroups()\BaseUnit = "m"
  AddUnit(ConversionGroups()\English(), "Inches", "in|inch|inches", 0.0254)
  AddUnit(ConversionGroups()\English(), "Feet", "ft|foot|feet|'", 0.3048)
  AddUnit(ConversionGroups()\English(), "Yards", "yd|yard|yards", 0.9144)
  AddUnit(ConversionGroups()\English(), "Miles", "mi|mile|miles", 1609.34)
  AddUnit(ConversionGroups()\Metric(), "Millimeters", "mm|millimeter|millimeters", 0.001)
  AddUnit(ConversionGroups()\Metric(), "Centimeters", "cm|centimeter|centimeters", 0.01)
  AddUnit(ConversionGroups()\Metric(), "Meters", "m|meter|meters", 1.0)
  AddUnit(ConversionGroups()\Metric(), "Kilometers", "km|kilometer|kilometers", 1000.0)

  ; Mass
  AddElement(ConversionGroups())
  ConversionGroups()\GroupName = "Mass"
  ConversionGroups()\BaseUnit = "kg"
  AddUnit(ConversionGroups()\English(), "Ounces", "oz|ounce|ounces", 0.0283495)
  AddUnit(ConversionGroups()\English(), "Pounds", "lb|lbs|pound|pounds", 0.453592)
  AddUnit(ConversionGroups()\English(), "Stone", "st|stone", 6.35029)
  AddUnit(ConversionGroups()\Metric(), "Milligrams", "mg|milligram|milligrams", 0.000001)
  AddUnit(ConversionGroups()\Metric(), "Grams", "g|gram|grams", 0.001)
  AddUnit(ConversionGroups()\Metric(), "Kilograms", "kg|kilogram|kilograms", 1.0)
  AddUnit(ConversionGroups()\Metric(), "Metric Tons", "t|tonne|tonnes", 1000.0)

  ; Volume
  AddElement(ConversionGroups())
  ConversionGroups()\GroupName = "Volume"
  ConversionGroups()\BaseUnit = "L"
  AddUnit(ConversionGroups()\English(), "Fluid Ounces", "fl oz|floz|fluid ounce", 0.0295735)
  AddUnit(ConversionGroups()\English(), "Cups", "cup|cups", 0.236588)
  AddUnit(ConversionGroups()\English(), "Pints", "pt|pint|pints", 0.473176)
  AddUnit(ConversionGroups()\English(), "Quarts", "qt|quart|quarts", 0.946353)
  AddUnit(ConversionGroups()\English(), "Gallons", "gal|gallon|gallons", 3.78541)
  AddUnit(ConversionGroups()\Metric(), "Milliliters", "ml|milliliter|milliliters", 0.001)
  AddUnit(ConversionGroups()\Metric(), "Liters", "l|liter|liters|litre|litres", 1.0)

  ; Temperature (Special case, requires offset)
  AddElement(ConversionGroups())
  ConversionGroups()\GroupName = "Temperature"
  ConversionGroups()\BaseUnit = "C"
  AddUnit(ConversionGroups()\English(), "Fahrenheit", "f|fahr|fahrenheit|deg f", 5.0/9.0, -32.0)
  AddUnit(ConversionGroups()\Metric(), "Celsius", "c|cel|celsius|deg c", 1.0, 0.0)
  AddUnit(ConversionGroups()\Metric(), "Kelvin", "k|kelvin", 1.0, -273.15)

  ; Area
  AddElement(ConversionGroups())
  ConversionGroups()\GroupName = "Area"
  ConversionGroups()\BaseUnit = "m2"
  AddUnit(ConversionGroups()\English(), "Square Inches", "sq in|sqin", 0.00064516)
  AddUnit(ConversionGroups()\English(), "Square Feet", "sq ft|sqft", 0.092903)
  AddUnit(ConversionGroups()\English(), "Acres", "acre|acres", 4046.86)
  AddUnit(ConversionGroups()\Metric(), "Square Meters", "m2|sqm", 1.0)
  AddUnit(ConversionGroups()\Metric(), "Hectares", "ha|hectare", 10000.0)

  ; Speed
  AddElement(ConversionGroups())
  ConversionGroups()\GroupName = "Speed"
  ConversionGroups()\BaseUnit = "m/s"
  AddUnit(ConversionGroups()\English(), "Miles per Hour", "mph", 0.44704)
  AddUnit(ConversionGroups()\English(), "Knots", "kt|knot|knots", 0.514444)
  AddUnit(ConversionGroups()\Metric(), "Kilometers per Hour", "kph|km/h", 0.277778)
  AddUnit(ConversionGroups()\Metric(), "Meters per Second", "m/s|mps", 1.0)
EndProcedure

InitConversions()

; --- Application State ---

Global mode.i = 0 ; 0 = English to Metric, 1 = Metric to English
Global done.i = 0
Global NewList history.s()
Global logFile.s = AppPath + #APP_NAME + "_history.log"

; --- Utility Functions ---

Procedure.s DateTimeStamp()
  ProcedureReturn FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date())
EndProcedure

Procedure LogConversion(line.s)
  Protected fileId.i
  fileId = OpenFile(#PB_Any, logFile)
  If fileId
    FileSeek(fileId, Lof(fileId))
    WriteStringN(fileId, DateTimeStamp() + "  " + line)
    CloseFile(fileId)
  EndIf
EndProcedure

Procedure.s NormalizeNumericPart(input.s)
  Protected cleaned.s = Trim(input)
  cleaned = ReplaceString(cleaned, ",", "")
  Protected i.i, char.s, result.s = ""
  Protected foundNumeric.i = #False
  
  For i = 1 To Len(cleaned)
    char = Mid(cleaned, i, 1)
    If FindString("0123456789.+-eE", char)
      result + char
      foundNumeric = #True
    ElseIf foundNumeric
      Break
    EndIf
  Next
  
  ProcedureReturn Trim(result)
EndProcedure

Procedure.s NormalizeUnitSuffix(input.s)
  Protected s.s = LCase(Trim(input))
  Protected i.i, char.s, startIdx.i = 0
  
  For i = 1 To Len(s)
    char = Mid(s, i, 1)
    If FindString("0123456789.+-eE, ", char) = 0
      startIdx = i
      Break
    EndIf
  Next
  
  If startIdx = 0 : ProcedureReturn "" : EndIf
  
  s = Mid(s, startIdx)
  s = Trim(s)
  s = ReplaceString(s, "deg ", "")
  s = ReplaceString(s, "degrees ", "")
  ProcedureReturn s
EndProcedure

Procedure.i UnitMatches(unit.s, expectedUnits.s)
  Protected needle.s = "|" + LCase(unit) + "|"
  ProcedureReturn Bool(FindString("|" + LCase(expectedUnits) + "|", needle, 1) > 0)
EndProcedure

Procedure.f GetInputValue(prompt.s)
  Protected tmp.s
  Print(prompt)
  Repeat
    tmp = Trim(Input())
    If tmp = ""
      Print("Please enter a value: ")
      Continue
    EndIf
    Protected valStr.s = NormalizeNumericPart(tmp)
    If valStr = ""
        Print("Invalid number. Please enter a value: ")
        Continue
    EndIf
    ProcedureReturn ValF(valStr)
  ForEver
EndProcedure

; --- Conversion Logic ---

Procedure.f PerformConversion(inputVal.f, groupIdx.i, unitIdx.i, fromMetric.i, *outUnitName.String)
  Protected baseVal.f
  SelectElement(ConversionGroups(), groupIdx)
  
  If fromMetric
    SelectElement(ConversionGroups()\Metric(), unitIdx)
    baseVal = (inputVal + ConversionGroups()\Metric()\Offset) * ConversionGroups()\Metric()\Factor
    FirstElement(ConversionGroups()\English())
    If *outUnitName : *outUnitName\s = ConversionGroups()\English()\Name : EndIf
    If ConversionGroups()\English()\Factor = 0 : ProcedureReturn 0 : EndIf
    ProcedureReturn (baseVal / ConversionGroups()\English()\Factor) - ConversionGroups()\English()\Offset
  Else
    SelectElement(ConversionGroups()\English(), unitIdx)
    baseVal = (inputVal + ConversionGroups()\English()\Offset) * ConversionGroups()\English()\Factor
    FirstElement(ConversionGroups()\Metric())
    If *outUnitName : *outUnitName\s = ConversionGroups()\Metric()\Name : EndIf
    If ConversionGroups()\Metric()\Factor = 0 : ProcedureReturn 0 : EndIf
    ProcedureReturn (baseVal / ConversionGroups()\Metric()\Factor) - ConversionGroups()\Metric()\Offset
  EndIf
EndProcedure

Procedure.s DoSmartConversion()
  PrintN("Smart conversion (Enter value with unit, e.g., '10 in' or '25 C'):")
  Print("> ")
  Protected input.s = Trim(Input())
  If input = "" : ProcedureReturn "" : EndIf
  
  Protected valueStr.s = NormalizeNumericPart(input)
  Protected unit.s = NormalizeUnitSuffix(input)
  
  If valueStr = "" Or unit = ""
    ProcedureReturn "Invalid input. Format: [value] [unit]"
  EndIf
  
  Protected value.f = ValF(valueStr)
  Protected targetNameStr.String
  Protected res.f
  
  ForEach ConversionGroups()
    ForEach ConversionGroups()\English()
      If UnitMatches(unit, ConversionGroups()\English()\Units)
        res = PerformConversion(value, ListIndex(ConversionGroups()), ListIndex(ConversionGroups()\English()), 0, @targetNameStr)
        ProcedureReturn StrF(value, 2) + " " + unit + " -> " + StrF(res, 2) + " " + targetNameStr\s
      EndIf
    Next
    ForEach ConversionGroups()\Metric()
      If UnitMatches(unit, ConversionGroups()\Metric()\Units)
        res = PerformConversion(value, ListIndex(ConversionGroups()), ListIndex(ConversionGroups()\Metric()), 1, @targetNameStr)
        ProcedureReturn StrF(value, 2) + " " + unit + " -> " + StrF(res, 2) + " " + targetNameStr\s
      EndIf
    Next
  Next
  
  ProcedureReturn "Unknown unit: '" + unit + "'"
EndProcedure

Procedure DisplayMenu()
  ClearConsole()
  PrintN("=== " + #APP_NAME + " ===")
  If mode = 0 : PrintN("Mode: English to Metric") : Else : PrintN("Mode: Metric to English") : EndIf
  PrintN("---------------------------")
  Protected i.i = 1
  ForEach ConversionGroups()
    PrintN("[" + ConversionGroups()\GroupName + "]")
    If mode = 0
      ForEach ConversionGroups()\English()
        PrintN("  " + Str(i) + ". " + ConversionGroups()\English()\Name) : i + 1
      Next
    Else
      ForEach ConversionGroups()\Metric()
        PrintN("  " + Str(i) + ". " + ConversionGroups()\Metric()\Name) : i + 1
      Next
    EndIf
  Next
  PrintN("")
  PrintN("M. Toggle Mode | S. Smart Conv | H. History | 0. Exit")
  PrintN("---------------------------")
EndProcedure

EnableGraphicalConsole(1)
OpenConsole()
ConsoleTitle(#APP_NAME)

While done = 0
  DisplayMenu()
  Print("Choice: ")
  Define choice.s = LCase(Trim(Input()))
  Define choiceVal.i = Val(choice)
  
  If choice = "m"
    mode ! 1
  ElseIf choice = "s"
    Define resLine.s = DoSmartConversion()
    If resLine <> ""
        PrintN("")
        PrintN("Result: " + resLine)
        AddElement(history()) : history() = resLine : LogConversion(resLine)
        PrintN("")
        Print("Press Enter to continue...") : Input()
    EndIf
  ElseIf choice = "h"
    PrintN("")
    PrintN("--- Recent History ---")
    If ListSize(history()) = 0
        PrintN("No history yet.")
    Else
        ForEach history()
            PrintN(history())
        Next
    EndIf
    PrintN("----------------------")
    Print("Press Enter to continue...") : Input()
  ElseIf choiceVal = 0 And choice <> "0"
    ; Refresh
  ElseIf choiceVal = 0
    done = 1
  Else
    Define gIdx.i, uIdx.i, counter.i = 1, found.i = 0
    ForEach ConversionGroups()
      gIdx = ListIndex(ConversionGroups())
      If mode = 0
        ForEach ConversionGroups()\English()
          If counter = choiceVal : uIdx = ListIndex(ConversionGroups()\English()) : found = 1 : Break 2 : EndIf
          counter + 1
        Next
      Else
        ForEach ConversionGroups()\Metric()
          If counter = choiceVal : uIdx = ListIndex(ConversionGroups()\Metric()) : found = 1 : Break 2 : EndIf
          counter + 1
        Next
      EndIf
    Next
    
    If found
      Define val.f = GetInputValue("Enter Value: ")
      Define outNameStr.String
      Define result.f = PerformConversion(val, gIdx, uIdx, mode, @outNameStr)
      resLine = StrF(val, 2) + " -> " + StrF(result, 2) + " " + outNameStr\s
      PrintN("")
      PrintN("Result: " + resLine)
      AddElement(history()) : history() = resLine : LogConversion(resLine)
      Print("") : Print("Press Enter to continue...") : Input()
    EndIf
  EndIf
Wend

CloseConsole()
End

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 7
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = UnitCalc.ico
; Executable = ..\UnitCalc.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,1
; VersionField1 = 1,0,0,1
; VersionField2 = ZoneSSoft
; VersionField3 = UnitCalc
; VersionField4 = 1.0.0.1
; VersionField5 = 1.0.0.1
; VersionField6 = A unit of measurements calculator
; VersionField7 = UnitCalc
; VersionField8 = UnitCalc.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60