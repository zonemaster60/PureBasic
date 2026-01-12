; English to Metric Converter
; Converts common English measurements to metric units

EnableExplicit

#APP_NAME = "UnitCalc"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

Procedure.f InchesToCentimeters(inches.f)
  ProcedureReturn inches * 2.54
EndProcedure

Procedure.f FeetToMeters(feet.f)
  ProcedureReturn feet * 0.3048
EndProcedure

Procedure.f YardsToMeters(yards.f)
  ProcedureReturn yards * 0.9144
EndProcedure

Procedure.f MilesToKilometers(miles.f)
  ProcedureReturn miles * 1.60934
EndProcedure

Procedure.f PoundsToKilograms(pounds.f)
  ProcedureReturn pounds * 0.453592
EndProcedure

Procedure.f OuncesToGrams(ounces.f)
  ProcedureReturn ounces * 28.3495
EndProcedure

Procedure.f GallonsToLiters(gallons.f)
  ProcedureReturn gallons * 3.78541
EndProcedure

Procedure.f FahrenheitToCelsius(fahrenheit.f)
  ProcedureReturn (fahrenheit - 32.0) * (5.0 / 9.0)
EndProcedure

Procedure.f CentimetersToInches(cm.f)
  ProcedureReturn cm / 2.54
EndProcedure

Procedure.f MetersToFeet(meters.f)
  ProcedureReturn meters / 0.3048
EndProcedure

Procedure.f MetersToYards(meters.f)
  ProcedureReturn meters / 0.9144
EndProcedure

Procedure.f KilometersToMiles(km.f)
  ProcedureReturn km / 1.60934
EndProcedure

Procedure.f KilogramsToPounds(kg.f)
  ProcedureReturn kg / 0.453592
EndProcedure

Procedure.f GramsToOunces(g.f)
  ProcedureReturn g / 28.3495
EndProcedure

Procedure.f LitersToGallons(liters.f)
  ProcedureReturn liters / 3.78541
EndProcedure

Procedure.f CelsiusToFahrenheit(celsius.f)
  ProcedureReturn (celsius * (9.0 / 5.0)) + 32.0
EndProcedure

EnableGraphicalConsole(1)
OpenConsole()

Global logFile.s

logFile = AppPath + "unitcalc_history.log"

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

Procedure DisplayMenu(mode.i)
  If mode = 0
    PrintN("English to Metric Converter")
  Else
    PrintN("Metric to English Converter")
  EndIf

  PrintN("===========================")
  PrintN("")

  If mode = 0
    PrintN("1. Inches to Centimeters")
    PrintN("2. Feet to Meters")
    PrintN("3. Yards to Meters")
    PrintN("4. Miles to Kilometers")
    PrintN("5. Pounds to Kilograms")
    PrintN("6. Ounces to Grams")
    PrintN("7. Gallons to Liters")
    PrintN("8. Fahrenheit to Celsius")
  Else
    PrintN("1. Centimeters to Inches")
    PrintN("2. Meters to Feet")
    PrintN("3. Meters to Yards")
    PrintN("4. Kilometers to Miles")
    PrintN("5. Kilograms to Pounds")
    PrintN("6. Grams to Ounces")
    PrintN("7. Liters to Gallons")
    PrintN("8. Celsius to Fahrenheit")
  EndIf

  PrintN("")
  PrintN("M. Toggle mode (English<->Metric)")
  PrintN("S. Smart convert (auto-detect units)")
  PrintN("9. Repeat last conversion")
  PrintN("0. Exit")
  PrintN("")
  PrintN("===========================")
EndProcedure

Procedure.s NormalizeNumericPart(input.s)
  Protected cleaned.s

  cleaned = Trim(input)
  cleaned = ReplaceString(cleaned, ",", "")

  ; Keep only number-ish characters (handles trailing units like "12 in").
  While Len(cleaned) > 0
    Protected ch.s = Right(cleaned, 1)
    If FindString("0123456789.+-eE", ch, 1) = 0
      cleaned = Left(cleaned, Len(cleaned) - 1)
    Else
      Break
    EndIf
  Wend

  ProcedureReturn Trim(cleaned)
EndProcedure

Procedure.s NormalizeUnitSuffix(input.s)
  Protected s.s = LCase(Trim(input))

  ; Drop leading numeric portion (including separators/spaces).
  While Len(s) > 0
    Protected ch.s = Left(s, 1)
    If FindString("0123456789.+-eE, ", ch, 1)
      s = Mid(s, 2)
    Else
      Break
    EndIf
  Wend

  s = Trim(s)

  ; Common symbols
  s = ReplaceString(s, "½", "")
  s = ReplaceString(s, "deg", "")
  s = ReplaceString(s, "degrees", "")
  s = ReplaceString(s, " ", "")

  ProcedureReturn s
EndProcedure

Procedure.i UnitMatches(unit.s, expectedUnits.s)
  ; expectedUnits is "|"-separated list, case-insensitive.
  Protected needle.s = "|" + LCase(unit) + "|"
  ProcedureReturn Bool(FindString("|" + LCase(expectedUnits) + "|", needle, 1) > 0)
EndProcedure

Procedure.s GetSmartInput(prompt.s)
  Protected input.s

  PrintN(prompt)
  PrintN("Examples: 12 in, 30 cm, 5ft, 10 km, 2.2 lb, 1 gal, 20 C, 68 F")

  Repeat
    Print("Enter value (with unit): ")
    input = Trim(Input())
    If input = ""
      PrintN("Please enter a value.")
      Continue
    EndIf
    ProcedureReturn input
  ForEver
EndProcedure

Procedure.i ParseSmartInput(input.s, *value.Float, *unitOut.String)
  Protected cleaned.s = NormalizeNumericPart(input)
  Protected unit.s = NormalizeUnitSuffix(input)

  If cleaned = "" Or cleaned = "+" Or cleaned = "-" Or cleaned = "."
    ProcedureReturn #False
  EndIf

  If unit = ""
    ProcedureReturn #False
  EndIf

  *value\f = ValF(cleaned)
  *unitOut\s = unit
  ProcedureReturn #True
EndProcedure

Procedure.f ConvertSmartToMetric(value.f, unit.s, *outUnit.String)
  Protected u.s = LCase(unit)

  ; Length -> meters (m)
  If UnitMatches(u, "m|meter|meters")
    *outUnit\s = "m"
    ProcedureReturn value
  ElseIf UnitMatches(u, "cm|centimeter|centimeters")
    *outUnit\s = "m"
    ProcedureReturn value / 100.0
  ElseIf UnitMatches(u, "km|kilometer|kilometers")
    *outUnit\s = "m"
    ProcedureReturn value * 1000.0
  ElseIf UnitMatches(u, "in|inch|inches")
    *outUnit\s = "m"
    ProcedureReturn InchesToCentimeters(value) / 100.0
  ElseIf UnitMatches(u, "ft|foot|feet|'")
    *outUnit\s = "m"
    ProcedureReturn FeetToMeters(value)
  ElseIf UnitMatches(u, "yd|yard|yards")
    *outUnit\s = "m"
    ProcedureReturn YardsToMeters(value)
  ElseIf UnitMatches(u, "mi|mile|miles")
    *outUnit\s = "m"
    ProcedureReturn MilesToKilometers(value) * 1000.0

  ; Mass -> kilograms (kg)
  ElseIf UnitMatches(u, "kg|kilogram|kilograms")
    *outUnit\s = "kg"
    ProcedureReturn value
  ElseIf UnitMatches(u, "g|gram|grams")
    *outUnit\s = "kg"
    ProcedureReturn value / 1000.0
  ElseIf UnitMatches(u, "lb|lbs|pound|pounds")
    *outUnit\s = "kg"
    ProcedureReturn PoundsToKilograms(value)
  ElseIf UnitMatches(u, "oz|ounce|ounces")
    *outUnit\s = "kg"
    ProcedureReturn OuncesToGrams(value) / 1000.0

  ; Volume -> liters (l)
  ElseIf UnitMatches(u, "l|liter|liters|litre|litres")
    *outUnit\s = "L"
    ProcedureReturn value
  ElseIf UnitMatches(u, "ml|milliliter|milliliters")
    *outUnit\s = "L"
    ProcedureReturn value / 1000.0
  ElseIf UnitMatches(u, "gal|gallon|gallons")
    *outUnit\s = "L"
    ProcedureReturn GallonsToLiters(value)

  ; Temperature -> Celsius (c)
  ElseIf UnitMatches(u, "c|cel|celsius")
    *outUnit\s = "C"
    ProcedureReturn value
  ElseIf UnitMatches(u, "f|fahr|fahrenheit")
    *outUnit\s = "C"
    ProcedureReturn FahrenheitToCelsius(value)
  EndIf

  *outUnit\s = ""
  ProcedureReturn 0.0
EndProcedure

; Legacy (choice-based) input kept for callers
Procedure.f GetInputValue(prompt.s, expectedUnits.s)
  Protected tmp.s
  Protected v.f
  Protected unit.s

  PrintN(prompt)
  PrintN("Tip: you can type commas and optional units (e.g. 1,234.5 in)")

  Repeat
    Print("Enter value: ")
    tmp = Trim(Input())
    If tmp = ""
      PrintN("Please enter a value.")
      Continue
    EndIf

    v = ValF(NormalizeNumericPart(tmp))
    unit = NormalizeUnitSuffix(tmp)

    If expectedUnits <> "" And unit <> "" And UnitMatches(unit, expectedUnits) = #False
      PrintN("Unexpected unit. Expected: " + expectedUnits)
      Continue
    EndIf

    ProcedureReturn v
  ForEver
EndProcedure

; Backwards compatibility wrapper
Procedure.f GetInputValueSimple(prompt.s)
  ProcedureReturn GetInputValue(prompt, "")
EndProcedure

Procedure.s UnitGroupFromUnit(unit.s)
  Protected u.s = LCase(unit)

  If UnitMatches(u, "m|meter|meters|cm|centimeter|centimeters|km|kilometer|kilometers|in|inch|inches|ft|foot|feet|yd|yard|yards|mi|mile|miles")
    ProcedureReturn "length"
  ElseIf UnitMatches(u, "kg|kilogram|kilograms|g|gram|grams|lb|lbs|pound|pounds|oz|ounce|ounces")
    ProcedureReturn "mass"
  ElseIf UnitMatches(u, "l|liter|liters|litre|litres|ml|milliliter|milliliters|gal|gallon|gallons")
    ProcedureReturn "volume"
  ElseIf UnitMatches(u, "c|cel|celsius|f|fahr|fahrenheit")
    ProcedureReturn "temperature"
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.s SmartToString(value.f, unit.s)
  ProcedureReturn StrF(value, 4) + " " + unit
EndProcedure

Procedure.s DoSmartConversion()
  Protected input.s
  Protected value.f
  Protected unit.s
  Protected u.s
  Protected group.s

  Protected destValue.f
  Protected destUnit.s

  input = GetSmartInput("Smart convert")

  If ParseSmartInput(input, @value, @unit) = #False
    ProcedureReturn "Invalid input. Please include a unit."
  EndIf

  u = LCase(unit)
  group = UnitGroupFromUnit(unit)
  If group = ""
    ProcedureReturn "Unknown unit: " + unit
  EndIf

  Select group
    Case "length"
      ; Imperial -> Metric: in/ft/yd/mi -> cm/m/km (scaled)
      If UnitMatches(u, "in|inch|inches|ft|foot|feet|'|yd|yard|yards|mi|mile|miles")
        Protected meters.f
        meters = ConvertSmartToMetric(value, unit, @destUnit) ; destUnit becomes "m"

        If Abs(meters) >= 1000.0
          destValue = meters / 1000.0
          destUnit = "km"
        ElseIf Abs(meters) >= 1.0
          destValue = meters
          destUnit = "m"
        Else
          destValue = meters * 100.0
          destUnit = "cm"
        EndIf

      ; Metric -> Imperial: cm/m/km -> in/ft/mi (scaled)
      Else
        Protected meters2.f
        meters2 = ConvertSmartToMetric(value, unit, @destUnit) ; destUnit becomes "m"

        If Abs(meters2) >= 1609.34
          destValue = meters2 / 1609.34
          destUnit = "mi"
        ElseIf Abs(meters2) >= 0.3048
          destValue = meters2 / 0.3048
          destUnit = "ft"
        Else
          destValue = (meters2 * 100.0) / 2.54
          destUnit = "in"
        EndIf
      EndIf

    Case "mass"
      ; Imperial -> Metric: oz/lb -> g/kg (scaled)
      If UnitMatches(u, "lb|lbs|pound|pounds|oz|ounce|ounces")
        Protected kg.f
        kg = ConvertSmartToMetric(value, unit, @destUnit) ; destUnit becomes "kg"

        If Abs(kg) >= 1.0
          destValue = kg
          destUnit = "kg"
        Else
          destValue = kg * 1000.0
          destUnit = "g"
        EndIf

      ; Metric -> Imperial: g/kg -> oz/lb (scaled)
      Else
        Protected kg2.f
        kg2 = ConvertSmartToMetric(value, unit, @destUnit) ; destUnit becomes "kg"

        If Abs(kg2) >= 0.453592
          destValue = kg2 / 0.453592
          destUnit = "lb"
        Else
          destValue = (kg2 * 1000.0) / 28.3495
          destUnit = "oz"
        EndIf
      EndIf

    Case "volume"
      ; Imperial -> Metric: gal -> L
      If UnitMatches(u, "gal|gallon|gallons")
        destValue = GallonsToLiters(value)
        destUnit = "L"

      ; Metric -> Imperial: ml/L -> gal (scaled)
      Else
        Protected liters.f
        liters = ConvertSmartToMetric(value, unit, @destUnit) ; destUnit becomes "L"
        destValue = liters / 3.78541
        destUnit = "gal"
      EndIf

    Case "temperature"
      ; Flip temperature direction
      If UnitMatches(u, "f|fahr|fahrenheit")
        destValue = FahrenheitToCelsius(value)
        destUnit = "C"
      Else
        destValue = (value * (9.0 / 5.0)) + 32.0
        destUnit = "F"
      EndIf

  EndSelect

  ProcedureReturn SmartToString(value, unit) + " -> " + SmartToString(destValue, destUnit)
EndProcedure

; Main program loop
Define choice.s
Define choiceVal.i
Define done.i
Define mode.i
Define value.f
Define result.f
Define lastChoiceVal.i = -1
Define lastValue.f
Define lastResult.f
Define lastWasSmart.i
Define lastSmartLine.s
Define lastMode.i
Global NewList history.s()

While done = 0
  DisplayMenu(mode)
  Print("Enter your choice (0-9, M, or S): ")
  choice = LCase(Trim(Input()))
  choiceVal = Val(choice)

  PrintN("")

  If choice = "m"
    mode ! 1
    If mode = 0
      PrintN("Mode: English -> Metric")
    Else
      PrintN("Mode: Metric -> English")
    EndIf
  ElseIf choice = "s"
    Define smartLine.s
    smartLine = DoSmartConversion()
    PrintN(smartLine)
    AddElement(history())
    history() = smartLine
    LogConversion(smartLine)
    lastWasSmart = 1
    lastSmartLine = smartLine
    lastMode = mode
    ; stay in loop
  Else
    If choiceVal = 9
      If lastWasSmart = 1
        PrintN(lastSmartLine)
        AddElement(history())
        history() = lastSmartLine
        LogConversion(lastSmartLine)
        choiceVal = -1
      ElseIf lastChoiceVal >= 1 And lastChoiceVal <= 8
        mode = lastMode
        choiceVal = lastChoiceVal
        value = lastValue
        result = lastResult
      Else
        PrintN("Nothing to repeat yet.")
        choiceVal = -1
      EndIf
    EndIf

    If mode = 1 And choiceVal >= 1 And choiceVal <= 8
      choiceVal + 9
    EndIf

    Select choiceVal
      Case 1
      value = GetInputValue("Inches to Centimeters", "in|inch|inches")
      result = InchesToCentimeters(value)
      PrintN(StrF(value, 2) + " inches = " + StrF(result, 2) + " centimeters")
      AddElement(history())
      history() = StrF(value, 2) + " in -> " + StrF(result, 2) + " cm"
      LogConversion(history())
      
    Case 2
      value = GetInputValue("Feet to Meters", "ft|foot|feet|'")
      result = FeetToMeters(value)
      PrintN(StrF(value, 2) + " feet = " + StrF(result, 2) + " meters")
      AddElement(history())
      history() = StrF(value, 2) + " ft -> " + StrF(result, 2) + " m"
      LogConversion(history())
      
    Case 3
      value = GetInputValue("Yards to Meters", "yd|yard|yards")
      result = YardsToMeters(value)
      PrintN(StrF(value, 2) + " yards = " + StrF(result, 2) + " meters")
      AddElement(history())
      history() = StrF(value, 2) + " yd -> " + StrF(result, 2) + " m"
      LogConversion(history())
      
    Case 4
      value = GetInputValue("Miles to Kilometers", "mi|mile|miles")
      result = MilesToKilometers(value)
      PrintN(StrF(value, 2) + " miles = " + StrF(result, 2) + " kilometers")
      AddElement(history())
      history() = StrF(value, 2) + " mi -> " + StrF(result, 2) + " km"
      LogConversion(history())
      
    Case 5
      value = GetInputValue("Pounds to Kilograms", "lb|lbs|pound|pounds")
      result = PoundsToKilograms(value)
      PrintN(StrF(value, 2) + " pounds = " + StrF(result, 2) + " kilograms")
      AddElement(history())
      history() = StrF(value, 2) + " lb -> " + StrF(result, 2) + " kg"
      LogConversion(history())
      
    Case 6
      value = GetInputValue("Ounces to Grams", "oz|ounce|ounces")
      result = OuncesToGrams(value)
      PrintN(StrF(value, 2) + " ounces = " + StrF(result, 2) + " grams")
      AddElement(history())
      history() = StrF(value, 2) + " oz -> " + StrF(result, 2) + " g"
      LogConversion(history())
      
    Case 7
      value = GetInputValue("Gallons to Liters", "gal|gallon|gallons")
      result = GallonsToLiters(value)
      PrintN(StrF(value, 2) + " gallons = " + StrF(result, 2) + " liters")
      AddElement(history())
      history() = StrF(value, 2) + " gal -> " + StrF(result, 2) + " L"
      LogConversion(history())
      
    Case 8
      value = GetInputValue("Fahrenheit to Celsius", "f|fahr|fahrenheit")
      result = FahrenheitToCelsius(value)
      PrintN(StrF(value, 2) + "°F = " + StrF(result, 2) + "°C")
      AddElement(history())
      history() = StrF(value, 2) + " °F -> " + StrF(result, 2) + " °C"
      LogConversion(history())

    Case 10
      value = GetInputValue("Centimeters to Inches", "cm|centimeter|centimeters")
      result = CentimetersToInches(value)
      PrintN(StrF(value, 2) + " centimeters = " + StrF(result, 2) + " inches")
      AddElement(history())
      history() = StrF(value, 2) + " cm -> " + StrF(result, 2) + " in"
      LogConversion(history())

    Case 11
      value = GetInputValue("Meters to Feet", "m|meter|meters")
      result = MetersToFeet(value)
      PrintN(StrF(value, 2) + " meters = " + StrF(result, 2) + " feet")
      AddElement(history())
      history() = StrF(value, 2) + " m -> " + StrF(result, 2) + " ft"
      LogConversion(history())

    Case 12
      value = GetInputValue("Meters to Yards", "m|meter|meters")
      result = MetersToYards(value)
      PrintN(StrF(value, 2) + " meters = " + StrF(result, 2) + " yards")
      AddElement(history())
      history() = StrF(value, 2) + " m -> " + StrF(result, 2) + " yd"
      LogConversion(history())

    Case 13
      value = GetInputValue("Kilometers to Miles", "km|kilometer|kilometers")
      result = KilometersToMiles(value)
      PrintN(StrF(value, 2) + " kilometers = " + StrF(result, 2) + " miles")
      AddElement(history())
      history() = StrF(value, 2) + " km -> " + StrF(result, 2) + " mi"
      LogConversion(history())

    Case 14
      value = GetInputValue("Kilograms to Pounds", "kg|kilogram|kilograms")
      result = KilogramsToPounds(value)
      PrintN(StrF(value, 2) + " kilograms = " + StrF(result, 2) + " pounds")
      AddElement(history())
      history() = StrF(value, 2) + " kg -> " + StrF(result, 2) + " lb"
      LogConversion(history())

    Case 15
      value = GetInputValue("Grams to Ounces", "g|gram|grams")
      result = GramsToOunces(value)
      PrintN(StrF(value, 2) + " grams = " + StrF(result, 2) + " ounces")
      AddElement(history())
      history() = StrF(value, 2) + " g -> " + StrF(result, 2) + " oz"
      LogConversion(history())

    Case 16
      value = GetInputValue("Liters to Gallons", "l|liter|liters|litre|litres")
      result = LitersToGallons(value)
      PrintN(StrF(value, 2) + " liters = " + StrF(result, 2) + " gallons")
      AddElement(history())
      history() = StrF(value, 2) + " L -> " + StrF(result, 2) + " gal"
      LogConversion(history())

    Case 17
      value = GetInputValue("Celsius to Fahrenheit", "c|cel|celsius")
      result = CelsiusToFahrenheit(value)
      PrintN(StrF(value, 2) + "°C = " + StrF(result, 2) + "°F")
      AddElement(history())
      history() = StrF(value, 2) + " °C -> " + StrF(result, 2) + " °F"
      LogConversion(history())
      
    Case 0
      PrintN("Goodbye!")
      done = 1

      If ListSize(history()) > 0
        PrintN("")
        PrintN("History:")
        PrintN("--------")
        ForEach history()
          PrintN(history())
        Next
        PrintN("")
        PrintN("Press Enter to continue...")
        Input()
      EndIf

    Default
      PrintN("Invalid choice! Please enter 0-9, M, or S.")
    EndSelect
  EndIf

  If (choiceVal >= 1 And choiceVal <= 8) Or (choiceVal >= 10 And choiceVal <= 17)
    lastChoiceVal = choiceVal
    lastValue = value
    lastResult = result
    lastWasSmart = 0
    lastMode = mode
  EndIf

  If choiceVal <> 0 And choice <> "s" And choice <> "m"
    PrintN("")
    PrintN("Press Enter to continue...")
    Input()
  EndIf
  
  Delay(2500)
  ClearConsole()
  
Wend
CloseConsole()
End
; IDE Options = PureBasic 6.30 beta 7 (Windows - x64)
; CursorPosition = 78
; FirstLine = 63
; Folding = ------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware