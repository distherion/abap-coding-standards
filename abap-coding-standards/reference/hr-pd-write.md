# HR — PD write path

> Release: the 7.50 API of the PD object layer (`cl_hrbas_*`). The read side — `hr-pd.md`.
> Writing PD/OM objects: the object layer, the dispatch BL data methods and what they already do for you.

## Write path

- **[P1]** PD write — only via the PD object layer, never `RH_INSERT_INFTY`/`RH_MODIFY_INFTY`/direct `HRP1000`/`HRP1001`. Two drives, with **different** trial contracts — do not mix them: <!-- rule: pd-write-via-object-layer -->
  - **Admin** — `cl_hrbas_pd_object_admin=>get_instance( )` → `start_trial( )` → the object methods → `approve_trial( )` + `flush( no_commit = abap_false )`, on error `discard_trial( )`. `start_trial`/`approve_trial`/`discard_trial` take **no parameters** — the cookie is the class attribute `a_magic_cookie_dispatch_bl`, set by `start_trial` and cleared by `approve_trial`/`discard_trial`. **Does not nest**: a second `start_trial( )` before the running one is closed hits `ASSERT a_magic_cookie_dispatch_bl IS INITIAL. "No nesting possible` and **dumps**. `flush` requires `no_commit` — no default.
  - **Dispatch BL** — `if_hrbas_dispatch_bl` includes `if_hrbas_buffer_control` and aliases its five methods (`start_trial`/`approve_trial`/`discard_trial`/`flush`/`initialize`), but here `start_trial( IMPORTING magic_cookie = ... )` **hands the cookie to the caller** and the trials sit on a stack (`a_magic_cookie_stack`) — nesting is allowed, `approve_trial`/`discard_trial( magic_cookie )` close the innermost one. Use this drive when you hold a dispatch-BL reference (integration/BAdI context) instead of the admin singleton.
  Close the trial on every path, including a failed `flush` — the close rule in `hr-pa-write.md` (`hrpa-bl-trial-close`). <!-- rule: pd-object-layer-trial -->

- **[P1]** PD dispatch-BL data methods (`if_hrbas_dispatch_bl~insert`/`modify`/`delete`/`action`) run **their own** trial and do **not** commit: each takes `start_trial` → the infotype logic → `cl_hr_infotype_services=>assert_matching_error_states( message_list = ... is_ok = ... )`, then `CLEANUP. discard_trial( l_magic_cookie )`, then `approve_trial` / `discard_trial` by `is_ok`, then `l_message_list->add_messages( message_handler )`. So a single call needs no wrapping trial, `flush( no_commit = abap_false )` stays the caller's job, and the row messages reach you **only** through the passed `message_handler` — pass a real message list, `is_ok = abap_false` alone tells you nothing. <!-- rule: pd-dispatch-bl-autotrial -->
