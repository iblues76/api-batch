# api-batch

api-batch sends a list of independent questions to a model's batch API, where tokens cost less than the normal price (half at Anthropic, 20 percent less at DeepInfra). It brings back the answers and records what each one cost.

You give it a document and the questions. Before anything is billed, it shows the most the run can cost, and it refuses to submit a run that would go over the budget you set. It keeps a cost ledger for each project. Projects have names, so you do not type their paths again, and the same commands work on another machine over SSH.

**Version 0.4.0.** api-batch is two Python files: `api-batch` itself, and `api-cost`, which estimates what a prompt would cost and is free to run. It needs nothing besides the provider's SDK, and it creates its own virtual environment the first time it runs. It works with two providers: Anthropic (Claude), which is the default, and DeepInfra (DeepSeek and the other models in its catalog). Each provider is a small class in the code, so another can be added. It runs on macOS and Linux with Python 3.10 or later.

## Install

```sh
git clone https://github.com/iblues76/api-batch.git
cd api-batch && ./install.sh      # copies api-batch into ~/.local/bin
api-batch -h
```

Put your API key in a file only you can read. The default place is `~/.config/api-batch/keys/<name>.key`:

```sh
mkdir -p ~/.config/api-batch/keys
(umask 077; read -rs -p "API key: " k && printf '%s' "$k" > ~/.config/api-batch/keys/research.key; unset k); echo
```

The key is never printed. `api-batch` stores the name of the key file and reads the file when it runs.

`pandoc` is optional. `add` uses it to convert `.docx` documents.

## Quick start

```sh
api-batch init     thesis --keyname research            # project folder, key file, budget ($50 default)
api-batch add      thesis background.docx                # docx -> markdown + images (or .md .pdf .png)
api-batch ask      thesis "What are the open problems in X?" "Which datasets are standard for Y?"
api-batch estimate thesis                                # FREE: token count and worst-case cost
api-batch submit   thesis --model opus --effort medium   # bills; refuses past the budget
api-batch ls                                             # every project: state, spent/budget
api-batch collect  thesis                                # answers + usage.csv + ledger line
api-batch show     thesis                                # read the latest run's answers
api-batch synth    thesis "Combine the answers into a two-page summary"
```

If you need the answers in minutes and not hours, use `submit --now`. It runs the same questions through the standard endpoint at the normal price (2× the batch rate), with the same budget check and the same ledger. To compare batch with standard, run both and read the two lines in `runs/ledger.csv`.

A batch usually finishes within an hour (the provider allows up to 24). `ls` marks a project `*`
while its batch runs and `!` when it has ended and is waiting for `collect`.

## Commands

| Command | Billed? | What it does |
| --- | --- | --- |
| `init <proj> --keyname <k> [--provider claude\|deepinfra] [--dir D] [--budget 50] [--target 30]` | no | register a project |
| `add <proj> <file>…` | no | put a document in `input/` (docx converted via pandoc) |
| `ask <proj> "q" … \| -f file` | no | append questions |
| `questions <proj>` | no | list them |
| `estimate <proj> [opts]` | no | count tokens, print the worst-case cost against the budget |
| `submit <proj> [opts]` | **yes** | run `estimate`, then submit the batch if it fits the budget |
| `submit <proj> --now [opts]` | **yes** | same, but through the standard endpoint right now, at full price |
| `status <proj>` | no | state of the latest batch |
| `cancel <proj>` | no | cancel the latest batch while it is still processing (started requests may still bill) |
| `collect <proj>` | no | fetch answers, write `usage.csv`, append the ledger |
| `show <proj> [qNN]` | no | print the latest run's answers (or one) |
| `synth <proj> "prompt" [opts]` | **yes** | one request fed every collected answer |
| `ls [--all]` | no | projects here (and on every host in `host ls`) |
| `models [--provider P] [--grep TEXT] [--all]` | no | the models each provider offers, with prices, batch prices and aliases |
| `host add\|rm\|ls <alias>` | no | machines for `ls --all` |
| `deploy <alias>…` | no | copy this script and its settings to other machines |
| `config [show \| set k v]` | no | `key_dir`, `install_path`, `notify.url`, `notify.token_file` |

Options for `estimate` / `submit` / `synth`: `--model opus|sonnet|haiku|fable|fable51` (`fable` is always the newest Fable, now 5.2; or a full model id),
`--effort low|medium|high|xhigh|max`, `--max-tokens N` (default 16000), `--web N` (web search, at most
N searches per question; off by default), `--now` (standard tier instead of batch).

## DeepInfra: DeepSeek and other models

A project belongs to one provider, chosen at `init`. With `--provider deepinfra` the same commands run
through DeepInfra's OpenAI-compatible Batch API, where a batch costs 20 percent less than the normal
price.

```sh
mkdir -p ~/.config/api-batch/keys
(umask 077; read -rs -p "DeepInfra key: " k && printf '%s' "$k" > ~/.config/api-batch/keys/deepinfra.key; unset k); echo
api-batch init     notes --provider deepinfra --budget 5     # the key file is deepinfra.key; no --keyname needed
api-batch add      notes background.md
api-batch ask      notes "Summarize the open problems."
api-batch estimate notes                                     # default model: flash
api-batch estimate notes --model dspro --max-tokens 4000
```

- `--model flash` is `deepseek-ai/DeepSeek-V4.1-Flash-1017` (the default), `--model dspro` is
  `deepseek-ai/DeepSeek-V4-Pro-0813`. Any full model id from the DeepInfra catalog works too; a batch
  uses one model.
- `api-batch models --provider deepinfra --grep deepseek` lists what is on offer, with the price of each.
- Prices are read from DeepInfra's public model list when you run `estimate` or `submit`. A model
  with no token price there is refused, so the budget guard never works from a guess.
- **The estimate is approximate.** DeepInfra has no token-counting endpoint, so the input is counted
  as characters divided by 3, and the output says so. `estimate` needs no key; `submit`, `status`,
  `collect` and `cancel` do.
- Text only: `.md` and `.txt` in `input/`. `--effort` is ignored and `--web` is refused.
- `api-cost --model flash notes.md` gives the same approximate figure for any text file.

## api-cost: the cost of a prompt before you send it

`api-cost` estimates the cost of a prompt that you plan to send another way, for example from a script, a notebook or another tool:

```sh
api-cost --keyname research prompt.md doc.pdf shot.png     # exact input tokens, per file, and the price
api-cost --keyname research --compare prompt.md           # standard vs batch side by side
echo "some text" | api-cost --keyname research -           # from stdin
```

It uses the provider's free token counter and never sends a real request. The input count is exact. The output is shown as the ceiling set by `--max-tokens`, because the length of the answer is not known in advance. Set `API_COST_KEY=research` to skip `--keyname`.

Global options, before the command: `--dir PATH` or `--pwd` selects the project by folder instead of
name; `--run <timestamp-prefix>` addresses an earlier run; `-H <host>` runs the command on another
machine.

## Where things live

```
~/.config/api-batch/config.json      projects, budgets, hosts, settings (key PATHS only)
~/.config/api-batch/keys/<name>.key  API keys, mode 600 (change with: config set key_dir …)
~/api-batch-projects/<proj>/         default project folder
    input/                           the document(s) sent with every question, cached
    questions.txt                    one question per line, '#' comments
    runs/<timestamp>/qNN.md          one answer per question
    runs/<timestamp>/usage.csv       tokens and estimated cost per question
    runs/ledger.csv                  one line per batch: date, id, model, requests, cost, minutes
```

## Cost

Costs are estimates. They use the provider's list prices with the batch discount applied (50 percent at Anthropic, 20 percent at DeepInfra). The amounts in the provider's own console are the real ones. `estimate` assumes that every answer uses all of `max_tokens` and that nothing is cached, so the real cost is usually well below it. With `--web`, the search results are extra input tokens that the estimate cannot see, so try two or three questions first.

See also the [quickstart](docs/quickstart.md), the [commands](docs/commands.md), [budget and ledger](docs/budget.md), [other machines](docs/remote.md), [keeping the key safe](docs/secrets.md), and the [changelog](CHANGELOG.md).

## License

BSD 2-Clause. Copyright (c) 2026 Francisco R. Ortega. See [LICENSE](LICENSE).
