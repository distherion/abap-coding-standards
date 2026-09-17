# Money and numbers — arithmetic

> Amounts, exact arithmetic, rounding, overflow, number ranges. Read before writing any calculation on money, quantities or counters.
> Related: `datetime.md` (dates and time), `data.md` (types, variables, references), `strings.md` (text).

## Money and amounts

- **[P1]** Money and exact amounts — only `p` (or DDIC `CURR`/`QUAN`), never `f` (binary float): `0.815` in `f` is stored as `8.1499…E-01` and rounds to `0.81`. Never compare floats for equality. <!-- rule: money-p-not-float -->

- **[P1]** `CURR`/`QUAN` copied between fields of different length/decimals loses value silently — no error, no dump: `p LENGTH 8 DECIMALS 2` into `p LENGTH 6 DECIMALS 0` drops the fraction. Align the types, or convert explicitly — `EXACT` raises `CX_SY_CONVERSION_ROUNDING`/`CX_SY_CONVERSION_OVERFLOW` instead of truncating quietly (see the `EXACT` rule below). <!-- rule: curr-quan-silent-loss -->

- **[P3]** Conversions — explicit: `CONV #( )`/`CONV type( )` or string templates `|{ lv_num }|`; do not rely on implicit ones — `i` from `p` rounds commercially (e.g. `1.6 → 2`), overflow raises `CX_SY_CONVERSION_OVERFLOW`. An explicit conversion gives a catchable exception where the implicit one does not always.

- **[P2]** A `CURR`/`QUAN` field must have a reference field — a `CUKY`/`UNIT` column in the same table/structure.

- **[P3]** Amount in words (printed forms) — use the standard FM `SPELL_AMOUNT`; do not write your own converter (language, currency and the legal form of the text are not yours to reproduce).

- **[P1]** Generating document/record numbers — via number range (`NUMBER_GET_NEXT`), not by hand (`MAX + 1` — a race under parallelism). Gaps in numbers are normal: do not require continuity, do not "fix" holes; the buffered number comes from the range. <!-- rule: number-range-not-max-plus-one -->


## Arithmetic and rounding

- **[P1]** Integer division `/` rounds commercially (round half up): `4 / 5 = 1`, `2 / 3 = 1`, `5 / 2 = 3`. The integer part without rounding comes from `DIV`: `4 DIV 5 = 0`, `7 DIV 3 = 2`. Do not confuse them — it gives a wrong result. A percent/ratio must multiply **before** dividing, or the fraction is lost first: `lv_pct = lv_sum * 100 / lv_salary.` is right, `lv_pct = lv_sum / lv_salary * 100.` is wrong for `sum < salary` (the integer `/` truncates to 0). <!-- rule: div-rounds-half-up -->

- **[P1]** `DIV`/`MOD` — non-negative remainder: `-7 DIV 3 = -3`, `-7 MOD 3 = 2` (invariant `n = (n DIV d)*d + (n MOD d)`; the remainder is **always** non-negative and < |divisor| — `7 MOD -3 = 1`, `-7 MOD -3 = 2`). <!-- rule: div-mod-nonneg-remainder -->

- **[P1]** Division by zero: `x / 0` (x≠0), `x DIV 0`, `x MOD 0` → `CX_SY_ZERODIVIDE`; a zero dividend (`0 / 0`, `0 DIV 0`, `0 MOD 0`) — no exception, result is 0. <!-- rule: division-by-zero -->

- **[P1]** `**` returns `f` (binary float, precision loss) when no operand is a decimal floating point type; if an operand is `decfloat16/34` — calc type is `decfloat34`. For an integer power use `ipow( base = ... exp = ... )`. <!-- rule: power-returns-float -->

- **[P1]** Integer overflow (`2147483647 + 1`) → `CX_SY_ARITHMETIC_OVERFLOW` (catchable) — do not rely on wrapping: widen the type (`i` → `int8`/`decfloat34`) or guard the range before the operation. <!-- rule: integer-overflow -->

- **[P1]** Inline `DATA(x) = lv_packed + 1` with a `p` operand gives `p LENGTH 8 DECIMALS 0` — the fraction is lost. For fractions declare the type explicitly: `DATA(x) TYPE p LENGTH 8 DECIMALS 2`. <!-- rule: inline-packed-loses-fraction -->

- **[P1]** `EXACT` on digit loss: `CX_SY_CONVERSION_ROUNDING` (fraction/digits lost), `CX_SY_CONVERSION_OVERFLOW` (overflow) — catch it or guarantee the range. <!-- rule: exact-digit-loss -->

- **[info]** `cl_abap_math` — numeric limits (`min_*`/`max_*` per type, e.g. `cl_abap_math=>min_int4`, `=>max_decfloat34`); the mathematical constants `pi`/`e` are **not** in the 7.50 class — use `acos( -1 )`. Rounding/min/max functions — see `booleans.md`.

- **[P3]** No `ADD`/`SUBTRACT`/`MULTIPLY`/`DIVIDE` — write an arithmetic assignment `lv_x = lv_x + lv_n`; computed assignments `+=`/`-=`/`*=`/`/=` — only from 7.54 (see `style.md`).
