# Commands

`api-batch -h` prints the same list. Commands marked **bills** spend money at the provider; everything
else is free (token counting is a free endpoint).

## Global options

These go **before** the command, like `ssh -p`:

| Option | Meaning |
| --- | --- |
| `-H <host>` | run the whole command on `<host>` over SSH (see [remote](remote.md)) |
| `--dir <path>` | select the project registered at that folder; the name becomes optional |
| `--pwd` | same, for the current folder |
| `--run <prefix>` | address the run whose timestamp starts with `<prefix>` instead of the latest |

## Project setup

**`init <proj> --keyname <name> [--dir D] [--provider claude] [--budget 50] [--target 30]`**
Register a project. `--dir` defaults to `~/api-batch-projects/<proj>`. `--keyname` is the key file's
name without `.key` (or a full path). Budget and target are US dollars, summed over every batch the
project ever ran.

**`add <proj> <file>…`**
Copy documents into `input/`. `.docx` is converted with pandoc to Markdown plus extracted images;
`.md`, `.txt`, `.pdf`, `.png`, `.jpg`, `.gif`, `.webp` are copied. The last file in `input/` gets the
cache marker, so the whole shared block is cached.

**`ask <proj> "question" … `** or **`ask <proj> -f file.txt`**
Append questions to `questions.txt`. **`questions <proj>`** lists them with their ids (`q01`, `q02`, …).

## Running

**`estimate <proj> [run options]`**
Count the input tokens of every request (free), print the worst case for this run, what the project has
spent so far, and the target and budget. Exit code 1 if the run would pass the budget.

**`submit <proj> [run options]`** — **bills**
Everything `estimate` does, then create the batch. Refuses past the budget, warns past the target.
Writes `runs/<timestamp>/batch.json` with the batch id and the questions.

**`synth <proj> "prompt" [run options]`** — **bills**
A one-request batch whose input is every `q*.md` of the latest run plus your prompt. Lands in its own
`runs/<timestamp>/` with `kind: synth`.

Run options:

| Option | Default | Notes |
| --- | --- | --- |
| `--model` | `opus` | `opus`, `sonnet`, `haiku`, `fable`, or a full model id |
| `--effort` | `medium` | `low` `medium` `high` `xhigh` `max` — mostly moves output (thinking) tokens |
| `--max-tokens` | `16000` | per-answer ceiling; also the worst-case assumption |
| `--web` | `0` | allow up to N web searches per question (server-side tool); results add input tokens the estimate cannot see |

## Results

**`status <proj>`** — state of the latest batch: `in_progress` / `ended`, counts, minutes since submit.

**`collect <proj>`** — once ended: write `qNN.md` per succeeded request, `usage.csv` (status, stop
reason, tokens in/out/cache, web searches, estimated cost), append one line to `runs/ledger.csv`, and
send a notification if `notify.url` is configured. Lists requests that failed, were refused, or were cut
off at `max_tokens`. Refuses to collect the same run twice.

**`show <proj> [qNN]`** — print the latest run's answers, or one of them. Pipe to `less`.

## Fleet

**`ls [--all]`** — every project on this machine: questions, runs, spent/budget, state of the latest
batch (`*` running, `!` ended and not collected), submit time, folder. `--all` appends the same table
from every host in `host ls`.

**`host add|rm|ls <alias>`** — the SSH aliases `ls --all` and `deploy` use.

**`deploy <alias>…`** — copy this script to `install_path` on each host, carry over `key_dir`,
`install_path` and `notify.*`, and run `ls` there as a smoke test. The key files are **not** copied;
each machine needs its own.

**`config [show | set <key> <value>]`** — `key_dir` (default `~/.config/api-batch/keys`),
`install_path` (default `~/.local/bin/api-batch`), `notify.url` and `notify.token_file` (an
ntfy-style endpoint that gets one line per collected batch). Paths under your home are stored with `~`
so they carry to machines with a different home directory.
