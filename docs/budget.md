# Budget, estimate and ledger

Three numbers protect you, in this order.

## The provider's spend limit

Set it in the provider's console, on a workspace made for the project. It is enforced by the provider
and stops billing no matter what any program on your side does. Everything below only makes you fail
earlier and more politely.

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

Web search is the one thing the estimate cannot see: each search returns results that count as input
tokens, and their size depends on the pages. Pilot two or three questions and read the real cost from
`collect` before scaling up.

## The ledger

`collect` computes the cost of each succeeded request from its reported usage — input, output, cache
reads and cache writes at their own rates, plus any web searches — and writes:

- `runs/<timestamp>/usage.csv`, one line per request;
- `runs/ledger.csv`, one line per batch: `date, batch_id, kind, model, requests, cost_usd, minutes`.

`spent` in every later estimate is the sum of the ledger, so a project's budget is a lifetime budget,
not a per-run one. `ls` shows `spent/budget` per project.

All of these are estimates. Prices change, and the provider may bill a cancelled request that had
already started. The provider's usage page for the workspace is the ground truth; compare it to the
ledger from time to time.

## What a real run looked like

A two-page document with two screenshots, one question ("follow the instructions in the document"),
Claude Fable 5.1 at medium effort. The estimate said $0.42 worst case. The batch finished in two
minutes and cost $0.15: 30 input tokens, 3,578 cache-write tokens, 5,032 output tokens, for a
1,500-word answer. The same request run a second time cost $0.09 and came back 20% shorter, which is
a useful reminder that one run is one sample.
