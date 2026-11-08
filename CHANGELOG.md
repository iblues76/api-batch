# Changelog

What changed in each release, newest first. Every release is a git tag (`v0.1.0`) and a tarball on
the [download page](https://api-batch.software.nuilab.org/download/).

## 0.2.0 — 2026-11-08

- **`submit --now`** (and `synth --now`, `estimate --now`): run through the standard endpoint
  immediately at the normal price instead of the batch queue. Same budget guard, same `usage.csv`,
  same ledger (`kind: now`), so batch and standard runs of the same questions sit side by side.
- **`api-cost`**, a second command: exact input tokens and the price for any prompt or set of files,
  standard or batch, from the free token counter. Never sends a real request.
- `install.sh` installs both commands.

## 0.1.1 — 2026-11-08

- Adds `install.sh`, which the 0.1.0 tarball was missing.

## 0.1.0 — 2026-11-08

First release.

- Projects by name: `init`, `add` (docx → markdown + images), `ask`, `questions`.
- `estimate` is free and prints the worst-case cost against the project budget; `submit` refuses to
  pass the budget and warns past the target.
- `collect` writes one Markdown answer per question, a `usage.csv` with tokens and estimated cost, and
  appends a line to the project ledger. `show` prints the latest run.
- `synth` runs a second round over the collected answers.
- `ls` for every project on this machine, `ls --all` across hosts, `-H <host>` to run a command on
  another machine, `deploy` to install there.
- `--dir` / `--pwd` select a project by folder, `--run` an earlier batch.
- Provider: Anthropic Message Batches (Claude). Model aliases `opus`, `sonnet`, `haiku`, `fable`.
