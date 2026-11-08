# Keeping the key secret

API keys leak in boring ways, almost always while someone is *checking* or *passing* one: echoed to a
terminal to see that it is there, given to a program as a command-line flag (visible to every user on
the machine in `ps`), or pasted into a chat with an AI assistant, which keeps a transcript. api-batch is
built so none of those are needed.

## What api-batch does

- It stores the **name** of the key file, never the key. `config.json` and every project file are
  safe to look at and to commit.
- It reads the key file at run time, inside the process, and hands it to the provider SDK. The key is
  never printed, logged, or placed on a command line, not even by `deploy`, which copies the script
  and settings but **not** the key files.
- `init` reports whether the key file exists; nothing reports what is in it.

## What you do

**Save the key without showing it.** A hidden prompt, straight into a file only you can read:

```sh
mkdir -p ~/.config/api-batch/keys
(umask 077; read -rs -p "API key: " k && printf '%s' "$k" > ~/.config/api-batch/keys/research.key; unset k); echo
```

**Check it without showing it.** Mode and size are enough; the model list is a free call that proves
the key works without printing it (the header goes to curl on stdin, not on the command line):

```sh
stat -c 'mode=%a bytes=%s' ~/.config/api-batch/keys/research.key     # macOS: stat -f 'mode=%Lp bytes=%z'
{ printf 'header = "x-api-key: '; tr -d '\r\n' < ~/.config/api-batch/keys/research.key; printf '"\n'; } | curl -s -o /dev/null -w 'HTTP %{http_code}\n' -K - -H "anthropic-version: 2023-06-01" https://api.anthropic.com/v1/models
```

`HTTP 200` is a working key. `401` is not; fix the file rather than printing it.

**If an agent is driving.** Tell it the key file's **path**, never the key. Let it run `estimate`
freely and have it stop there: `submit` spends money, so a person should press it. We learned this
the usual way: a sentence that merely described the submit command was read as approval, and two
identical batches ran.

**If it leaks anyway.** Revoke the key in the provider's console and make a new one. Creating a new key
does not disable the old one.
