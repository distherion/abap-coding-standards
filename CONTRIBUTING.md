# Contributing

Thanks for considering a contribution to **abap-coding-standards**.

## How to report a problem

- Open a [GitHub issue](https://github.com/distherion/abap-coding-standards/issues)
  for bugs, rule gaps, and feature suggestions.
- For rule content: name the topic (`reference/*.md` file), quote the rule in question,
  and explain the expected behavior with a short example if possible.

## Repository layout

```
.
├── README.md                # documentation (English)
├── README.ru.md             # documentation (Russian)
├── LICENSE                  # MIT
└── abap-coding-standards/   # the skill itself
    ├── SKILL.md             # entry point, review workflow, reference map
    └── reference/*.md       # topic files, loaded on demand
```

`SKILL.md` is the entry point the agent reads first. Rules live in `reference/*.md`
and are loaded per topic — do not dump new rules into `SKILL.md`.

## Guidelines

- **Keep the skill in English.** Russian is fine only for `README.ru.md`.
- **No hyperlinks inside the skill.** Name tools/standards in plain text
  (`abaplint`, `dotabap.org`); link them in `README.md` instead.
- **Follow the marker convention:** every review rule is tagged `[P0]`–`[P3]`;
  `[info]` for facts, `[behavior]` for agent instructions.
- **One topic, one reference file.** If a rule fits an existing topic, add it there;
  create a new `reference/*.md` only when the topic genuinely does not exist.
- **Update the "Reference map" in `SKILL.md`** when you add or rename a topic file.
- **Update both READMEs** (`README.md` and `README.ru.md`) when behavior changes.

## Pull request process

1. Fork the repository and create a branch from `main`.
2. Make a focused change (small, single-purpose PRs are easier to review).
3. Run a final check that the reference map still matches the files.
4. Open the PR with a short description; mention which rule/behavior changed.

Everything is Markdown — no build step, no dependencies.