# Budget, estimate and ledger

Three numbers keep the cost of a project under control: the provider's spend limit, the estimate, and the ledger.

## The provider's spend limit

Set it in the provider's console, on a workspace made for the project. The provider enforces it, and it stops billing whatever any program on your side does. The estimate and the budget only stop a run earlier, before it is submitted.

## The estimate

`estimate` (and the first half of `submit`) sends each request to the provider's free token-counting
endpoint and prints:

```
thesis: 12 questions | input 48,120 tok | model claude-opus-5-5 effort medium max_tokens 16000
worst case $2.02 | spent $0.00 | target $10 | budget $20
```

- **input** is the exact token count of every request as it will be sent: the shared document(s)
  once per question, plus the question.
- **worst case** assumes every answer uses all of `max_tokens`, nothing is read from cache, and (with
  `--web`) every allowed search happens. Prices are the provider's list prices with the batch
  discount. The real bill is usually well below: answers rarely hit the ceiling, and the shared input
  is cached after the first request.
- `submit` refuses when `spent + worst case > budget`, and warns when it passes `target`. Lower
  `--max-tokens`, send fewer questions, or change the budget with a text editor in
  `~/.config/api-batch/config.json`.

On a DeepInfra project there is no token-counting endpoint, so **input** is an approximation
(characters divided by 3, shown with a `~`), the prices come from DeepInfra's public model list, and
the batch discount is 20 percent. A model with no listed token price is refused.

Web search is the one thing the estimate cannot see: each search returns results that count as input
tokens, and their size depends on the pages. Try two or three questions and read the real cost from `collect` before you send many.

## Batch or standard

`--now` runs the same requests through the standard endpoint, right away, at twice the batch price
(at DeepInfra, 1.25 times).
The estimate and the guard use the standard rate when you pass it, and the ledger line says
`kind: now`. To measure what the batch discount saves, run the same set of questions once each way. The ledger then has two lines with the same input, their two costs, and the time each took in the `minutes` column.

## The ledger

`collect` computes the cost of each request that succeeded from the usage the provider reports (input, output, cache reads and cache writes at their own rates, plus any web searches) and writes:

- `runs/<timestamp>/usage.csv`, one line per request;
- `runs/ledger.csv`, one line per batch: `date, batch_id, kind, model, requests, cost_usd, minutes`.

`spent` in every later estimate is the sum of the ledger, so a project's budget is a lifetime budget,
not a per-run one. `ls` shows `spent/budget` per project.

All of these are estimates. Prices change, and the provider may bill a cancelled request that had
already started. The provider's usage page for the workspace has the real amounts. Compare it with the ledger from time to time.

## What a real run looked like

A two-page document with two screenshots, one question ("follow the instructions in the document"),
Claude Fable 5.1 at medium effort. The estimate said $0.42 worst case. The batch finished in two
minutes and cost $0.15: 30 input tokens, 3,578 cache-write tokens, 5,032 output tokens, for a
1,500-word answer. The same request, run a second time, cost $0.09 and its answer was 20% shorter. One run is one sample.
