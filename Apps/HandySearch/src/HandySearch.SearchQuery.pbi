; Search query parsing and DB-backed result refresh

Procedure.s WildcardToRegex(pattern.s)
  Protected out.s = "^"
  Protected i.i, ch.s

  For i = 1 To Len(pattern)
    ch = Mid(pattern, i, 1)
    Select ch
      Case "*"
        out + ".*"
      Case "?"
        out + "."
      Case ".", "^", "$", "+", "(", ")", "[", "]", "{", "}", "|"
        out + "\" + ch
      Case "\"
        out + "\"
      Default
        out + ch
    EndSelect
  Next

  ProcedureReturn out + "$"
EndProcedure

Procedure.i MatchPatternPrecompiled(text.s, pattern.s, regexID.i)
  Protected needle.s

  If regexID
    ProcedureReturn MatchRegularExpression(regexID, text)
  EndIf

  needle = ReplaceString(pattern, "*", "")
  needle = ReplaceString(needle, "?", "")
  needle = Trim(needle)
  If needle <> "" And FindString(LCase(text), LCase(needle), 1)
    ProcedureReturn 1
  EndIf

  ProcedureReturn 0
EndProcedure

Procedure.b IsMatchAllQuery(query.s)
  Protected q.s = LCase(Trim(query))

  If q = "" Or q = "*" Or q = "*.*"
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.s QueryToLikePattern(query.s)
  Protected p.s = Trim(query)

  If IsMatchAllQuery(p)
    ProcedureReturn "%"
  EndIf

  If FindString(p, "*", 1) = 0 And FindString(p, "?", 1) = 0
    p = "*" + p + "*"
  EndIf

  p = ReplaceString(p, "*", "%")
  p = ReplaceString(p, "?", "_")
  p = ReplaceString(p, "'", "''")
  ProcedureReturn p
EndProcedure

Procedure.s ParseRegexQueryPattern(query.s, *ignoreCase.Integer)
  ; Supported syntaxes:
  ;   re:<pattern>      (case-insensitive)
  ;   recs:<pattern>    (case-sensitive)
  ;   /<pattern>/       (case-sensitive)
  ;   /<pattern>/i      (case-insensitive)
  Protected q.s = Trim(query)
  Protected lower.s = LCase(q)
  Protected lastSlash.i
  Protected pos.i
  Protected flags.s

  If *ignoreCase
    *ignoreCase\i = 1
  EndIf

  If Left(lower, 3) = "re:"
    If *ignoreCase : *ignoreCase\i = 1 : EndIf
    ProcedureReturn Trim(Mid(q, 4))
  EndIf

  If Left(lower, 5) = "recs:"
    If *ignoreCase : *ignoreCase\i = 0 : EndIf
    ProcedureReturn Trim(Mid(q, 6))
  EndIf

  If Left(q, 1) = "/"
    lastSlash = 0
    For pos = Len(q) To 2 Step -1
      If Mid(q, pos, 1) = "/"
        lastSlash = pos
        Break
      EndIf
    Next

    If lastSlash > 1
      flags = Trim(Mid(q, lastSlash + 1))
      If *ignoreCase
        *ignoreCase\i = Bool(FindString(LCase(flags), "i", 1) > 0)
      EndIf
      ProcedureReturn Trim(Mid(q, 2, lastSlash - 2))
    EndIf
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.s RegexLiteralHint(pattern.s)
  ; Best-effort: returns the longest run of literal characters in a regex.
  ; Used only to build a SQL LIKE pre-filter.
  Protected i.i, ch.s
  Protected escaped.i
  Protected curr.s = ""
  Protected best.s = ""

  For i = 1 To Len(pattern)
    ch = Mid(pattern, i, 1)

    If escaped
      curr + ch
      escaped = 0
      Continue
    EndIf

    If ch = "\\"
      escaped = 1
      Continue
    EndIf

    Select ch
      Case ".", "^", "$", "*", "+", "?", "(", ")", "[", "]", "{", "}", "|"
        If Len(curr) > Len(best)
          best = curr
        EndIf
        curr = ""
      Default
        curr + ch
    EndSelect
  Next

  If Len(curr) > Len(best)
    best = curr
  EndIf

  best = Trim(best)
  If Len(best) < 3
    ProcedureReturn ""
  EndIf

  ProcedureReturn best
EndProcedure

Procedure RefreshResultsFromDb(query.s)
  Protected likePattern.s
  Protected sql.s
  Protected shown.i
  Protected ignoreCase.i
  Protected regexPattern.s
  Protected regexID.i
  Protected hint.s
  Protected candidateLimit.i
  Protected rowName.s
  Protected rowPath.s
  Protected rowImg.i
  Protected startTime.q = ElapsedMilliseconds()

  If IndexDbId = 0
    ProcedureReturn
  EndIf

  If DbMutex = 0
    ProcedureReturn
  EndIf

  ClearGadgetItems(#Gadget_ResultsList)

  ignoreCase = 1
  regexPattern = ParseRegexQueryPattern(query, @ignoreCase)

  If regexPattern <> "" And Trim(regexPattern) <> ""
    If ignoreCase
      regexID = CreateRegularExpression(#PB_Any, regexPattern, #PB_RegularExpression_NoCase)
    Else
      regexID = CreateRegularExpression(#PB_Any, regexPattern)
    EndIf

    If regexID
      hint = RegexLiteralHint(regexPattern)

      candidateLimit = SearchMaxResults * 40
      If candidateLimit < 10000 : candidateLimit = 10000 : EndIf
      If candidateLimit > 200000 : candidateLimit = 200000 : EndIf

      sql = "SELECT name, path FROM files"
      If hint <> ""
        hint = ReplaceString(hint, "'", "''")
        sql + " WHERE name LIKE '%" + hint + "%' COLLATE NOCASE OR path LIKE '%" + hint + "%' COLLATE NOCASE"
      EndIf
      sql + " LIMIT " + Str(candidateLimit) + ";"

      LockMutex(DbMutex)
      If DatabaseQuery(IndexDbId, sql)
        While NextDatabaseRow(IndexDbId)
          rowName = GetDatabaseString(IndexDbId, 0)
          rowPath = GetDatabaseString(IndexDbId, 1)

          If MatchRegularExpression(regexID, rowName) Or MatchRegularExpression(regexID, rowPath)
            rowImg = GetFileIconIndex(rowPath)
            If rowImg
              AddGadgetItem(#Gadget_ResultsList, -1, rowPath, ImageID(rowImg))
            Else
              AddGadgetItem(#Gadget_ResultsList, -1, rowPath)
            EndIf
            LiveShownPaths(rowPath) = 1
            shown + 1
            If shown >= SearchMaxResults
              Break
            EndIf
          EndIf

          If shown % 500 = 0 And ElapsedMilliseconds() - startTime > 500
            While WindowEvent() : Wend
          EndIf
        Wend
        FinishDatabaseQuery(IndexDbId)
      EndIf
      UnlockMutex(DbMutex)

      FreeRegularExpression(regexID)
      StatusBarText(#StatusBar_Main, 1, "Showing: " + Str(shown) + "  (regex)  Indexed: " + Str(GetIndexedCountCached()))
      ProcedureReturn
    EndIf
  EndIf

  likePattern = QueryToLikePattern(query)

  LockMutex(DbMutex)
  sql = "SELECT path FROM files WHERE name LIKE '" + likePattern + "' COLLATE NOCASE OR path LIKE '" + likePattern + "' COLLATE NOCASE LIMIT " + Str(SearchMaxResults) + ";"
  If DatabaseQuery(IndexDbId, sql)
    While NextDatabaseRow(IndexDbId)
      rowPath = GetDatabaseString(IndexDbId, 0)
      rowImg = GetFileIconIndex(rowPath)
      If rowImg
        AddGadgetItem(#Gadget_ResultsList, -1, rowPath, ImageID(rowImg))
      Else
        AddGadgetItem(#Gadget_ResultsList, -1, rowPath)
      EndIf
      LiveShownPaths(rowPath) = 1
      shown + 1
    Wend
    FinishDatabaseQuery(IndexDbId)
  EndIf
  UnlockMutex(DbMutex)

  StatusBarText(#StatusBar_Main, 1, "Showing: " + Str(shown) + "  Indexed: " + Str(GetIndexedCountCached()))
EndProcedure
