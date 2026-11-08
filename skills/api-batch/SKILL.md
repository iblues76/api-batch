---
name: api-batch
description: Use when a user wants to run many independent LLM questions cheaply through a batch API, measure what a batch job costs, or drive the api-batch CLI (init/add/ask/estimate/submit/collect/show/synth/ls, -H remote). Covers what is free vs billed, the budget guard, and the rule that a human presses submit.
---

# api-batch — batch LLM jobs with a budget and a ledger

One Python file; `api-batch -h` lists everything. Docs: https://api-batch.software.nuilab.org.
Source: https://github.com/iblues76/api-batch. Provider today: Anthropic Message Batches (50% off).

## What an agent may do freely (nothing billed)

```
api-batch init <proj> --keyname <key> [--dir D] [--budget 50 --target 30]
api-batch add  <proj> doc.docx|doc.md|img.png        # docx → md + images via pandoc
api-batch ask  <proj> "question" … | -f file.txt
api-batch estimate <proj> [--model opus|sonnet|haiku|fable --effort medium --max-tokens 16000 --web N]
api-batch status | collect | show <proj> [qNN] | ls [--all]
```
`estimate` uses the free token-count endpoint and prints the worst case against the budget. Run it,
show the user the number, **stop**.

`api-cost [--compare] <files>` answers "what would this prompt cost" for anything outside a project
(exact input tokens, output as a ceiling) — also free. Prefer it over asking a model to guess.

## What needs the user's explicit go, each time

`api-batch submit …` (with or without `--now`) and `api-batch synth …` spend money. Only an explicit "submit" / "go" / "run it"
for that run counts; a sentence that restates or describes the submit command is not approval. A
rerun with other flags or the synthesis step is a new approval. (Real incident: an agent read "ok
submit is the same but with api-batch submit …" as a go; the user submitted six seconds later, and
two identical paid batches ran.)

## Key hygiene

- The key lives in `<key_dir>/<keyname>.key`, mode 600 (default `~/.config/api-batch/keys/`). Refer
  to it by **path**; never print, `cat`, echo, or put it on a command line. `init` says whether the
  file exists; that is all you need.
- Never ask the user to paste the key into chat. Have them save it with a hidden prompt:
  `(umask 077; read -rs -p "API key: " k && printf '%s' "$k" > <key_dir>/<name>.key; unset k)`.
- `deploy` copies the script and settings to other machines but not the keys; each machine needs its
  own copy, piped over SSH stdin.

## Shapes that work

- **One document, one instruction**: `add` the document, `ask "Follow the instructions in the
  document."` A one-request batch still gets the discount.
- **Fan-out then synthesis**: many independent questions, `collect`, then `synth "<combine prompt>"`.
  There is no tool loop inside a batch; iteration happens in rounds.
- **Batch vs standard**: `submit --now` runs the same questions through the normal endpoint at once,
  at 2× the price, with `kind: now` in the ledger — the direct measurement of what the discount buys.
- **Measuring**: run the same questions at two settings (`--model`, `--effort`) as separate batches;
  each lands in its own `runs/<ts>/` with its cost in `runs/ledger.csv`. Compare `usage.csv` side by
  side. Treat one run as one sample.
- `--web N` enables web search; the estimate cannot see search results, so pilot 2–3 questions first.

## Reading results

`runs/<ts>/qNN.md` (answer headed by its question), `runs/<ts>/usage.csv` (tokens and estimated cost
per request), `runs/ledger.csv` (one line per batch). `api-batch show <proj>` prints the latest run.
`ls` marks `*` running, `!` ended and not collected. `--run <ts-prefix>` addresses an earlier run.

## Gotchas

- Costs are list-price estimates; the provider console is ground truth. A cancelled batch may still
  bill requests that had started.
- `collect` refuses to run twice on the same run; use `--run` to collect an older one.
- Submitted something by mistake? `api-batch cancel <proj>` right away (free). Started requests may
  still bill; `--run <ts> collect` after it ends records whatever ran.
- A `.docx` with pictures pandoc cannot extract reports fewer `+N images` than expected; add those
  as PNG by hand.
- Paths in `config set` are stored with `~` so they carry across machines with different home dirs.
