# Dynamic programming and RTTI

- **[P2]** Dynamics — only when static is impossible (generic by type/structure/field). Static is preferable: the compiler does not catch dynamic errors.
- **[info]** RTTI (Runtime Type Identification): `cl_abap_typedescr=>describe_by_data( dobj )` → `cl_abap_structdescr`/`cl_abap_tabledescr`/`cl_abap_elemdescr`/`cl_abap_refdescr`; by DDIC type — `describe_by_name( 'TYPE_NAME' )`.
- **[info]** RTTS (Runtime Type Creation): `cl_abap_structdescr=>create( )` / `cl_abap_tabledescr=>create( ... )` / `cl_abap_elemdescr=>get_*`, then `CREATE DATA ... TYPE HANDLE`.
- **[P2]** `ASSIGN COMPONENT comp OF STRUCTURE <fs> TO <f>` (or `(compname)`) — only after checking the component exists (`cl_abap_structdescr->get_components` / `line_exists`), otherwise `CX_SY_ASSIGN_OUT_OF_RANGE`/`sy-subrc <> 0`. `ASSIGN (name)` without a whitelist — see `security.md`.
- **[P2]** Dynamic component/field names — the source is not external, validate it (see `security.md`: `CL_ABAP_DYN_PRG`).
- **[P3]** `DESCRIBE FIELD lv TYPE typ [LENGTH len] [DECIMALS dec]` / `DESCRIBE TABLE itab LINES lv_lines` — only when one attribute is needed; full description — via RTTI.
- **[info]** Downcast — `CAST cl_abap_structdescr( lo_descr )` (or `?=`): `CAST` is typed and fails fast.
- **[P2]** Copying: `dobj2 = dobj1` copies tables/structures entirely; references — `REF #`/`CREATE DATA ... LIKE`; do not confuse a data reference with a copy.
