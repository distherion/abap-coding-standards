# Unit testing (ABAP Unit)

> Complement to "Testability and dependency injection" in `classes.md`. There — how to make code testable (DI, interfaces); here — how to write the tests themselves. Rules based on Clean ABAP (SAP styleguides).

## Principles

- **[P2]** Test the public, not the private: a test on the public interface (`zif_*`/public methods) survives refactoring. A need to test `PRIVATE`/`PROTECTED` — a signal: the concept wants to be a separate class with its own interface, or the domain logic is buried in glue code (BOPF action, `*_DPC_EXT`).
- **[P2]** Type the code under test by interface, not class: `DATA cut TYPE REF TO zif_x.`, not `TYPE REF TO zcl_x.` — for integration/service classes that declare an interface (per `classes.md`); a simple `FINAL` value/domain class without an interface is tested directly by its class type.
- **[P3]** Coverage — a tool for finding forgotten tests, not a KPI. A test without an assert for a percentage — worse than no test (masks a non-trivial refactor). < 100% with honest tests is normal.
- **[P3]** Test code is more readable than production: it is documentation. Keep tests simpler than production, follow the same conventions.
- **[P2]** No "manual testing" via `$TMP` copies and test reports checked by eye — automate into a unit test with an assert.

## Test classes

- **[P3]** A local test class in the test-include of the class under test (found on refactor, run in one click). Component-/integration tests — in a separate global class `FOR TESTING ... ABSTRACT` (not a `$TMP` report), so it does not leak into production.
- **[P3]** Name the test class by purpose/setup, not "test": `ltc_<public-method>` or `ltc_<common setup>`. Anti-patterns: `ltc_test`, repeating the name of the class under test.
- **[P3]** Common helper methods (custom asserts, data factories) — in a helper class (`lth_*`), accessed via inheritance or delegation, do not duplicate in each test.
- **[info]** Mandatory additions: `FOR TESTING`, `RISK LEVEL HARMLESS` (or `DANGEROUS` — only if the test actually writes to the DB/external systems, in a unit — almost never), `DURATION SHORT`/`MEDIUM`/`LONG`. Class `ABSTRACT` — so it cannot be instantiated in production.
- **[info]** Run in ADT: `Ctrl+Shift+F10` — all tests of the class, `Ctrl+Shift+F11` — with coverage, `Ctrl+Shift+F9` — preview, `Ctrl+Shift+F12` — with test relations (macOS — `Cmd`).

## Code under test

- **[P3]** Name the tested object's variable meaningfully (`empty_blog_post`, `simple_blog_post`) or `cut` by default — do not repeat the class with prefixes (`clean_fra_blog_post`).
- **[P3]** A method with a pile of parameters/data — wrap the call in a helper method that defaults the uninteresting parameters and call it in one line; do not bury the test in junk `VALUE #( ... )`.

## Injecting test doubles

- **[P2]** Injection — per `classes.md`: dependencies via the constructor; a setter — only for genuinely optional or configured-per-instance dependencies. It must not swap a required dependency halfway or bypass the constructor. (FRIENDS injection into private fields after `NEW` — no, see the `LOCAL FRIENDS` rule.)
- **[P3]** Test doubles — `cl_abap_testdouble=>create( 'zif_x' )` + `configure_call( ... )->returning( ... )`, shorter and clearer than a hand-written stub class.
- **[P2]** `TEST-SEAM`/`TEST-INJECTION` — a temporary workaround for legacy, not a permanent solution (invasive, tangled in private dependencies). New code — no test seam.
- **[P2]** `LOCAL FRIENDS` — only to call the `CREATE PRIVATE` constructor of the tested class with a test double. Do not reach through it into private members for mock data (fragile).
- **[P2]** Do not add "test-only" branches to production code (`IF is_unit_test_running = abap_true.`). Exception — test mode as part of the domain (simulated posting, a report in test mode).
- **[P2]** Do not mock via inheritance and `REDEFINITION` (removes `FINAL`, changes `PRIVATE`→`PROTECTED` — changes the class's behavior in production). For legacy — a test seam; for new code — extract the problematic method into a separate class with an interface.
- **[P3]** Do not mock the unnecessary: data/containers without side effects (`transient_log`) use as-is. Do not build test frameworks with "test case IDs" and `CASE` — define the data in place.

## Test methods

- **[P3]** The name reflects given/expected. The skill's convention — `should_[behavior]_[condition]` (see `classes.md`); Clean ABAP — descriptive (`reads_existing_entry`, `throws_on_invalid_key`, `detects_invalid_input`). Both are fine, the main thing — not `test_...` and not cryptic (`get_attributes_wo_w`). If the name does not fit in 30 chars — explain in the first line of the method.
- **[P3]** The given-when-then pattern (= Arrange-Act-Assert): initialization ("given"), exactly one call to the tested ("when"), the check ("then"). Separate visually (blank lines) or extract into sub-methods.
- **[P2]** "when" — exactly one call. Several calls = unclear focus, cannot find the cause of a failure.
- **[P3]** `TEARDOWN` — only if actually needed (cleaning DB/external resources in an integration test). Resetting `cut`/test doubles is redundant — `setup` will overwrite. Note: `setup` re-creates instance state on every test but does **not** reset class-level (static) data, buffers and global switches — reset those explicitly (`TEARDOWN` or in `setup`) or tests leak state into each other.

## Test data

- **[P3]** Make meaningless data obviously meaningless: `'42'`, `'?=/"&'`, `CONSTANTS some_random_number TYPE i VALUE 782346.` Do not give reason to think `'00000001223678871'` is a real object if it is not.
- **[P3]** Make differences in data immediately noticeable (`END1`/`END2`), do not force finding the difference in long identical strings.
- **[P3]** Constants for "unimportant" values (`CONSTANTS some_nonsense_key TYPE char8 VALUE 'ABCDEFGH'.`) — immediately clear that the value is insignificant.

## Assertions

- **[P3]** A few focused asserts — exactly about the essence of the test. A pile of asserts = unclear focus, extra coupling between test and production.
- **[P3]** The right assert type: `assert_equals`/`assert_false`/`assert_initial`/`assert_not_initial`/`assert_bound`/`assert_subrc`/`assert_table_contains`/`assert_differs`/`fail`. Not `assert_true( xsdbool( act = exp ) )` — `assert_equals` itself gives a description on mismatch.
- **[P3]** Check contents, not count: `assert_equals( act = lines( log ) exp = 3 )` is fragile (the number may vary) and blind (the number matches, the contents differ). Check the rows/records themselves.
- **[P3]** If a property of the result matters, not the exact contents (meta-quality) — a suitable assert, not full equality (exact comparison is fragile under a permitted refactor).
- **[P3]** An expected exception: `TRY ... cl_abap_unit_assert=>fail( ). CATCH zcx_x. ENDTRY.` — fall via `fail` if the exception did not come.
- **[P3]** An unexpected exception — propagate it out (`METHODS m FOR TESTING RAISING zcx_x.`), do not catch and wrap into `fail`: the test stays on the happy path, more readable.
- **[P3]** A duplicated complex assert — extract into a custom helper method (`assert_contains`), do not repeat `TRY/CATCH cx_sy_itab_line_not_found` in each test.
