# Screens (Dynpro)

> Classic Dynpro screens and their ABAP side. "No business logic in modules" and selection screens — `style.md` "Screens and events".

- **[P2]** No business logic in a dialog module (`PBO`/`PAI`): the module reads the screen field / ok-code and delegates to a class method (`style.md`). A `MODULE ... OUTPUT` sets the screen state; a `MODULE ... INPUT` takes the input and calls the check/write method — neither computes or writes directly.
- **[P2]** Always allow the user to leave: the first `MODULE ... AT EXIT-COMMAND` handles the cancel/back function code, before the field checks. A module that raises `MESSAGE ... TYPE 'E'` outside `FIELD`/`CHAIN` leaves no input-ready field — without an `AT EXIT-COMMAND` path the user is stuck.
- **[info]** Single-field check — `FIELD f MODULE mod` (+ `ON REQUEST`: run only when the field was changed). On `E`/`W`, only that field becomes ready for input again, PAI resumes after the `FIELD` statement, earlier modules are not re-run.
- **[P2]** Related fields — check together in `CHAIN … ENDCHAIN`, not as separate `FIELD`s: `CHAIN. FIELD f1. FIELD f2. MODULE check. ENDCHAIN.` On an error, **all** chained fields stay ready for input (separate `FIELD`s gray out the rest after an error). Conditional run — `MODULE m ON CHAIN-INPUT` (any field of the chain has input) / `ON CHAIN-REQUEST` (any changed).
- **[info]** `CHAIN` is meaningful only in PAI (in PBO it has no effect); it cannot be nested.
- **[P2]** The user command — read `ok_code` in PAI, `CLEAR ok_code` at the end of the module (or a stale function code re-fires on the next round). Do not drive control flow from screen-field values that also carry data; function codes carry navigation, fields carry data.
- **[info]** Dynamic screen changes at PBO — `LOOP AT SCREEN` and set the `screen` attributes (`invisible`, `input`, `active`, `required`, `group1..group4`, `name`): `screen-input = 0` disables a field, `screen-invisible = 1` hides it; `MODIFY SCREEN` applies the change. Group fields by `group1..group4` in the Screen Painter to toggle them as one block.
- **[P2]** GUI status and title — `SET PF-STATUS` / `SET TITLEBAR` (in PBO), not hand-made menu/button code; function codes come from the status. Function-key texts and the status belong to the dynpro, not to ABAP literals.
- **[info]** Navigation — `LEAVE TO SCREEN n` (stay in the same screen sequence, PBO re-runs), `CALL SCREEN n` (a separate screen sequence, returns to the caller), `LEAVE SCREEN` (return to the caller's `CALL SCREEN`), `SET SCREEN n` + `LEAVE SCREEN` (leave then call), `LEAVE PROGRAM` (end). `LEAVE TO LIST-PROCESSING` — switch to a classic list (see `alv.md` — prefer ALV over the list).
- **[P3]** Subscreen / tabstrip: `CALL SUBSCREEN` embeds another screen's PBO/PAI; a tabstrip switches subscreens — the embedded screen has its own flow logic. Do not fake tabs with `SET SCREEN` and duplicated fields.
- **[P3]** Do not transport values from screen to program with implicit work areas — use the field with an explicit `TYPE` (see `data.md`, no `TABLES`); the dynpro field and the ABAP variable are the same name by convention, not by the work-area mechanism.

> Sources: SAP Help "Input Checks in Dialog Modules" (CHAIN/FIELD/MODULE, ON CHAIN-INPUT, message handling), ABAPDocu "Dynpro".
