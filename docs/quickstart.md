# Quickstart

This page goes through a first run, from an empty folder to the collected answers. Only one step costs money, and it is marked.

## 1. A key, in a file

Make a key in your provider's console. For Anthropic, create a **workspace** for the project first and
give it a monthly spend limit, then create the key inside that workspace. The provider enforces that limit whatever any program does.

Save the key where only you can read it. Type it at a hidden prompt rather than pasting it into a
command, so it never lands in your shell history:

```sh
mkdir -p ~/.config/api-batch/keys
(umask 077; read -rs -p "API key: " k && printf '%s' "$k" > ~/.config/api-batch/keys/research.key; unset k); echo
```

If you keep keys somewhere else: `api-batch config set key_dir ~/that/dir`.

## 2. A project

```sh
api-batch init thesis --keyname research --budget 20 --target 10
```

This registers `thesis`, creates `~/api-batch-projects/thesis/` with `input/`, `questions.txt` and
`runs/`, and checks that `~/.config/api-batch/keys/research.key` exists. `--budget` is the ceiling
`submit` will refuse to pass; `--target` is where it starts warning.

## 3. The document and the questions

```sh
api-batch add thesis ~/Documents/background.docx
api-batch ask thesis -f questions.txt
api-batch questions thesis
```

`add` converts a `.docx` to Markdown with pandoc and pulls its pictures out as PNG files next to it.
Markdown, PDF and images are copied as they are. Everything in `input/` is sent with every question
(and cached by the provider, so you pay the reduced cache rate after the first request). Delete
anything in `input/` you don't need; images in particular cost tokens on every question.

`questions.txt` has one question per line; lines starting with `#` are ignored. If the document itself
is the prompt, one question is enough: "Follow the instructions in the document."

## 4. Estimate (free)

```sh
api-batch estimate thesis --model opus --effort medium
```

```
thesis: 12 questions | input 48,120 tok | model claude-opus-5-5 effort medium max_tokens 16000
worst case $2.02 | spent $0.00 | target $10 | budget $20
```

Worst case means that every answer uses all of `max_tokens` and nothing is cached. A real run costs well below it. The same flags apply to `submit`, so try a few settings here.

## 5. Submit (bills)

```sh
api-batch submit thesis --model opus --effort medium
```

It repeats the estimate, refuses if `spent + worst case` passes the budget, then submits and prints the
batch id. If an agent is running these steps for you, this is the one step that a person should run.

## 6. Wait, collect, read

```sh
api-batch ls                 # * = running, ! = ended, waiting for collect
api-batch collect thesis     # answers, usage.csv, ledger line
api-batch show thesis        # all answers of the latest run
api-batch show thesis q03    # one of them
```

Answers are in `runs/<timestamp>/qNN.md`, headed by the question. `usage.csv` has the token counts and
the estimated cost per question; `runs/ledger.csv` has one line per batch.

## Another provider: DeepInfra

The steps are the same with one flag at `init`. Save the key as `deepinfra.key` in the key folder, then:

```sh
api-batch init notes --provider deepinfra --budget 5
api-batch estimate notes                  # default model: flash (DeepSeek V4.1 Flash); --model dspro for V4 Pro
```

`api-batch models --provider deepinfra --grep deepseek` lists the models you can pass to `--model`, with
their prices. The estimate is approximate there (characters / 3) and the batch discount is 20 percent. Input is text
only, and `--effort` and `--web` do not apply.

## 7. A second round

```sh
api-batch synth thesis "Combine the answers into a two-page summary with the open questions last."
```

`synth` sends one request that contains every collected answer plus your prompt, as another
(one-request) batch. Collect it the same way.
