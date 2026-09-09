# abap-coding-standards

**Стандарты написания кода ABAP 7.50 — навык для написания и проверки классических программ ABAP с помощью AI-агентов.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/distherion/abap-coding-standards)](https://github.com/distherion/abap-coding-standards/releases)

[Русский](README.ru.md) | [English](README.md)

Список правил для написания и проверки **классического ABAP 7.50 (NetWeaver)** с помощью
AI-агентов: стандарты написания кода, Open SQL, LUW/транзакции, обработка ошибок,
безопасность, типы данных, классы, тестирование, параллелизм, CDS/AMDP, OData,
файловый ввод/вывод и интеграция.

> **Цель:** классический ABAP 7.50 (NetWeaver). **Не** ABAP Cloud / S/4HANA RAP.

## Зачем этот навык

- **Clean ABAP + практический опыт.** Правила из SAP styleguides и проверенной
  документации SAP, с реальными ошибками из практики и неочевидными деталями API.
- **Проверка по серьёзности.** Каждое правило помечено `[P0]`–`[P3]`, поэтому агент
  выдаёт замечания в порядке важности (сначала серьёзные, потом мелочи).
- **Загрузка по требованию.** Правила разбиты по темам в `reference/*.md`; агент
  открывает только файл нужной темы, а не весь список правил целиком.
- **Независимость от инструмента.** Чистый Markdown — работает в Claude Code, OpenCode,
  Codex, Cursor и любом LLM через system prompt.

## Как работает

Правила используют явные маркеры:

| Маркер      | Значение |
|-------------|----------|
| `[P0]`–`[P3]` | Серьёзность замечания при проверке (P0 = блокер … P3 = стиль) |
| `[info]`  | Факт/справка (синтаксис, платформа, лимиты имён); не замечание |
| `[behavior]` | Инструкция агенту (как искать, когда спрашивать); не замечание |

Замечания проверки выводятся в порядке P0 → P3:

- **P0 — Blocker:** дамп, порча данных, инъекция / обход авторизации. Не принимать.
- **P1 — Critical:** неверный результат (гонки, потерянные/испорченные деньги, неверная запись, необработанная ошибка).
- **P2 — Substantial:** медленно (`SELECT` в цикле, O(n²)), хрупко, тяжело тестировать.
- **P3 — Minor:** стиль (имена, регистр, форматирование, читаемость).

## Установка

Навык — чистый Markdown (`SKILL.md` + `reference/`), стандартная структура навыков для агентов.
Скопируй папку `abap-coding-standards/` в каталог навыков своего инструмента или подключи по инструкции:

### Claude Code

```bash
cp -r abap-coding-standards ~/.claude/skills/     # глобально
cp -r abap-coding-standards .claude/skills/      # на уровне проекта
```

### OpenCode

```bash
cp -r abap-coding-standards ~/.config/opencode/skills/     # глобально
cp -r abap-coding-standards .opencode/skills/              # на уровне проекта
```

Или подключи папку без копирования, через `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "skills": { "paths": ["path/to/abap-coding-standards/abap-coding-standards"] }
}
```

### Codex

В новых версиях Codex навыки подхватываются из `.codex/skills/` (или через `AGENTS.md`); если загрузчика навыков нет — вставь правила в `AGENTS.md` или в свой prompt/agent.

### Cursor

Положи правила в `.cursor/rules/*.mdc` (project или global rules).

### Любой LLM

Вставь нужный `reference/*.md` в system prompt.

> Храни `abap-coding-standards/SKILL.md` и `abap-coding-standards/reference/` вместе.

## Структура репозитория

```
abap-coding-standards/
├── README.md            # документация (англ.)
├── README.ru.md         # документация (рус.)
├── LICENSE              # MIT
└── abap-coding-standards/             # сам навык — на английском
    ├── SKILL.md         # точка входа и процесс проверки
    └── reference/       # файлы по темам, лениво подгружаются
        ├── errors.md        # обработка ошибок, исключения, LUW/ENQUEUE/COMMIT, update task
        ├── logging.md       # логирование (cl_reca_message_list, Application Log)
        ├── data.md          # типы и DDIC, числа, дата/время, таблицы, строки
        ├── open-sql.md      # Open SQL, производительность, buffer, client, JOIN
        ├── ldb.md           # логические БД (LDB-PNP/PNPCE), чтение инфотипов HR
        ├── security.md      # безопасность, динамический SQL, авторизация, инфотипы HR
        ├── hr.md            # HR PA/OM/PD, расчёт зарплаты, фреймворк cl_hrpa_*/cl_hrbas_*
        ├── classes.md       # классы, сигнатуры, тело метода, DI
        ├── testing.md       # ABAP Unit: принципы, тест-классы, двойники, assertion
        ├── parallel.md      # параллелизм, bgRFC/aRFC, фоновые задания
        ├── cds-amdp.md      # CDS Views, AMDP (SQLScript)
        ├── dynamic-rtti.md  # динамическое программирование, RTTI/RTTS
        ├── style.md         # язык и стиль, имена, булевы, форматирование
        ├── odata.md         # OData (SEGW / Gateway)
        ├── odata-v4.md      # особенности OData v4 (SEGW V4)
        ├── files-io.md      # файловый I/O (DATASET, gui_upload/download, кодировки, JSON/XML)
        ├── integration.md   # batch input (BDC), память, BAdI, RFC/HTTP
        ├── ddic.md          # словарь данных: ключи таблиц, буферизация, append-структуры, домены/DE
        ├── alv.md           # вывод через ALV (SAP List Viewer), классические списки
        └── dynpro.md        # классические экраны Dynpro: PBO/PAI, CHAIN/FIELD, LOOP AT SCREEN
```

## Источники

Правила собраны из источников ниже. Ссылки есть только здесь — в самом навыке (`SKILL.md`/`reference/`) их намеренно нет (см. `CONTRIBUTING.md`).

**Официальные источники SAP**

- [Clean ABAP — SAP styleguides](https://github.com/SAP/styleguides/blob/main/clean-abap/CleanABAP.md) · [ABAP Code Reviews — SAP styleguides](https://github.com/SAP/styleguides/blob/main/abap-code-review/ABAPCodeReview.md)
- [SAP Help Portal](https://help.sap.com) · [Документация ABAP Keyword 7.50 (ABAPDocu)](https://help.sap.com/doc/abapdocu_750_index_htm/7.50/en-US/index.htm) · [SAP Support Notes / База знаний](https://support.sap.com/en/my-support/knowledge-base.html)

**Статический анализ и инструменты**

- [SAP/code-pal-for-abap](https://github.com/SAP/code-pal-for-abap) — проверки Clean ABAP в SCI/ATC
- [SAP/abap-cleaner](https://github.com/SAP/abap-cleaner) — правила очистки в ADT (100+ проверок); источник правил цепочек, устаревших операторов и форматирования в `style.md`/`data.md`/`classes.md`
- [larshp/abapOpenChecks](https://github.com/larshp/abapOpenChecks) — открытые проверки SCI/ATC (7.40 SP02+)
- [abaplint/abaplint](https://github.com/abaplint/abaplint) · [rules.abaplint.org](https://rules.abaplint.org) — линтер для репозиториев abapGit
- [abapGit/abapGit](https://github.com/abapGit/abapGit) — Git-клиент для ABAP; основа правил локального редактирования (SKILL.md) и abapGit-сериализации, которую читают abaplint/SonarQube в CI

**Обучающие материалы**

- [SAP-samples/abap-oo-basics](https://github.com/SAP-samples/abap-oo-basics) — основы ООП
- [SAP-samples/abap-cheat-sheets](https://github.com/SAP-samples/abap-cheat-sheets) — синтаксис ABAP кратко, с исполняемыми демо-примерами
- [SchwarzIT/abap_oo_patterns](https://github.com/SchwarzIT/abap_oo_patterns) — паттерны проектирования ООП
- [ilyakaznacheev/abap-best-practice](https://github.com/ilyakaznacheev/abap-best-practice) — список общих принципов чистого ABAP
- [dotabap.org](https://dotabap.org) — каталог open-source проектов ABAP

## Вклад

Вклад приветствуется — как сообщать о проблемах и открывать PR, см. [CONTRIBUTING.md](CONTRIBUTING.md).

## Лицензия

[MIT](LICENSE)