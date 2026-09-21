# Date and time

> Date, time, time stamps and time zones — values, arithmetic and the 7.50 APIs around them.
> Related: `numbers.md` (arithmetic and rounding of the results), `data.md` (the types themselves).

## Date arithmetic

- **[P3]** Do not write date arithmetic (months/years, end of month, seniority) by hand — use proven utilities. Where RE-FX is available: `cl_reca_date` — add/subtract: `add_to_date( id_date = ... id_months/id_years/id_days = ... )` (→ `rd_date`), `add_months_to_date( id_months = ... id_date = ... )`, `sub_months_from_date( ... )`; end of month — `set_to_end_of_month( id_date = ... )` / `set_to_begin_of_month( ... )`; diff — `get_days_between_two_dates( id_datefrom = ... id_dateto = ... )`, `months_between_two_dates( id_date_to = ... id_date_from = ... )`, `get_date_diff( id_date_from = ... id_date_to = ... IMPORTING ed_years/ed_months/ed_calendar_days )`. Without RE-FX — FM `RP_CALC_DATE_IN_INTERVAL` (`date`/`days`/`months`/`years`/`signum` → `calc_date`); end of month — `CONV d( lv_first_day_of_next_month - 1 )` or FM `RP_LAST_DAY_OF_MONTHS`; HR month arithmetic (seniority/periods) — `cl_hrpad_date_computations=>add_months_to_date( start_date = ... months = ... )` (→ `date`), `=>get_last_day_in_month( date_in = ... )` (→ `date_out`), or the FM `RE_ADD_MONTH_TO_DATE`; **does not exist:** a generic `ADD_MONTH_TO_DATE` — the FM family is country-specific (`HR_<CC>_ADD_MONTH_TO_DATE`, e.g. `HR_HCP_ADD_MONTH_TO_DATE`).
- **[P3]** Localized date **text**: the Russian month name in the genitive (as printed in documents) comes from the FM `HR_RU_MONTH_NAME_IN_GENITIVE` — do not hard-code an array of month names (case endings and translation). Localized month name = text, so it belongs to the language of the output, not to the stored date.
- **[P3]** Month edges — `LAST_DAY_OF_MONTHS` or its sibling `SLS_MISC_GET_LAST_DAY_OF_MONTH` (both next to the `RP_LAST_DAY_OF_MONTHS` above) — reuse one of them consistently instead of adding a third helper of your own.


## Values and conversions

- **[info]** Types `d`/`t` in arithmetic behave like `i`: `d` = days since 01.01.0001, `t` = seconds since midnight. A direct date difference gives days: `DATA(days) = lv_date2 - lv_date1.` The time stamp in 7.50 is `timestamp`/`timestampl` — **does not exist:** `utclong` and the DDIC types `DATN`/`TIMN` (from 7.54 — see `style.md`, "Version").

- **[P1]** Time difference across midnight — take `MOD 86400`, otherwise a negative result: `DATA(diff) = ( lv_time2 - lv_time1 ) MOD 86400.` <!-- rule: time-diff-across-midnight -->

- **[P3]** Day of week (1 = Monday): do not compute via `lv_date MOD 7`. Compute via the difference from a known Monday (`20240101`): `DATA(wd) = ( lv_date - CONV d( '20240101' ) ) MOD 7 + 1.` (the non-negative remainder — `numbers.md`, `div-mod-nonneg-remainder`). Or FM `DAY_IN_WEEK` (`datum` → `wotnr`, 1 = Monday).

- **[P1]** `CONVERT TIME STAMP ... TIME ZONE ... INTO DATE ... TIME ...` sets `sy-subrc`: `8` = invalid timezone, `12` = invalid timestamp — check immediately (see `errors.md`). <!-- rule: convert-timestamp-check-subrc -->

- **[P1]** `EXACT d( lv_str )` validates the date — on an invalid one it raises `CX_SY_CONVERSION_NO_DATE`; `CONV d( )` does not validate. <!-- rule: exact-date-validates -->

- **[info]** Timezone: server — `sy-datum`/`sy-uzeit`; user's local — `sy-datlo`/`sy-timlo`/`sy-zonlo`. The user timezone — from `sy-zonlo`; `cl_abap_context_info=>get_user_time_zone( )` — NOT in 7.50 (see `style.md`, "Version").

- **[P2]** The current time stamp — `GET TIME STAMP FIELD ts`: a POSIX **UTC** time stamp built from the system date and time. The target must be `timestamp`/`timestampl` (an inline `DATA(ts)` gets the short form); any other type, length or number of decimals — a non-catchable runtime error `GET_TIMESTAMP_FORMAT`. It is UTC, not local time: displaying it to a user or comparing it with a local date/time without an explicit conversion gives an off-by-hours result — wrong near midnight and at period ends. Convert deliberately (`CONVERT TIME STAMP ... TIME ZONE sy-zonlo INTO DATE ... TIME ...` with the `sy-subrc` check above, or `cl_abap_tstmp`) and keep the stored value UTC.

- **[P3]** Timestamp arithmetic — prefer `cl_abap_tstmp`, not manual recomputation of `timestampl`/`CONVERT`: difference — `cl_abap_tstmp=>subtract( tstmp1 = ... tstmp2 = ... )` (→ seconds), add — `cl_abap_tstmp=>add( tstmp = ... secs = ... )`, shift — `cl_abap_tstmp=>subtractsecs( tstmp = ... secs = ... )`. Local↔UTC — `cl_abap_tstmp=>systemtstmp_syst2utc( )`/`systemtstmp_utc2syst( )` (same names exist as FMs; the class methods are the common form); DST — `systemtstmp_syst2loc`/`systemtstmp_loc2syst`, a DST detection — `cl_abap_tstmp=>is_double_interval( date, time )` / `is_double_interval_tzone( )` (RETURNING flag, not an IMPORTING parameter). A seconds-between helper — `cl_abap_timestamp_util=>get_instance( )->tstmp_seconds_between( iv_timestamp0 = ... iv_timestamp1 = ... )`. `CONVERT TIME STAMP` only converts, does not add. In DB `SELECT` — built-ins `tstmp_add_seconds( )`/`tstmp_seconds_between( )`/`tstmp_is_valid( )` — NOT in 7.50 (see `style.md`, "Version"); stay on `cl_abap_tstmp`/`CONVERT TIME STAMP`.
