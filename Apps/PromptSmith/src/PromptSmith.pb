; PromptSmith - PureBasic CLI app to generate very detailed AI prompts
; Target: PureBasic 6.30 (Windows x64)

EnableExplicit

#APP_NAME   = "PromptSmith"
#APP_VERSION = "v1.0.0.1"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global AppPath.s = GetPathPart(ProgramFilename())

; Open console first so all output (including errors) goes to the terminal.
OpenConsole("PromptSmith")

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex <> 0 And GetLastError_() = #ERROR_ALREADY_EXISTS
  PrintN(#APP_NAME + " is already running.")
  CloseHandle_(hMutex)
  End
EndIf

Enumeration
  #FormatMarkdown
  #FormatJson
EndEnumeration

Enumeration
  #TemplateGeneral
  #TemplateCoding
  #TemplateWriting
  #TemplateImage
EndEnumeration

Structure PromptSpec
  template.i
  format.i
  title.s
  role.s
  objective.s
  context.s
  inputs.s
  constraints.s
  requiredOutput.s
  styleTone.s
  doList.s
  dontList.s
  edgeCases.s
  evaluation.s
  examples.s
EndStructure

; -------------------- utils --------------------

Procedure.s ReadLinePrompt(label.s, allowEmpty.i=#False)
  Protected s.s
  Repeat
    Print(label)
    s = Input()
    s = Trim(s)
  Until allowEmpty Or s <> ""
  ProcedureReturn s
EndProcedure

Procedure.s ReadMultiLinePrompt(title.s)
  ; User enters multiple lines, ending with a single dot '.' line.
  Protected line.s, out.s
  PrintN(title)
  PrintN("(Enter multiple lines. End with a single '.' line.)")
  While #True
    line = Input()
    If Trim(line) = "."
      Break
    EndIf
    If out <> ""
      out + #CRLF$
    EndIf
    out + line
  Wend
  ProcedureReturn Trim(out)
EndProcedure

Procedure.i ReadChoice(label.s, choices.s, min.i, max.i)
  ; Expects numeric min..max. Prints feedback on invalid input.
  Protected s.s, v.i
  Protected first.i = #True
  Repeat
    If first
      first = #False
    Else
      PrintN("Invalid choice, please try again.")
    EndIf
    PrintN(label)
    PrintN(choices)
    Print("Choice: ")
    s = Trim(Input())
    v = Val(s)
  Until v >= min And v <= max
  ProcedureReturn v
EndProcedure

Procedure.s JoinBulletLines(text.s, bullet.s)
  ; Converts newline-separated items into bullets.
  Protected out.s, i.i, cnt.i
  Protected item.s

  text = Trim(text)
  If text = "" : ProcedureReturn "" : EndIf

  ; Normalize lone LF to CRLF so splitting works regardless of line-ending source.
  text = ReplaceString(text, #CRLF$, #LF$)
  text = ReplaceString(text, #LF$, #CRLF$)

  cnt = CountString(text, #CRLF$) + 1
  For i = 1 To cnt
    item = Trim(StringField(text, i, #CRLF$))
    If item <> ""
      out + bullet + item + #CRLF$
    EndIf
  Next

  ProcedureReturn Trim(out)
EndProcedure

Procedure.s MarkdownSection(title.s, body.s)
  body = Trim(body)
  If body = "" : ProcedureReturn "" : EndIf
  ProcedureReturn "## " + title + #CRLF$ + body + #CRLF$ + #CRLF$
EndProcedure

; -------------------- random generation --------------------

Declare ApplyTemplateDefaults(*s.PromptSpec, fillEmptyOnly.i = #False)

Global gSeeded.i

Procedure SeedIfNeeded(seed.i)
  If gSeeded = #False
    If seed = 0
      RandomSeed(Date())
    Else
      RandomSeed(seed)
    EndIf
    gSeeded = #True
  EndIf
EndProcedure

Procedure.s Pick1(List.s)
  Protected n.i, idx.i
  List = Trim(List)
  If List = "" : ProcedureReturn "" : EndIf
  n = CountString(List, "|") + 1
  idx = Random(n - 1) + 1
  ProcedureReturn StringField(List, idx, "|")
EndProcedure

Procedure.s ThemeNormalize(theme.s)
  theme = LCase(Trim(theme))
  theme = ReplaceString(theme, " ", "")
  ProcedureReturn theme
EndProcedure

Procedure GenerateRandomSpec(*s.PromptSpec, theme.s, forcedTemplate.i = -1)
  Protected subject.s, deliverable.s, audience.s, tone.s
  Protected domain.s, extra.s
  Protected selectedSubject.s, selectedDeliverable.s, selectedAudience.s, selectedTone.s, selectedDomain.s

  theme = ThemeNormalize(theme)
  If theme = "" : theme = "random" : EndIf

  ; Defaults per theme.
  If forcedTemplate <> -1
    *s\template = forcedTemplate
  EndIf

  Select theme
    Case "space", "scifi", "sci-fi", "sciencefiction"
      If forcedTemplate = -1 : *s\template = #TemplateWriting : EndIf
      domain = "hard sci-fi|space opera|near-future|cyberpunk-in-space"
      subject = "an abandoned orbital station|a first-contact negotiation|a salvage crew heist|a ship AI gone rogue|a generation ship crisis"
      deliverable = "a short story scene|a mission briefing|a lore bible excerpt|a dialogue-driven vignette"
      audience = "general readers|YA readers|hard sci-fi fans|tabletop RPG group"
      tone = "cinematic and tense|witty and fast|grounded and realistic|mysterious and eerie"
      extra = "Include plausible space travel constraints.|Use sensory details and technical shorthand sparingly.|Give characters a clear goal and a complication."

    Case "games", "game"
      If forcedTemplate = -1 : *s\template = #TemplateCoding : EndIf
      domain = "2D platformer|roguelite|cozy farming sim|puzzle game|multiplayer party game"
      subject = "a core gameplay loop|a progression system|a combat mechanic|a level generation approach|a UI/UX flow"
      deliverable = "a design doc + pseudocode|a minimal prototype plan|a backlog + milestones|a balancing approach"
      audience = "solo indie dev|small studio|game jam team"
      tone = "clear and pragmatic|creative but shippable|structured and testable"
      extra = "Specify player goals, failure states, and feedback loops.|Include edge cases like pause/resume, saving, and accessibility."

    Case "tools", "tool"
      If forcedTemplate = -1 : *s\template = #TemplateCoding : EndIf
      domain = "CLI tool|desktop utility|automation script|developer productivity app"
      subject = "a log analyzer|a code formatter helper|a backup/sync tool|a note capture tool|a release checklist generator"
      deliverable = "a spec + implementation plan|a minimal viable feature set|a robust error-handling strategy"
      audience = "devs on Windows|ops engineer|non-technical users"
      tone = "direct and professional|safety-first|minimal but powerful"
      extra = "Focus on UX: defaults, confirmations, dry-run modes.|Include security considerations and safe failure modes."

    Case "apps", "app"
      If forcedTemplate = -1 : *s\template = #TemplateGeneral : EndIf
      domain = "mobile app|web app|desktop app|internal admin tool"
      subject = "a habit tracker|a recipe planner|a budgeting dashboard|a study planner|a team status dashboard"
      deliverable = "a product requirements doc|a user story set + acceptance criteria|an information architecture outline"
      audience = "busy professionals|students|families|small teams"
      tone = "helpful and friendly|simple and concise|highly structured"
      extra = "Include primary user journey, data model, and success metrics.|Call out privacy and onboarding."

    Default
      If forcedTemplate = -1 : *s\template = #TemplateGeneral : EndIf
      domain = "creative|practical|technical|educational"
      subject = "a guide|a plan|a checklist|a proposal|a draft"
      deliverable = "a structured response|a step-by-step walkthrough|a template"
      audience = "beginners|intermediate users|experts"
      tone = "clear and helpful|detailed and thorough|concise and actionable"
      extra = "Add assumptions if information is missing.|Ask up to 5 clarifying questions if needed."
  EndSelect

  ApplyTemplateDefaults(*s)

  selectedDomain = Pick1(domain)
  selectedSubject = Pick1(subject)
  selectedDeliverable = Pick1(deliverable)
  selectedAudience = Pick1(audience)
  selectedTone = Pick1(tone)

  *s\title = "Random " + UCase(theme) + " Prompt"

  *s\role = "You are an expert assistant specialized in " + selectedDomain + "."

  *s\context = "Theme: " + theme + #CRLF$ +
               "Domain: " + selectedDomain + #CRLF$ +
               "Tone: " + selectedTone + #CRLF$ +
               "Audience: " + selectedAudience

  *s\constraints = "- Be concrete and avoid vague advice." + #CRLF$ +
                   "- Include at least 10 highly specific details (numbers, names, settings, constraints)." + #CRLF$ +
                   "- Include at least 5 edge cases or failure modes."

  Select *s\template
    Case #TemplateImage
      *s\objective = "Create an image prompt about " + selectedSubject + "."

      *s\inputs = "Theme keyword: " + theme + #CRLF$ +
                  "Optional model: SDXL / Flux / Midjourney" + #CRLF$ +
                  "Desired aspect ratio: 16:9 or 1:1"

      *s\styleTone = "Be extremely visual and specific. Avoid abstract wording."

      *s\requiredOutput = "Return exactly:" + #CRLF$ +
                          "1) FINAL_PROMPT (single line)" + #CRLF$ +
                          "2) NEGATIVE_PROMPT (single line)" + #CRLF$ +
                          "3) SETTINGS (bullets: aspect ratio, style, lighting, lens, steps, cfg, seed)" + #CRLF$ +
                          "4) VARIATIONS (3 alternative prompts)"

      *s\doList = "Specify subject, environment, composition" + #CRLF$ +
                  "Specify lighting, lens/camera, color palette" + #CRLF$ +
                  "Specify art style + level of detail" + #CRLF$ +
                  "Add 3 variations (mood, time of day, framing)"

      *s\dontList = "Do not include conflicting styles" + #CRLF$ +
                    "Do not use vague phrases like 'beautiful' without details"

      *s\edgeCases = "Avoid extra limbs, warped faces, unreadable text/logos, low-res artifacts."

      *s\evaluation = "- Is the prompt unambiguous and visual?" + #CRLF$ +
                      "- Does it specify composition + lighting + style?" + #CRLF$ +
                      "- Is the negative prompt helpful?"

    Case #TemplateCoding
      *s\objective = "Design and implement " + selectedSubject + " for a " + selectedDomain + "."

      *s\inputs = "Target platform: Windows" + #CRLF$ +
                  "Preferred language: choose one and justify" + #CRLF$ +
                  "Constraints: small dependencies, clear CLI/UX"

      *s\styleTone = "Write like a senior engineer: concise, explicit, test-minded."

      *s\requiredOutput = "Output sections:" + #CRLF$ +
                          "1) Requirements (functional + non-functional)" + #CRLF$ +
                          "2) API/CLI Design" + #CRLF$ +
                          "3) Data Structures" + #CRLF$ +
                          "4) Implementation Plan" + #CRLF$ +
                          "5) Tests (unit/integration)" + #CRLF$ +
                          "6) Edge Cases & Failure Modes"

      *s\doList = "Give exact function names or modules" + #CRLF$ +
                  "Include error handling and logging" + #CRLF$ +
                  "Include tests and how to run them"

      *s\dontList = "Do not omit input validation" + #CRLF$ +
                    "Do not propose architecture with no MVP"

      *s\edgeCases = "Include invalid input, empty sets, large files, permission errors, and cancellation."

      *s\evaluation = "- Would the plan be implementable without guessing?" + #CRLF$ +
                      "- Are tests specified and realistic?" + #CRLF$ +
                      "- Are edge cases handled?"

    Case #TemplateWriting
      *s\objective = "Write " + selectedDeliverable + " about " + selectedSubject + "."

      *s\inputs = "Include: a protagonist name, a setting detail, a concrete goal, and a complication." + #CRLF$ +
                  "Length: 800-1200 words"

      *s\styleTone = "Write in a " + selectedTone + " tone with vivid but controlled detail."

      *s\requiredOutput = "Return:" + #CRLF$ +
                          "1) Title" + #CRLF$ +
                          "2) Outline (beats)" + #CRLF$ +
                          "3) Final Text" + #CRLF$ +
                          "4) 5 specificity notes (what makes it concrete)"

      *s\doList = "Show, don't tell (use sensory detail)" + #CRLF$ +
                  "Give characters distinct voices" + #CRLF$ +
                  "Maintain internal logic and stakes"

      *s\dontList = "Do not use generic filler" + #CRLF$ +
                    "Do not break established constraints"

      *s\edgeCases = "Avoid confusing POV swaps; keep timeline consistent; avoid deus ex machina."

      *s\evaluation = "- Is the scene specific and coherent?" + #CRLF$ +
                      "- Are stakes and goals clear?" + #CRLF$ +
                      "- Does the outline match the text?"

    Default
      *s\objective = "Create " + selectedDeliverable + " about " + selectedSubject + "."

      *s\inputs = "Theme keyword: " + theme

      *s\styleTone = "Use a structured format with headings and bullet points." + #CRLF$ +
                     "Write in a " + selectedTone + " tone."

      *s\requiredOutput = "Output sections:" + #CRLF$ +
                          "1) Summary" + #CRLF$ +
                          "2) Assumptions" + #CRLF$ +
                          "3) Main Deliverable" + #CRLF$ +
                          "4) Edge Cases" + #CRLF$ +
                          "5) Checklist" + #CRLF$ +
                          "6) Next Actions"

      *s\doList = "Ask clarifying questions if needed" + #CRLF$ +
                  "Provide steps, not just ideas" + #CRLF$ +
                  "Include a checklist and next actions"

      *s\dontList = "Do not hand-wave technical details" + #CRLF$ +
                    "Do not assume missing requirements without stating assumptions"

      *s\edgeCases = "List edge cases relevant to the deliverable (inputs, time, scale, errors, offline, security)."

      *s\evaluation = "- Does it follow the requested format?" + #CRLF$ +
                      "- Are the details concrete and consistent?" + #CRLF$ +
                      "- Are edge cases addressed?" + #CRLF$ +
                      "- Could a reader execute this with minimal follow-up?"

  EndSelect

  *s\examples = ReplaceString(extra, "|", #CRLF$)
EndProcedure

; -------------------- templates --------------------

Procedure ApplyTemplateDefaults(*s.PromptSpec, fillEmptyOnly.i = #False)
  Select *s\template
    Case #TemplateGeneral
      If fillEmptyOnly = #False Or Trim(*s\title) = "" : *s\title = "Detailed AI Prompt" : EndIf
      If fillEmptyOnly = #False Or Trim(*s\role) = "" : *s\role = "You are an expert assistant." : EndIf
      If fillEmptyOnly = #False Or Trim(*s\requiredOutput) = "" : *s\requiredOutput = "Provide a structured answer with headings, bullet points, and actionable steps." : EndIf
      If fillEmptyOnly = #False Or Trim(*s\evaluation) = "" : *s\evaluation = "Check correctness, completeness, and whether constraints are respected." : EndIf

    Case #TemplateCoding
      If fillEmptyOnly = #False Or Trim(*s\title) = "" : *s\title = "Detailed Coding Task Prompt" : EndIf
      If fillEmptyOnly = #False Or Trim(*s\role) = "" : *s\role = "You are a senior software engineer and careful code reviewer." : EndIf
      If fillEmptyOnly = #False Or Trim(*s\requiredOutput) = "" : *s\requiredOutput = "Return a complete solution, including code, file layout (if relevant), and brief rationale." : EndIf
      If fillEmptyOnly = #False Or Trim(*s\evaluation) = "" : *s\evaluation = "Solution compiles/runs, handles edge cases, follows constraints, and is readable." : EndIf

    Case #TemplateWriting
      If fillEmptyOnly = #False Or Trim(*s\title) = "" : *s\title = "Detailed Writing Task Prompt" : EndIf
      If fillEmptyOnly = #False Or Trim(*s\role) = "" : *s\role = "You are an expert editor and writer." : EndIf
      If fillEmptyOnly = #False Or Trim(*s\requiredOutput) = "" : *s\requiredOutput = "Deliver the final text plus an outline and rationale for key choices." : EndIf
      If fillEmptyOnly = #False Or Trim(*s\evaluation) = "" : *s\evaluation = "Meets audience and tone, is coherent, and follows formatting requirements." : EndIf

    Case #TemplateImage
      If fillEmptyOnly = #False Or Trim(*s\title) = "" : *s\title = "Detailed Image Generation Prompt" : EndIf
      If fillEmptyOnly = #False Or Trim(*s\role) = "" : *s\role = "You are a prompt engineer for image models." : EndIf
      If fillEmptyOnly = #False Or Trim(*s\requiredOutput) = "" : *s\requiredOutput = "Return a single final prompt plus negative prompt and suggested settings." : EndIf
      If fillEmptyOnly = #False Or Trim(*s\evaluation) = "" : *s\evaluation = "Prompt is specific, unambiguous, and covers composition, lighting, style, and constraints." : EndIf
  EndSelect
EndProcedure

; -------------------- rendering --------------------

Procedure.s RenderMarkdown(*s.PromptSpec)
  Protected out.s

  out + "# " + *s\title + #CRLF$ + #CRLF$
  out + MarkdownSection("Role", *s\role)
  out + MarkdownSection("Objective", *s\objective)
  out + MarkdownSection("Context", *s\context)
  out + MarkdownSection("Inputs", *s\inputs)
  out + MarkdownSection("Constraints", *s\constraints)
  out + MarkdownSection("Style & Tone", *s\styleTone)

  If Trim(*s\doList) <> ""
    out + "## Do" + #CRLF$ + JoinBulletLines(*s\doList, "- ") + #CRLF$ + #CRLF$
  EndIf
  If Trim(*s\dontList) <> ""
    out + "## Don't" + #CRLF$ + JoinBulletLines(*s\dontList, "- ") + #CRLF$ + #CRLF$
  EndIf

  out + MarkdownSection("Required Output", *s\requiredOutput)
  out + MarkdownSection("Edge Cases", *s\edgeCases)
  out + MarkdownSection("Evaluation Checklist", *s\evaluation)
  out + MarkdownSection("Examples", *s\examples)

  out + "---" + #CRLF$
  out + "(Generated by PromptSmith)" + #CRLF$
  ProcedureReturn out
EndProcedure

Procedure.s RenderJson(*s.PromptSpec)
  Protected json.i, root.i, out.s

  json = CreateJSON(#PB_Any)
  If json = 0
    ProcedureReturn "{}" + #CRLF$
  EndIf

  root = SetJSONObject(JSONValue(json))
  SetJSONString(AddJSONMember(root, "title"), *s\title)
  SetJSONString(AddJSONMember(root, "role"), *s\role)
  SetJSONString(AddJSONMember(root, "objective"), *s\objective)
  SetJSONString(AddJSONMember(root, "context"), *s\context)
  SetJSONString(AddJSONMember(root, "inputs"), *s\inputs)
  SetJSONString(AddJSONMember(root, "constraints"), *s\constraints)
  SetJSONString(AddJSONMember(root, "styleTone"), *s\styleTone)
  SetJSONString(AddJSONMember(root, "do"), *s\doList)
  SetJSONString(AddJSONMember(root, "dont"), *s\dontList)
  SetJSONString(AddJSONMember(root, "requiredOutput"), *s\requiredOutput)
  SetJSONString(AddJSONMember(root, "edgeCases"), *s\edgeCases)
  SetJSONString(AddJSONMember(root, "evaluation"), *s\evaluation)
  SetJSONString(AddJSONMember(root, "examples"), *s\examples)

  out = ComposeJSON(json, #PB_JSON_PrettyPrint)
  FreeJSON(json)
  ProcedureReturn out + #CRLF$
EndProcedure

Procedure.s Render(*s.PromptSpec)
  If *s\format = #FormatJson
    ProcedureReturn RenderJson(*s)
  Else
    ProcedureReturn RenderMarkdown(*s)
  EndIf
EndProcedure

; -------------------- IO helpers --------------------

Procedure.i EnsureDirectoryExists(dir.s)
  Protected normalized.s, current.s, part.s
  Protected i.i, cnt.i, size.i

  normalized = Trim(ReplaceString(dir, "/", "\"))
  If normalized = ""
    ProcedureReturn #True
  EndIf

  If Len(normalized) = 2 And Right(normalized, 1) = ":"
    normalized + "\"
  EndIf

  While Len(normalized) > 3 And Right(normalized, 1) = "\"
    normalized = Left(normalized, Len(normalized) - 1)
  Wend

  If normalized = ""
    ProcedureReturn #True
  EndIf

  size = FileSize(normalized)
  If size = -2
    ProcedureReturn #True
  EndIf
  If size <> -1
    ProcedureReturn #False
  EndIf

  If Mid(normalized, 2, 2) = ":\"
    current = Left(normalized, 3)
    normalized = Mid(normalized, 4)
  ElseIf Left(normalized, 1) = "\"
    current = "\"
    normalized = Mid(normalized, 2)
  EndIf

  cnt = CountString(normalized, "\") + 1
  For i = 1 To cnt
    part = StringField(normalized, i, "\")
    If part <> ""
      If current = "" Or Right(current, 1) = "\"
        current + part
      Else
        current + "\" + part
      EndIf

      size = FileSize(current)
      If size = -1
        If CreateDirectory(current) = 0
          ProcedureReturn #False
        EndIf
      ElseIf size <> -2
        ProcedureReturn #False
      EndIf
    EndIf
  Next

  ProcedureReturn #True
EndProcedure

Procedure.i WriteToFile(path.s, content.s)
  Protected file.i
  Protected dir.s = GetPathPart(path)
  If dir <> ""
    While Len(dir) > 3 And (Right(dir, 1) = "\" Or Right(dir, 1) = "/")
      dir = Left(dir, Len(dir) - 1)
    Wend
  EndIf
  If EnsureDirectoryExists(dir) = #False
    ProcedureReturn #False
  EndIf
  file = CreateFile(#PB_Any, path)
  If file
    WriteString(file, content, #PB_UTF8)
    CloseFile(file)
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure.i CopyToClipboard(text.s)
  ProcedureReturn SetClipboardText(text)
EndProcedure

; -------------------- CLI --------------------

Procedure PrintUsage()
  PrintN("PromptSmith (PureBasic) - generate detailed AI prompts")
  PrintN("")
  PrintN("Usage:")
  PrintN("  PromptSmith.exe [--wizard] [--quick]")
  PrintN("  PromptSmith.exe --random <theme> [--seed <n>] [--randomtemplate general|coding|writing|image]")
  PrintN("  PromptSmith.exe --quick  (minimal questions, auto-fills the rest)")
  PrintN("  PromptSmith.exe --quick --theme <word> --randomtemplate coding|writing|image|general --autoout [--autoclip] [--goal '...']")
  PrintN("  PromptSmith.exe --yes   (never prompt; choose safe defaults)")
  PrintN("              [--format md|json] [--out path] [--clip]")
  PrintN("  PromptSmith.exe --template general|coding|writing|image --format md|json [--title '...'] [--role '...']")
  PrintN("              [--objective '...'] [--context '...'] [--inputs '...'] [--constraints '...']")
  PrintN("              [--style '...'] [--do '...'] [--dont '...'] [--required '...']")
  PrintN("              [--edge '...'] [--eval '...'] [--examples '...']")
  PrintN("              [--out path] [--clip]")
  PrintN("")
  PrintN("Notes:")
  PrintN("  - If any of the content flags are used, wizard is disabled.")
  PrintN("  - Random themes: space, scifi, games, tools, apps (and any other word).")
  PrintN("  - Use literal newlines in values if your shell supports it, or use " + Chr(39) + "\\n" + Chr(39) + ".")
  PrintN("  - Help: --help, -h, -help, /?")
  PrintN("  - Use --pause to wait for Enter before exit.")
  PrintN("  - Use --raw to suppress OUTPUT START/END markers (clean output for files/piping).")
  PrintN("  - Use --version to display the version number.")
EndProcedure

Procedure MaybeWaitForUserOnExit(forceWait.i = #False)
  If forceWait
    PrintN("")
    Print("Press Enter to exit...")
    Input()
  EndIf
EndProcedure

Procedure.i IsHelpArg(aLower.s)
  aLower = LCase(aLower)
  If aLower = "--help" Or aLower = "-h" Or aLower = "-help" Or aLower = "/?"
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure.i HasAnyHelpArg()
  Protected i.i
  For i = 0 To CountProgramParameters() - 1
    If IsHelpArg(ProgramParameter(i))
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

Procedure.s NormalizeNewlines(s.s)
  ; Supports passing "\\n" or "\n" via CLI.
  s = ReplaceString(s, "\\n", #CRLF$)
  s = ReplaceString(s, "\n", #CRLF$)
  ProcedureReturn s
EndProcedure

Procedure.s ReadArgValueChecked(flag.s, i.i, *ok.Integer)
  Protected value.s

  *ok\i = #False
  If i >= CountProgramParameters() - 1
    PrintN("Error: " + flag + " expects a value.")
    ProcedureReturn ""
  EndIf

  value = ProgramParameter(i + 1)
  If Left(value, 2) = "--" Or IsHelpArg(value)
    PrintN("Error: " + flag + " expects a value.")
    ProcedureReturn ""
  EndIf

  *ok\i = #True
  ProcedureReturn value
EndProcedure

Procedure.i IsIntegerText(value.s)
  Protected i.i, ch.s

  value = Trim(value)
  If value = ""
    ProcedureReturn #False
  EndIf

  If Left(value, 1) = "+" Or Left(value, 1) = "-"
    If Len(value) = 1
      ProcedureReturn #False
    EndIf
    value = Mid(value, 2)
  EndIf

  For i = 1 To Len(value)
    ch = Mid(value, i, 1)
    If ch < "0" Or ch > "9"
      ProcedureReturn #False
    EndIf
  Next

  ProcedureReturn #True
EndProcedure

Procedure.i HasFlag(flag.s)
  Protected i.i
  Protected aLower.s
  flag = LCase(flag)
  For i = 0 To CountProgramParameters() - 1
    aLower = LCase(ProgramParameter(i))
    If aLower = flag
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

Procedure.i ParseArgs(*s.PromptSpec, *outPath.String, *clip.Integer, *randomTheme.String, *seed.Integer, *randomTemplate.Integer, *quick.Integer, *theme.String, *goal.String, *autoOut.Integer, *autoClip.Integer, *yes.Integer, *templateSpecified.Integer, *formatSpecified.Integer, *parseOk.Integer)
  Protected i.i
  Protected a.s, aLower.s, v.s
  Protected useWizard.i = #False
  Protected sawAnyArg.i = #False
  Protected sawValueFlag.i = #False
  Protected sawQuickOnlyFlag.i = #False
  Protected gotValue.Integer

  *parseOk\i = #True
  *templateSpecified\i = #False
  *formatSpecified\i = #False

  For i = 0 To CountProgramParameters() - 1
    a = ProgramParameter(i)
    aLower = LCase(a)

    If IsHelpArg(aLower)
      ProcedureReturn #False
    EndIf

    sawAnyArg = #True

    Select aLower
      Case "--wizard"
        useWizard = #True

      Case "--quick"
        useWizard = #True
        *quick\i = #True

      Case "--random"
        v = ReadArgValueChecked("--random", i, @gotValue)
        If gotValue\i = #False
          *parseOk\i = #False
          Break
        EndIf
        *randomTheme\s = v : i + 1

      Case "--seed"
        v = ReadArgValueChecked("--seed", i, @gotValue)
        If gotValue\i = #False
          *parseOk\i = #False
          Break
        EndIf
        If IsIntegerText(v) = #False
          PrintN("Error: --seed expects an integer value.")
          *parseOk\i = #False
          Break
        EndIf
        *seed\i = Val(v) : i + 1

      Case "--randomtemplate"
        v = LCase(ReadArgValueChecked("--randomtemplate", i, @gotValue))
        If gotValue\i = #False
          *parseOk\i = #False
          Break
        EndIf
        Select v
          Case "general" : *randomTemplate\i = #TemplateGeneral
          Case "coding"  : *randomTemplate\i = #TemplateCoding
          Case "writing" : *randomTemplate\i = #TemplateWriting
          Case "image"   : *randomTemplate\i = #TemplateImage
          Default
            PrintN("Error: invalid value for --randomtemplate: " + v)
            *parseOk\i = #False
            Break
        EndSelect
        i + 1

      Case "--template"
        v = LCase(ReadArgValueChecked("--template", i, @gotValue))
        If gotValue\i = #False
          *parseOk\i = #False
          Break
        EndIf
        Select v
          Case "general" : *s\template = #TemplateGeneral
          Case "coding"  : *s\template = #TemplateCoding
          Case "writing" : *s\template = #TemplateWriting
          Case "image"   : *s\template = #TemplateImage
          Default
            PrintN("Error: invalid value for --template: " + v)
            *parseOk\i = #False
            Break
        EndSelect
        *templateSpecified\i = #True
        i + 1

      Case "--format"
        v = LCase(ReadArgValueChecked("--format", i, @gotValue))
        If gotValue\i = #False
          *parseOk\i = #False
          Break
        EndIf
        Select v
          Case "json"
            *s\format = #FormatJson
          Case "md", "markdown"
            *s\format = #FormatMarkdown
          Default
            PrintN("Error: invalid value for --format: " + v)
            *parseOk\i = #False
            Break
        EndSelect
        *formatSpecified\i = #True
        i + 1

      Case "--title"
        v = ReadArgValueChecked("--title", i, @gotValue)
        If gotValue\i = #False : *parseOk\i = #False : Break : EndIf
        *s\title = NormalizeNewlines(v) : i + 1 : sawValueFlag = #True

      Case "--role"
        v = ReadArgValueChecked("--role", i, @gotValue)
        If gotValue\i = #False : *parseOk\i = #False : Break : EndIf
        *s\role = NormalizeNewlines(v) : i + 1 : sawValueFlag = #True

      Case "--objective"
        v = ReadArgValueChecked("--objective", i, @gotValue)
        If gotValue\i = #False : *parseOk\i = #False : Break : EndIf
        *s\objective = NormalizeNewlines(v) : i + 1 : sawValueFlag = #True

      Case "--context"
        v = ReadArgValueChecked("--context", i, @gotValue)
        If gotValue\i = #False : *parseOk\i = #False : Break : EndIf
        *s\context = NormalizeNewlines(v) : i + 1 : sawValueFlag = #True

      Case "--inputs"
        v = ReadArgValueChecked("--inputs", i, @gotValue)
        If gotValue\i = #False : *parseOk\i = #False : Break : EndIf
        *s\inputs = NormalizeNewlines(v) : i + 1 : sawValueFlag = #True

      Case "--constraints"
        v = ReadArgValueChecked("--constraints", i, @gotValue)
        If gotValue\i = #False : *parseOk\i = #False : Break : EndIf
        *s\constraints = NormalizeNewlines(v) : i + 1 : sawValueFlag = #True

      Case "--style"
        v = ReadArgValueChecked("--style", i, @gotValue)
        If gotValue\i = #False : *parseOk\i = #False : Break : EndIf
        *s\styleTone = NormalizeNewlines(v) : i + 1 : sawValueFlag = #True

      Case "--do"
        v = ReadArgValueChecked("--do", i, @gotValue)
        If gotValue\i = #False : *parseOk\i = #False : Break : EndIf
        *s\doList = NormalizeNewlines(v) : i + 1 : sawValueFlag = #True

      Case "--dont"
        v = ReadArgValueChecked("--dont", i, @gotValue)
        If gotValue\i = #False : *parseOk\i = #False : Break : EndIf
        *s\dontList = NormalizeNewlines(v) : i + 1 : sawValueFlag = #True

      Case "--required"
        v = ReadArgValueChecked("--required", i, @gotValue)
        If gotValue\i = #False : *parseOk\i = #False : Break : EndIf
        *s\requiredOutput = NormalizeNewlines(v) : i + 1 : sawValueFlag = #True

      Case "--edge"
        v = ReadArgValueChecked("--edge", i, @gotValue)
        If gotValue\i = #False : *parseOk\i = #False : Break : EndIf
        *s\edgeCases = NormalizeNewlines(v) : i + 1 : sawValueFlag = #True

      Case "--eval"
        v = ReadArgValueChecked("--eval", i, @gotValue)
        If gotValue\i = #False : *parseOk\i = #False : Break : EndIf
        *s\evaluation = NormalizeNewlines(v) : i + 1 : sawValueFlag = #True

      Case "--examples"
        v = ReadArgValueChecked("--examples", i, @gotValue)
        If gotValue\i = #False : *parseOk\i = #False : Break : EndIf
        *s\examples = NormalizeNewlines(v) : i + 1 : sawValueFlag = #True

      Case "--theme"
        v = ReadArgValueChecked("--theme", i, @gotValue)
        If gotValue\i = #False : *parseOk\i = #False : Break : EndIf
        *theme\s = v : i + 1 : sawQuickOnlyFlag = #True

      Case "--goal"
        v = ReadArgValueChecked("--goal", i, @gotValue)
        If gotValue\i = #False : *parseOk\i = #False : Break : EndIf
        *goal\s = NormalizeNewlines(v) : i + 1 : sawQuickOnlyFlag = #True

      Case "--autoout"
        *autoOut\i = #True
        sawQuickOnlyFlag = #True

      Case "--autoclip"
        *autoClip\i = #True
        sawQuickOnlyFlag = #True

      Case "--yes"
        *yes\i = #True

      Case "--out"
        v = ReadArgValueChecked("--out", i, @gotValue)
        If gotValue\i = #False : *parseOk\i = #False : Break : EndIf
        *outPath\s = v : i + 1

      Case "--clip"
        *clip\i = #True

      Case "--raw", "--pause", "--version"
        ; Handled elsewhere.

      Default
        PrintN("Error: unknown argument: " + a)
        *parseOk\i = #False
        Break

    EndSelect
  Next

  If *parseOk\i = #False
    ProcedureReturn #False
  EndIf

  ; Wizard rules:
  ; - If no args -> wizard
  ; - If --wizard explicitly -> wizard
  ; - If --random is used -> non-wizard
  ; - If any content flags -> non-wizard
  If sawAnyArg = #False
    ProcedureReturn #True
  EndIf

  If sawValueFlag And *quick\i
    PrintN("Error: content flags cannot be combined with --quick.")
    *parseOk\i = #False
    ProcedureReturn #False
  EndIf

  If sawValueFlag And Trim(*randomTheme\s) <> ""
    PrintN("Error: content flags cannot be combined with --random.")
    *parseOk\i = #False
    ProcedureReturn #False
  EndIf

  If Trim(*randomTheme\s) <> "" And (*quick\i Or sawQuickOnlyFlag)
    PrintN("Error: --random cannot be combined with --quick, --theme, --goal, --autoout, or --autoclip.")
    *parseOk\i = #False
    ProcedureReturn #False
  EndIf

  If sawQuickOnlyFlag And *quick\i = #False
    PrintN("Error: --theme, --goal, --autoout, and --autoclip require --quick.")
    *parseOk\i = #False
    ProcedureReturn #False
  EndIf

  If *randomTemplate\i <> -1 And Trim(*randomTheme\s) = "" And *quick\i = #False
    PrintN("Error: --randomtemplate requires --random or --quick.")
    *parseOk\i = #False
    ProcedureReturn #False
  EndIf

  If Trim(*randomTheme\s) <> ""
    ProcedureReturn #False
  EndIf

  If sawValueFlag
    ProcedureReturn #False
  EndIf

  If useWizard
    ProcedureReturn #True
  EndIf

  ; If user only set template/format/out/clip, assume non-interactive (emit defaults).
  ProcedureReturn #False
EndProcedure

Procedure.i PickTemplate()
  Protected c.i
  c = ReadChoice("Pick a template:", "1) General" + #CRLF$ + "2) Coding" + #CRLF$ + "3) Writing" + #CRLF$ + "4) Image", 1, 4)
  Select c
    Case 1 : ProcedureReturn #TemplateGeneral
    Case 2 : ProcedureReturn #TemplateCoding
    Case 3 : ProcedureReturn #TemplateWriting
    Case 4 : ProcedureReturn #TemplateImage
  EndSelect
  ProcedureReturn #TemplateGeneral
EndProcedure

Procedure.s AutoOutPath(theme.s, format.i)
  Protected ext.s
  Protected ts.s

  If format = #FormatJson
    ext = "json"
  Else
    ext = "md"
  EndIf

  ts = FormatDate("[%yy-%mm-%dd]_[%hh-%ii-%ss]", Date())
  theme = ThemeNormalize(theme)
  If theme = "" : theme = "prompt" : EndIf

  ProcedureReturn "promptsmith\\prompt_" + theme + "_" + ts + "." + ext
EndProcedure

Procedure ApplyQuickGoal(*s.PromptSpec, goal.s)
  goal = Trim(goal)
  If goal <> ""
    *s\objective = Trim(*s\objective) + #CRLF$ + "User goal: " + goal
  EndIf
EndProcedure

Procedure PrepareQuickSpec(*s.PromptSpec, theme.s, goal.s, *seed.Integer, forcedTemplate.i = -1)
  If forcedTemplate <> -1
    *s\template = forcedTemplate
  EndIf

  SeedIfNeeded(*seed\i)
  GenerateRandomSpec(*s, theme, forcedTemplate)
  ApplyQuickGoal(*s, goal)
EndProcedure

Procedure FinalizeQuickOutput(theme.s, format.i, *outPath.String, *clip.Integer, autoOut.i, autoClip.i, yes.i, promptForOutput.i, promptForClipboard.i, rawOutput.i = #False)
  Protected c.i

  If autoOut Or yes
    If Trim(*outPath\s) = ""
      *outPath\s = AutoOutPath(theme, format)
    EndIf
  ElseIf promptForOutput And Trim(*outPath\s) = ""
    *outPath\s = ReadLinePrompt("Output file path (blank to skip): ", #True)
  EndIf

  If autoClip
    *clip\i = #True
  ElseIf promptForClipboard And *clip\i = #False And yes = #False And rawOutput = #False
    c = ReadChoice("Copy result to clipboard?", "1) No" + #CRLF$ + "2) Yes", 1, 2)
    If c = 2 : *clip\i = #True : EndIf
  EndIf
EndProcedure

Procedure.i QuickNeedsInteraction(theme.s, formatSpecified.i, outPath.s, autoOut.i, clip.i, autoClip.i, yes.i, rawOutput.i)
  If yes
    ProcedureReturn #False
  EndIf

  If Trim(theme) = ""
    ProcedureReturn #True
  EndIf

  If formatSpecified = #False
    ProcedureReturn #True
  EndIf

  If autoOut = #False And Trim(outPath) = ""
    ProcedureReturn #True
  EndIf

  If rawOutput = #False And autoClip = #False And clip = #False
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure RunQuickWizard(*s.PromptSpec, *outPath.String, *clip.Integer, *seed.Integer, *themeArg.String, *goalArg.String, templateSpecified.i = #False, formatPreselected.i = #False, autoOut.i = #False, autoClip.i = #False)
  Protected c.i
  Protected theme.s, goal.s
  Protected forcedTemplate.i = -1

  PrintN("PromptSmith quick wizard")
  PrintN("------------------------")

  If Trim(*themeArg\s) <> ""
    theme = *themeArg\s
    PrintN("Theme: " + theme)
  Else
    theme = ReadLinePrompt("Theme (one word, e.g. space, scifi, games, tools, apps): ")
  EndIf

  If templateSpecified = #False And Trim(*themeArg\s) = ""
    *s\template = PickTemplate()
    forcedTemplate = *s\template
  ElseIf templateSpecified
    forcedTemplate = *s\template
  EndIf

  If formatPreselected = #False
    c = ReadChoice("Pick output format:", "1) Markdown" + #CRLF$ + "2) JSON", 1, 2)
    If c = 2 : *s\format = #FormatJson : Else : *s\format = #FormatMarkdown : EndIf
  EndIf

  If Trim(*goalArg\s) <> ""
    goal = *goalArg\s
    PrintN("Goal: " + ReplaceString(goal, #CRLF$, " | "))
  Else
    goal = ReadLinePrompt("Optional goal (1 line, blank to skip): ", #True)
  EndIf

  PrepareQuickSpec(*s, theme, goal, *seed, forcedTemplate)
  FinalizeQuickOutput(theme, *s\format, *outPath, *clip, autoOut, autoClip, #False, #True, #True, #False)
EndProcedure

Procedure RunWizard(*s.PromptSpec, *outPath.String, *clip.Integer)
  Protected c.i

  PrintN("PromptSmith interactive wizard")
  PrintN("------------------------------")

  *s\template = PickTemplate()

  c = ReadChoice("Pick output format:", "1) Markdown" + #CRLF$ + "2) JSON", 1, 2)
  If c = 2 : *s\format = #FormatJson : Else : *s\format = #FormatMarkdown : EndIf

  *s\title = ReadLinePrompt("Title (short): ")
  *s\role = ReadLinePrompt("Role (who the model is): ")

  *s\objective = ReadMultiLinePrompt("Objective (what to do):")
  *s\context = ReadMultiLinePrompt("Context (background, domain, audience):")
  *s\inputs = ReadMultiLinePrompt("Inputs (data you provide, sources, assumptions):")
  *s\constraints = ReadMultiLinePrompt("Constraints (must/must-not, tools, scope, time):")
  *s\styleTone = ReadMultiLinePrompt("Style & tone (voice, reading level, formatting):")

  *s\doList = ReadMultiLinePrompt("Do list (one per line):")
  *s\dontList = ReadMultiLinePrompt("Don't list (one per line):")

  *s\requiredOutput = ReadMultiLinePrompt("Required output (exact sections, schema, length):")
  *s\edgeCases = ReadMultiLinePrompt("Edge cases / pitfalls to cover:")
  *s\evaluation = ReadMultiLinePrompt("Evaluation checklist (how to judge success):")
  *s\examples = ReadMultiLinePrompt("Examples (optional; include minimal examples):")

  *outPath\s = ReadLinePrompt("Output file path (blank to skip): ", #True)

  c = ReadChoice("Copy result to clipboard?", "1) No" + #CRLF$ + "2) Yes", 1, 2)
  If c = 2 : *clip\i = #True : EndIf
EndProcedure

; -------------------- main --------------------

; Strict early-exit handlers.
If HasAnyHelpArg()
  PrintUsage()
  MaybeWaitForUserOnExit(HasFlag("--pause"))
  CloseHandle_(hMutex)
  End
EndIf

If HasFlag("--version")
  PrintN(#APP_NAME + " " + #APP_VERSION)
  MaybeWaitForUserOnExit(HasFlag("--pause"))
  CloseConsole()
  CloseHandle_(hMutex)
  End
EndIf

Define spec.PromptSpec
Define outPath.String
Define clip.Integer

spec\template = #TemplateGeneral
spec\format = #FormatMarkdown

Define randomTheme.String
Define seed.Integer

Define randomTemplate.Integer
randomTemplate\i = -1

Define quick.Integer

Define theme.String
Define goal.String
Define autoOut.Integer
Define autoClip.Integer
Define yes.Integer
Define templateSpecified.Integer
Define formatSpecified.Integer
Define parseOk.Integer
Define rawOutput.i = HasFlag("--raw")

Define interactive.i = ParseArgs(@spec, @outPath, @clip, @randomTheme, @seed, @randomTemplate, @quick, @theme, @goal, @autoOut, @autoClip, @yes, @templateSpecified, @formatSpecified, @parseOk)
Define shouldPauseOnExit.i
Define quickNeedsInteraction.i

If parseOk\i = #False
  MaybeWaitForUserOnExit(HasFlag("--pause"))
  CloseConsole()
  CloseHandle_(hMutex)
  End
EndIf

shouldPauseOnExit = Bool(HasFlag("--pause") Or (interactive And yes\i = #False))

If quick\i
  quickNeedsInteraction = QuickNeedsInteraction(theme\s, formatSpecified\i, outPath\s, autoOut\i, clip\i, autoClip\i, yes\i, rawOutput)

  shouldPauseOnExit = Bool(HasFlag("--pause") Or quickNeedsInteraction)
EndIf

If Trim(randomTheme\s) <> ""
  SeedIfNeeded(seed\i)
  If randomTemplate\i <> -1
    GenerateRandomSpec(@spec, randomTheme\s, randomTemplate\i)
  ElseIf templateSpecified\i
    GenerateRandomSpec(@spec, randomTheme\s, spec\template)
  Else
    GenerateRandomSpec(@spec, randomTheme\s, -1)
  EndIf

  If yes\i
    If Trim(outPath\s) = ""
      outPath\s = AutoOutPath(randomTheme\s, spec\format)
    EndIf
    If autoClip\i
      clip\i = #True
    EndIf
  EndIf
Else
  If interactive
    If quick\i
      If Trim(theme\s) <> ""
        If randomTemplate\i <> -1
          PrepareQuickSpec(@spec, theme\s, goal\s, @seed, randomTemplate\i)
        ElseIf templateSpecified\i
          PrepareQuickSpec(@spec, theme\s, goal\s, @seed, spec\template)
        Else
          PrepareQuickSpec(@spec, theme\s, goal\s, @seed, -1)
        EndIf
        FinalizeQuickOutput(theme\s, spec\format, @outPath, @clip, autoOut\i, autoClip\i, yes\i, #True, #True, rawOutput)
      Else
        If yes\i
          If Trim(theme\s) = ""
            theme\s = "random"
          EndIf

          If randomTemplate\i <> -1
            PrepareQuickSpec(@spec, theme\s, goal\s, @seed, randomTemplate\i)
          ElseIf templateSpecified\i
            PrepareQuickSpec(@spec, theme\s, goal\s, @seed, spec\template)
          Else
            PrepareQuickSpec(@spec, theme\s, goal\s, @seed, -1)
          EndIf
          FinalizeQuickOutput(theme\s, spec\format, @outPath, @clip, autoOut\i, autoClip\i, yes\i, #False, #False, rawOutput)
        Else
          If randomTemplate\i <> -1
            spec\template = randomTemplate\i
          EndIf
          RunQuickWizard(@spec, @outPath, @clip, @seed, @theme, @goal, Bool(templateSpecified\i Or randomTemplate\i <> -1), formatSpecified\i, autoOut\i, autoClip\i)
        EndIf
      EndIf
    Else
      If yes\i
        ApplyTemplateDefaults(@spec)
      Else
        ApplyTemplateDefaults(@spec)
        RunWizard(@spec, @outPath, @clip)
      EndIf
    EndIf
  Else
    ApplyTemplateDefaults(@spec, #True)
  EndIf

  If spec\title = "" : spec\title = "Detailed AI Prompt" : EndIf
  If spec\role = "" : spec\role = "You are an expert assistant." : EndIf
EndIf

Define result.s = Render(@spec)

If rawOutput
  PrintN(result)
Else
  PrintN("")
  PrintN("--- OUTPUT START ---")
  PrintN(result)
  PrintN("--- OUTPUT END ---")
EndIf

If Trim(outPath\s) <> ""
  If WriteToFile(outPath\s, result)
    If rawOutput = #False
      PrintN("Wrote: " + outPath\s)
    EndIf
  Else
    If rawOutput = #False
      PrintN("Failed to write: " + outPath\s)
    EndIf
  EndIf
EndIf

If clip\i
  If CopyToClipboard(result)
    If rawOutput = #False
      PrintN("Copied to clipboard.")
    EndIf
  Else
    If rawOutput = #False
      PrintN("Failed to copy to clipboard.")
    EndIf
  EndIf
EndIf

If rawOutput = #False
  PrintN("")
  PrintN("Done.")
EndIf

MaybeWaitForUserOnExit(shouldPauseOnExit)

CloseConsole()
CloseHandle_(hMutex)
End
; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 6
; Folding = ------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = PromptSmith.ico
; Executable = ..\PromptSmith.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,1
; VersionField1 = 1,0,0,1
; VersionField2 = ZoneSoft
; VersionField3 = PromptSmith
; VersionField4 = 1.0.0.1
; VersionField5 = 1.0.0.1
; VersionField6 = An automated AI prompt generator
; VersionField7 = PromptSmith
; VersionField8 = PromptSmith.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60
