; Unit conversion calculator
; Converts between common English and metric measurements

EnableExplicit

#APP_NAME = "UnitCalc"
#SYSTEM_ENGLISH = 0
#SYSTEM_METRIC = 1

Global version.s = "v1.0.0.2"
Global AppPath.s = GetPathPart(ProgramFilename())
If AppPath = "" : AppPath = GetCurrentDirectory() : EndIf
SetCurrentDirectory(AppPath)

; --- Constants and Structures ---

Structure ConversionUnit
  Name.s
  Units.s  ; Pipe-separated list of recognized units
  Factor.f ; Factor to base unit (m, kg, L, C, etc)
  Offset.f ; Offset for temperature-style conversions
EndStructure

Structure ConversionGroup
  GroupName.s
  BaseUnit.s
  List English.ConversionUnit()
  List Metric.ConversionUnit()
EndStructure

Structure UnitChoice
  GroupIdx.i
  System.i
  UnitIdx.i
  Name.s
EndStructure

Structure ConversionResult
  Success.i
  Value.f
  SourceName.s
  TargetName.s
  ErrorMessage.s
EndStructure

Structure ActionResult
  Success.i
  Message.s
EndStructure

Global NewList ConversionGroups.ConversionGroup()
Global mode.i = #SYSTEM_ENGLISH
Global done.i = #False
Global NewList history.s()
Global logFile.s = AppPath + #APP_NAME + "_history.log"

; --- Initialization ---

Procedure AddGroup(GroupName.s, BaseUnit.s)
  AddElement(ConversionGroups())
  ConversionGroups()\GroupName = GroupName
  ConversionGroups()\BaseUnit = BaseUnit
EndProcedure

Procedure AddUnit(List TargetList.ConversionUnit(), Name.s, Units.s, Factor.f, Offset.f = 0.0)
  AddElement(TargetList())
  TargetList()\Name = Name
  TargetList()\Units = Units
  TargetList()\Factor = Factor
  TargetList()\Offset = Offset
EndProcedure

Procedure InitConversions()
  ClearList(ConversionGroups())

  AddGroup("Length", "m")
  AddUnit(ConversionGroups()\English(), "Inches", "in|inch|inches", 0.0254)
  AddUnit(ConversionGroups()\English(), "Feet", "ft|foot|feet|'", 0.3048)
  AddUnit(ConversionGroups()\English(), "Yards", "yd|yard|yards", 0.9144)
  AddUnit(ConversionGroups()\English(), "Miles", "mi|mile|miles", 1609.34)
  AddUnit(ConversionGroups()\Metric(), "Millimeters", "mm|millimeter|millimeters", 0.001)
  AddUnit(ConversionGroups()\Metric(), "Centimeters", "cm|centimeter|centimeters", 0.01)
  AddUnit(ConversionGroups()\Metric(), "Meters", "m|meter|meters", 1.0)
  AddUnit(ConversionGroups()\Metric(), "Kilometers", "km|kilometer|kilometers", 1000.0)

  AddGroup("Mass", "kg")
  AddUnit(ConversionGroups()\English(), "Ounces", "oz|ounce|ounces", 0.0283495)
  AddUnit(ConversionGroups()\English(), "Pounds", "lb|lbs|pound|pounds", 0.453592)
  AddUnit(ConversionGroups()\English(), "Stone", "st|stone", 6.35029)
  AddUnit(ConversionGroups()\Metric(), "Milligrams", "mg|milligram|milligrams", 0.000001)
  AddUnit(ConversionGroups()\Metric(), "Grams", "g|gram|grams", 0.001)
  AddUnit(ConversionGroups()\Metric(), "Kilograms", "kg|kilogram|kilograms", 1.0)
  AddUnit(ConversionGroups()\Metric(), "Metric Tons", "t|tonne|tonnes|metric ton|metric tons", 1000.0)

  AddGroup("Volume", "L")
  AddUnit(ConversionGroups()\English(), "Fluid Ounces", "fl oz|floz|fluid ounce|fluid ounces", 0.0295735)
  AddUnit(ConversionGroups()\English(), "Cups", "cup|cups", 0.236588)
  AddUnit(ConversionGroups()\English(), "Pints", "pt|pint|pints", 0.473176)
  AddUnit(ConversionGroups()\English(), "Quarts", "qt|quart|quarts", 0.946353)
  AddUnit(ConversionGroups()\English(), "Gallons", "gal|gallon|gallons", 3.78541)
  AddUnit(ConversionGroups()\Metric(), "Milliliters", "ml|milliliter|milliliters", 0.001)
  AddUnit(ConversionGroups()\Metric(), "Liters", "l|liter|liters|litre|litres", 1.0)

  AddGroup("Temperature", "C")
  AddUnit(ConversionGroups()\English(), "Fahrenheit", "f|fahr|fahrenheit|deg f|degree f|degrees f", 5.0 / 9.0, -32.0)
  AddUnit(ConversionGroups()\Metric(), "Celsius", "c|cel|celsius|centigrade|deg c|degree c|degrees c", 1.0, 0.0)
  AddUnit(ConversionGroups()\Metric(), "Kelvin", "k|kelvin|kelvins", 1.0, -273.15)

  AddGroup("Area", "m2")
  AddUnit(ConversionGroups()\English(), "Square Inches", "sq in|sqin|square inch|square inches", 0.00064516)
  AddUnit(ConversionGroups()\English(), "Square Feet", "sq ft|sqft|square foot|square feet", 0.092903)
  AddUnit(ConversionGroups()\English(), "Acres", "acre|acres", 4046.86)
  AddUnit(ConversionGroups()\Metric(), "Square Meters", "m2|sqm|square meter|square meters", 1.0)
  AddUnit(ConversionGroups()\Metric(), "Hectares", "ha|hectare|hectares", 10000.0)

  AddGroup("Speed", "m/s")
  AddUnit(ConversionGroups()\English(), "Miles per Hour", "mph|mile per hour|miles per hour", 0.44704)
  AddUnit(ConversionGroups()\English(), "Knots", "kt|knot|knots", 0.514444)
  AddUnit(ConversionGroups()\Metric(), "Kilometers per Hour", "kph|km/h|kilometer per hour|kilometers per hour", 0.277778)
  AddUnit(ConversionGroups()\Metric(), "Meters per Second", "m/s|mps|meter per second|meters per second", 1.0)
EndProcedure

InitConversions()

; --- Utility Functions ---

Procedure.s DateTimeStamp()
  ProcedureReturn FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date())
EndProcedure

Procedure.i OpenLogFileForAppend(path.s)
  Protected fileId.i

  If FileSize(path) = -1
    fileId = CreateFile(#PB_Any, path)
  Else
    fileId = OpenFile(#PB_Any, path)
    If fileId
      FileSeek(fileId, Lof(fileId))
    EndIf
  EndIf

  ProcedureReturn fileId
EndProcedure

Procedure LogConversion(line.s)
  Protected fileId.i = OpenLogFileForAppend(logFile)

  If fileId
    WriteStringN(fileId, DateTimeStamp() + "  " + line)
    CloseFile(fileId)
  EndIf
EndProcedure

Procedure RecordHistory(line.s)
  AddElement(history())
  history() = line
  LogConversion(line)
EndProcedure

Procedure PauseForEnter()
  Print("")
  Print("Press Enter to continue...")
  Input()
EndProcedure

Procedure.s CollapseSpaces(input.s)
  Protected result.s = ""
  Protected i.i
  Protected previousWasSpace.i = #False
  Protected char.s

  For i = 1 To Len(input)
    char = Mid(input, i, 1)
    If char = " "
      If previousWasSpace = #False
        result + char
        previousWasSpace = #True
      EndIf
    Else
      result + char
      previousWasSpace = #False
    EndIf
  Next

  ProcedureReturn Trim(result)
EndProcedure

Procedure.s NormalizeUnitText(input.s)
  Protected s.s = LCase(Trim(input))

  s = ReplaceString(s, ".", "")
  s = ReplaceString(s, "degrees ", "")
  s = ReplaceString(s, "degree ", "")
  s = ReplaceString(s, "deg ", "")
  s = CollapseSpaces(s)

  ProcedureReturn s
EndProcedure

Procedure.s NormalizeNumberString(input.s)
  Protected s.s = Trim(input)
  s = ReplaceString(s, ",", "")
  ProcedureReturn s
EndProcedure

Procedure.i IsDigitChar(char.s)
  ProcedureReturn Bool(FindString("0123456789", char, 1) > 0)
EndProcedure

Procedure.i IsStrictNumberString(input.s)
  Protected s.s = NormalizeNumberString(input)
  Protected i.i
  Protected char.s
  Protected hasDigit.i = #False
  Protected hasExponent.i = #False
  Protected hasDecimal.i = #False
  Protected exponentHasDigit.i = #False
  Protected allowSign.i = #True

  If s = ""
    ProcedureReturn #False
  EndIf

  For i = 1 To Len(s)
    char = Mid(s, i, 1)

    If char = "+" Or char = "-"
      If allowSign = #False
        ProcedureReturn #False
      EndIf
      allowSign = #False
    ElseIf char = "."
      If hasDecimal Or hasExponent
        ProcedureReturn #False
      EndIf
      hasDecimal = #True
      allowSign = #False
    ElseIf char = "e" Or char = "E"
      If hasExponent Or hasDigit = #False
        ProcedureReturn #False
      EndIf
      hasExponent = #True
      exponentHasDigit = #False
      allowSign = #True
    ElseIf IsDigitChar(char)
      If hasExponent
        exponentHasDigit = #True
      Else
        hasDigit = #True
      EndIf
      allowSign = #False
    Else
      ProcedureReturn #False
    EndIf
  Next

  If hasDigit = #False
    ProcedureReturn #False
  EndIf

  If hasExponent And exponentHasDigit = #False
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.s ValidateNumberString(input.s)
  Protected normalized.s = NormalizeNumberString(input)

  If normalized = ""
    ProcedureReturn "Please enter a number."
  EndIf

  If IsStrictNumberString(normalized) = #False
    ProcedureReturn "Invalid number. Use formats like 12, -3.5, or 6.02e2."
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.i IsPositiveIntegerString(input.s)
  Protected s.s = Trim(input)
  Protected i.i

  If s = ""
    ProcedureReturn #False
  EndIf

  For i = 1 To Len(s)
    If IsDigitChar(Mid(s, i, 1)) = #False
      ProcedureReturn #False
    EndIf
  Next

  ProcedureReturn #True
EndProcedure

Procedure.s GetSystemName(system.i)
  If system = #SYSTEM_METRIC
    ProcedureReturn "Metric"
  EndIf

  ProcedureReturn "English"
EndProcedure

Procedure.s GetModeLabel(system.i)
  If system = #SYSTEM_METRIC
    ProcedureReturn "Metric to English"
  EndIf

  ProcedureReturn "English to Metric"
EndProcedure

Procedure.i GetTargetSystem(sourceSystem.i)
  If sourceSystem = #SYSTEM_METRIC
    ProcedureReturn #SYSTEM_ENGLISH
  EndIf

  ProcedureReturn #SYSTEM_METRIC
EndProcedure

Procedure.s GetPrimaryUnitAlias(units.s)
  ProcedureReturn NormalizeUnitText(StringField(units, 1, "|"))
EndProcedure

Procedure.s BuildUnitLabel(name.s, units.s)
  Protected alias.s = GetPrimaryUnitAlias(units)

  If alias = ""
    ProcedureReturn name
  EndIf

  ProcedureReturn name + " [" + alias + "]"
EndProcedure

Procedure.s FormatNumericValue(value.f, decimals.i = 6)
  Protected text.s = StrF(value, decimals)

  While FindString(text, ".", 1) > 0 And Right(text, 1) = "0"
    text = Left(text, Len(text) - 1)
  Wend

  If Right(text, 1) = "."
    text = Left(text, Len(text) - 1)
  EndIf

  ProcedureReturn text
EndProcedure

Procedure.s FormatGroupValue(groupIdx.i, value.f)
  Protected absValue.f = Abs(value)
  Protected decimals.i = 4

  If SelectElement(ConversionGroups(), groupIdx)
    If ConversionGroups()\GroupName = "Temperature"
      decimals = 2
    ElseIf absValue >= 1000
      decimals = 2
    ElseIf absValue >= 100
      decimals = 3
    ElseIf absValue >= 1
      decimals = 4
    Else
      decimals = 6
    EndIf
  EndIf

  ProcedureReturn FormatNumericValue(value, decimals)
EndProcedure

Procedure.i ParseMeasurementInput(input.s, *valueText.String, *unitText.String, *errorText.String)
  Protected trimmed.s = Trim(input)
  Protected allowedChars.s = "0123456789+-.,eE"
  Protected splitIdx.i = 0
  Protected i.i
  Protected char.s
  Protected numberText.s
  Protected parsedUnitText.s
  Protected validationError.s

  If *valueText : *valueText\s = "" : EndIf
  If *unitText : *unitText\s = "" : EndIf
  If *errorText : *errorText\s = "" : EndIf

  If trimmed = ""
    If *errorText : *errorText\s = "Please enter a value followed by a unit." : EndIf
    ProcedureReturn #False
  EndIf

  For i = 1 To Len(trimmed)
    char = Mid(trimmed, i, 1)
    If FindString(allowedChars, char, 1) = 0
      splitIdx = i
      Break
    EndIf
  Next

  If splitIdx = 0
    If *errorText : *errorText\s = "Missing unit. Format: [value] [unit]." : EndIf
    ProcedureReturn #False
  EndIf

  numberText = Trim(Left(trimmed, splitIdx - 1))
  parsedUnitText = NormalizeUnitText(Mid(trimmed, splitIdx))
  validationError = ValidateNumberString(numberText)

  If validationError <> ""
    If *errorText : *errorText\s = validationError : EndIf
    ProcedureReturn #False
  EndIf

  If parsedUnitText = ""
    If *errorText : *errorText\s = "Missing unit. Format: [value] [unit]." : EndIf
    ProcedureReturn #False
  EndIf

  If *valueText : *valueText\s = NormalizeNumberString(numberText) : EndIf
  If *unitText : *unitText\s = parsedUnitText : EndIf

  ProcedureReturn #True
EndProcedure

Procedure.i SetActionResult(*result.ActionResult, success.i, message.s)
  If *result
    *result\Success = success
    *result\Message = message
  EndIf

  ProcedureReturn success
EndProcedure

Procedure.i UnitMatches(unit.s, expectedUnits.s)
  Protected normalizedUnit.s = NormalizeUnitText(unit)
  Protected i.i
  Protected aliasCount.i = CountString(expectedUnits, "|") + 1

  For i = 1 To aliasCount
    If normalizedUnit = NormalizeUnitText(StringField(expectedUnits, i, "|"))
      ProcedureReturn #True
    EndIf
  Next

  ProcedureReturn #False
EndProcedure

Procedure.f GetInputValue(prompt.s)
  Protected inputText.s
  Protected validationError.s

  Repeat
    Print(prompt)
    inputText = Trim(Input())
    validationError = ValidateNumberString(inputText)

    If validationError <> ""
      PrintN(validationError)
      Continue
    EndIf

    ProcedureReturn ValF(NormalizeNumberString(inputText))
  ForEver
EndProcedure

Procedure.i GetUnitListSize(groupIdx.i, system.i)
  If SelectElement(ConversionGroups(), groupIdx) = 0
    ProcedureReturn 0
  EndIf

  If system = #SYSTEM_METRIC
    ProcedureReturn ListSize(ConversionGroups()\Metric())
  EndIf

  ProcedureReturn ListSize(ConversionGroups()\English())
EndProcedure

Procedure DisplayUnitChoices(groupIdx.i, system.i)
  Protected itemNumber.i = 1

  If SelectElement(ConversionGroups(), groupIdx) = 0
    ProcedureReturn
  EndIf

  If system = #SYSTEM_METRIC
    ForEach ConversionGroups()\Metric()
      PrintN("  " + Str(itemNumber) + ". " + BuildUnitLabel(ConversionGroups()\Metric()\Name, ConversionGroups()\Metric()\Units))
      itemNumber + 1
    Next
  Else
    ForEach ConversionGroups()\English()
      PrintN("  " + Str(itemNumber) + ". " + BuildUnitLabel(ConversionGroups()\English()\Name, ConversionGroups()\English()\Units))
      itemNumber + 1
    Next
  EndIf
EndProcedure

Procedure.i ResolveUnitSelection(groupIdx.i, system.i, selection.i)
  Protected itemNumber.i = 1

  If selection < 1 Or SelectElement(ConversionGroups(), groupIdx) = 0
    ProcedureReturn -1
  EndIf

  If system = #SYSTEM_METRIC
    ForEach ConversionGroups()\Metric()
      If itemNumber = selection
        ProcedureReturn ListIndex(ConversionGroups()\Metric())
      EndIf
      itemNumber + 1
    Next
  Else
    ForEach ConversionGroups()\English()
      If itemNumber = selection
        ProcedureReturn ListIndex(ConversionGroups()\English())
      EndIf
      itemNumber + 1
    Next
  EndIf

  ProcedureReturn -1
EndProcedure

Procedure.i PromptForSelection(prompt.s, maxValue.i, allowCancel.i = #False)
  Protected choice.s
  Protected value.i
  Protected message.s

  If allowCancel
    message = "Please enter a number between 1 and " + Str(maxValue) + ", or 0 to cancel."
  Else
    message = "Please enter a number between 1 and " + Str(maxValue) + "."
  EndIf

  Repeat
    Print(prompt)
    choice = Trim(Input())

    If allowCancel And choice = "0"
      ProcedureReturn 0
    EndIf

    If IsPositiveIntegerString(choice) = #False
      PrintN(message)
      Continue
    EndIf

    value = Val(choice)
    If value < 1 Or value > maxValue
      PrintN(message)
      Continue
    EndIf

    ProcedureReturn value
  ForEver
EndProcedure

; --- Conversion Logic ---

Procedure.i ConvertValue(inputVal.f, groupIdx.i, sourceSystem.i, sourceIdx.i, targetSystem.i, targetIdx.i, *result.ConversionResult)
  Protected baseVal.f
  Protected sourceFactor.f
  Protected sourceOffset.f
  Protected targetFactor.f
  Protected targetOffset.f

  If *result
    *result\Success = #False
    *result\Value = 0
    *result\SourceName = ""
    *result\TargetName = ""
    *result\ErrorMessage = ""
  EndIf

  If sourceSystem = targetSystem
    If *result : *result\ErrorMessage = "Source and target systems must be different." : EndIf
    ProcedureReturn #False
  EndIf

  If SelectElement(ConversionGroups(), groupIdx) = 0
    If *result : *result\ErrorMessage = "Invalid conversion group selected." : EndIf
    ProcedureReturn #False
  EndIf

  If sourceSystem = #SYSTEM_METRIC
    If SelectElement(ConversionGroups()\Metric(), sourceIdx) = 0
      If *result : *result\ErrorMessage = "Invalid source unit selected." : EndIf
      ProcedureReturn #False
    EndIf

    sourceFactor = ConversionGroups()\Metric()\Factor
    sourceOffset = ConversionGroups()\Metric()\Offset
    If *result : *result\SourceName = BuildUnitLabel(ConversionGroups()\Metric()\Name, ConversionGroups()\Metric()\Units) : EndIf
  Else
    If SelectElement(ConversionGroups()\English(), sourceIdx) = 0
      If *result : *result\ErrorMessage = "Invalid source unit selected." : EndIf
      ProcedureReturn #False
    EndIf

    sourceFactor = ConversionGroups()\English()\Factor
    sourceOffset = ConversionGroups()\English()\Offset
    If *result : *result\SourceName = BuildUnitLabel(ConversionGroups()\English()\Name, ConversionGroups()\English()\Units) : EndIf
  EndIf

  If targetSystem = #SYSTEM_METRIC
    If SelectElement(ConversionGroups()\Metric(), targetIdx) = 0
      If *result : *result\ErrorMessage = "Invalid target unit selected." : EndIf
      ProcedureReturn #False
    EndIf

    targetFactor = ConversionGroups()\Metric()\Factor
    targetOffset = ConversionGroups()\Metric()\Offset
    If *result : *result\TargetName = BuildUnitLabel(ConversionGroups()\Metric()\Name, ConversionGroups()\Metric()\Units) : EndIf
  Else
    If SelectElement(ConversionGroups()\English(), targetIdx) = 0
      If *result : *result\ErrorMessage = "Invalid target unit selected." : EndIf
      ProcedureReturn #False
    EndIf

    targetFactor = ConversionGroups()\English()\Factor
    targetOffset = ConversionGroups()\English()\Offset
    If *result : *result\TargetName = BuildUnitLabel(ConversionGroups()\English()\Name, ConversionGroups()\English()\Units) : EndIf
  EndIf

  If sourceFactor = 0 Or targetFactor = 0
    If *result : *result\ErrorMessage = "Encountered an invalid conversion factor." : EndIf
    ProcedureReturn #False
  EndIf

  baseVal = (inputVal + sourceOffset) * sourceFactor

  If *result
    *result\Value = (baseVal / targetFactor) - targetOffset
    *result\Success = #True
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.i FindUnit(unit.s, *match.UnitChoice)
  Protected normalizedUnit.s = NormalizeUnitText(unit)

  If *match
    *match\GroupIdx = -1
    *match\System = #SYSTEM_ENGLISH
    *match\UnitIdx = -1
    *match\Name = ""
  EndIf

  ForEach ConversionGroups()
    ForEach ConversionGroups()\English()
      If UnitMatches(normalizedUnit, ConversionGroups()\English()\Units)
        If *match
          *match\GroupIdx = ListIndex(ConversionGroups())
          *match\System = #SYSTEM_ENGLISH
          *match\UnitIdx = ListIndex(ConversionGroups()\English())
          *match\Name = ConversionGroups()\English()\Name
        EndIf
        ProcedureReturn #True
      EndIf
    Next

    ForEach ConversionGroups()\Metric()
      If UnitMatches(normalizedUnit, ConversionGroups()\Metric()\Units)
        If *match
          *match\GroupIdx = ListIndex(ConversionGroups())
          *match\System = #SYSTEM_METRIC
          *match\UnitIdx = ListIndex(ConversionGroups()\Metric())
          *match\Name = ConversionGroups()\Metric()\Name
        EndIf
        ProcedureReturn #True
      EndIf
    Next
  Next

  ProcedureReturn #False
EndProcedure

Procedure.s FormatConversionLine(inputVal.f, *result.ConversionResult)
  If *result = 0 Or *result\Success = #False
    ProcedureReturn ""
  EndIf

  ProcedureReturn FormatGroupValue(ListIndex(ConversionGroups()), inputVal) + " " + *result\SourceName + " -> " + FormatGroupValue(ListIndex(ConversionGroups()), *result\Value) + " " + *result\TargetName
EndProcedure

Procedure DoSmartConversion(*actionResult.ActionResult)
  Protected inputText.s
  Protected valueText.s
  Protected unitText.s
  Protected errorText.s
  Protected match.UnitChoice
  Protected targetSystem.i
  Protected targetCount.i
  Protected targetSelection.i
  Protected targetIdx.i
  Protected value.f
  Protected result.ConversionResult

  PrintN("Smart conversion (Enter value with unit, e.g., '10 in' or '25 C'):")
  Print("> ")
  inputText = Trim(Input())

  If inputText = ""
    SetActionResult(*actionResult, #False, "")
    ProcedureReturn
  EndIf

  If ParseMeasurementInput(inputText, @valueText, @unitText, @errorText) = #False
    SetActionResult(*actionResult, #False, errorText)
    ProcedureReturn
  EndIf

  If FindUnit(unitText, @match) = #False
    SetActionResult(*actionResult, #False, "Unknown unit: '" + unitText + "'")
    ProcedureReturn
  EndIf

  targetSystem = GetTargetSystem(match\System)
  targetCount = GetUnitListSize(match\GroupIdx, targetSystem)
  If targetCount = 0
    SetActionResult(*actionResult, #False, "No compatible target units are available for that group.")
    ProcedureReturn
  EndIf

  SelectElement(ConversionGroups(), match\GroupIdx)
  PrintN("")
  PrintN("Detected: " + match\Name + " in " + ConversionGroups()\GroupName)
  PrintN("To:")
  DisplayUnitChoices(match\GroupIdx, targetSystem)

  targetSelection = PromptForSelection("To unit (0 to cancel): ", targetCount, #True)
  If targetSelection = 0
    SetActionResult(*actionResult, #False, "Smart conversion cancelled.")
    ProcedureReturn
  EndIf

  targetIdx = ResolveUnitSelection(match\GroupIdx, targetSystem, targetSelection)
  If targetIdx < 0
    SetActionResult(*actionResult, #False, "Invalid target unit selected.")
    ProcedureReturn
  EndIf

  value = ValF(valueText)
  If ConvertValue(value, match\GroupIdx, match\System, match\UnitIdx, targetSystem, targetIdx, @result) = #False
    SetActionResult(*actionResult, #False, result\ErrorMessage)
    ProcedureReturn
  EndIf

  SetActionResult(*actionResult, #True, FormatConversionLine(value, @result))
EndProcedure

Procedure RunGuidedConversion(groupIdx.i, sourceSystem.i, *actionResult.ActionResult)
  Protected targetSystem.i = GetTargetSystem(sourceSystem)
  Protected sourceCount.i = GetUnitListSize(groupIdx, sourceSystem)
  Protected targetCount.i = GetUnitListSize(groupIdx, targetSystem)
  Protected sourceSelection.i
  Protected targetSelection.i
  Protected sourceIdx.i
  Protected targetIdx.i
  Protected inputVal.f
  Protected result.ConversionResult

  If sourceCount = 0 Or targetCount = 0
    SetActionResult(*actionResult, #False, "Selected group is not configured correctly.")
    ProcedureReturn
  EndIf

  SelectElement(ConversionGroups(), groupIdx)
  PrintN("")
  PrintN("Group: " + ConversionGroups()\GroupName)
  PrintN("From (" + GetSystemName(sourceSystem) + "):")
  DisplayUnitChoices(groupIdx, sourceSystem)
  sourceSelection = PromptForSelection("From unit (0 to cancel): ", sourceCount, #True)
  If sourceSelection = 0
    SetActionResult(*actionResult, #False, "Conversion cancelled.")
    ProcedureReturn
  EndIf

  sourceIdx = ResolveUnitSelection(groupIdx, sourceSystem, sourceSelection)
  If sourceIdx < 0
    SetActionResult(*actionResult, #False, "Invalid source unit selected.")
    ProcedureReturn
  EndIf

  PrintN("")
  PrintN("To (" + GetSystemName(targetSystem) + "):")
  DisplayUnitChoices(groupIdx, targetSystem)
  targetSelection = PromptForSelection("To unit (0 to cancel): ", targetCount, #True)
  If targetSelection = 0
    SetActionResult(*actionResult, #False, "Conversion cancelled.")
    ProcedureReturn
  EndIf

  targetIdx = ResolveUnitSelection(groupIdx, targetSystem, targetSelection)
  If targetIdx < 0
    SetActionResult(*actionResult, #False, "Invalid target unit selected.")
    ProcedureReturn
  EndIf

  inputVal = GetInputValue("Value: ")
  If ConvertValue(inputVal, groupIdx, sourceSystem, sourceIdx, targetSystem, targetIdx, @result) = #False
    SetActionResult(*actionResult, #False, result\ErrorMessage)
    ProcedureReturn
  EndIf

  SetActionResult(*actionResult, #True, FormatConversionLine(inputVal, @result))
EndProcedure

Procedure ShowHistory()
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
EndProcedure

Procedure DisplayMenu()
  Protected itemNumber.i = 1

  ClearConsole()
  PrintN("=== " + #APP_NAME + " ===")
  PrintN("Mode: " + GetModeLabel(mode))
  PrintN("---------------------------")

  ForEach ConversionGroups()
    PrintN("  " + Str(itemNumber) + ". " + ConversionGroups()\GroupName)
    itemNumber + 1
  Next

  PrintN("")
  PrintN("Pick a group, then choose From, To, and Value.")
  PrintN("M. Toggle Mode | S. Smart Conv | H. History | 0. Exit")
  PrintN("---------------------------")
EndProcedure

EnableGraphicalConsole(1)
If OpenConsole() = 0
  MessageRequester(#APP_NAME, "Unable to open the console window.")
  End 1
EndIf
ConsoleTitle(#APP_NAME)

While done = #False
  DisplayMenu()
  Print("Choice: ")

  Define choice.s = LCase(Trim(Input()))
  Define choiceVal.i
  Define actionResult.ActionResult

  If choice = "m"
    mode = GetTargetSystem(mode)
  ElseIf choice = "s"
    DoSmartConversion(@actionResult)
    If actionResult\Message <> ""
      PrintN("")
      If actionResult\Success
        PrintN("Result: " + actionResult\Message)
        RecordHistory(actionResult\Message)
      Else
        PrintN(actionResult\Message)
      EndIf
      PauseForEnter()
    EndIf
  ElseIf choice = "h"
    ShowHistory()
    PauseForEnter()
  ElseIf choice = "0"
    done = #True
  ElseIf IsPositiveIntegerString(choice)
    choiceVal = Val(choice)
    If choiceVal < 1 Or choiceVal > ListSize(ConversionGroups())
      PrintN("")
      PrintN("Invalid selection: " + choice)
      PauseForEnter()
    Else
      RunGuidedConversion(choiceVal - 1, mode, @actionResult)
      If actionResult\Message <> ""
        PrintN("")
        If actionResult\Success
          PrintN("Result: " + actionResult\Message)
          RecordHistory(actionResult\Message)
        Else
          PrintN(actionResult\Message)
        EndIf
        PauseForEnter()
      EndIf
    EndIf
  Else
    PrintN("")
    PrintN("Invalid choice: " + choice)
    PauseForEnter()
  EndIf
Wend

CloseConsole()
End

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 9
; Folding = -------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = UnitCalc.ico
; Executable = ..\UnitCalc.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,2
; VersionField1 = 1,0,0,2
; VersionField2 = ZoneSSoft
; VersionField3 = UnitCalc
; VersionField4 = 1.0.0.2
; VersionField5 = 1.0.0.2
; VersionField6 = A unit of measurements calculator
; VersionField7 = UnitCalc
; VersionField8 = UnitCalc.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60