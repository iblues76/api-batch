# api-batch

Send a list of independent questions to a model's **batch API**, where every token costs half the
normal price, and get the answers back with the cost of each one written down.

You give it a document and the questions. It tells you the worst case the run can cost, refuses to go
over the budget you set, and keeps a ledger per project. Projects have names, so you never type paths
twice, and the same commands work on another machine over SSH.

**Version 0.2.2.** Two Python files (`api-batch` and the free estimator `api-cost`), no dependencies beyond the provider SDK (it creates its own
virtual environment on first run). The only provider today is Anthropic (Claude); the provider sits
behind a small class so another can be added. Works on macOS and Linux with Python 3.10+.

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

Nothing ever prints the key: `api-batch` stores the file's *name* and reads the file when it runs.

Optional: `pandoc`, for `add` to convert `.docx` documents.

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

Need the answers in minutes rather than hours? `submit --now` runs the same questions through the
standard endpoint at the normal price (2× the batch rate), with the same budget check and the same
ledger, so a batch-versus-standard comparison is just two lines in `runs/ledger.csv`.

A batch usually finishes within an hour (the provider allows up to 24). `ls` marks a project `*`
while its batch runs and `!` when it has ended and is waiting for `collect`.

## Commands

| Command | Billed? | What it does |
| --- | --- | --- |
| `init <proj> --keyname <k> [--dir D] [--budget 50] [--target 30]` | no | register a project |
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
| `host add\|rm\|ls <alias>` | no | machines for `ls --all` |
| `deploy <alias>…` | no | copy this script and its settings to other machines |
| `config [show \| set k v]` | no | `key_dir`, `install_path`, `notify.url`, `notify.token_file` |

Options for `estimate` / `submit` / `synth`: `--model opus|sonnet|haiku|fable|fable51` (`fable` is always the newest Fable, now 5.2; or a full model id),
`--effort low|medium|high|xhigh|max`, `--max-tokens N` (default 16000), `--web N` (web search, at most
N searches per question; off by default), `--now` (standard tier instead of batch).

## api-cost: what would this prompt cost?

For anything you are about to send through some other path (a script, a notebook, another tool):

```sh
api-cost --keyname research prompt.md doc.pdf shot.png     # exact input tokens, per file, and the price
api-cost --keyname research --compare prompt.md           # standard vs batch side by side
echo "some text" | api-cost --keyname research -           # from stdin
```

It uses the provider's free token counter and never sends a real request. Input is exact; output is
shown as the ceiling set by `--max-tokens`, because nobody knows the answer's length in advance.
Set `API_COST_KEY=research` to skip `--keyname`.

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

Costs are estimates from the provider's list prices with the batch discount applied; the provider's
own console is the number that counts. `estimate` assumes every answer uses all of `max_tokens` and
nothing is cached, so the real cost is usually well below it. With `--web`, the search results are
extra input tokens the estimate cannot see: pilot two or three questions first.

Docs: [quickstart](docs/quickstart.md) · [commands](docs/commands.md) · [budget and ledger](docs/budget.md) ·
[remote](docs/remote.md) · [secrets](docs/secrets.md) · [changelog](CHANGELOG.md).

## License

BSD 2-Clause. Copyright (c) 2026 Francisco R. Ortega. See [LICENSE](LICENSE).
