# Keeping the key secret

API keys usually leak while someone is checking one or passing one to a program. The key is shown in a terminal to see that it is there, given to a program as a command-line flag (which every user on the machine can see in `ps`), or pasted into a chat with an AI assistant, which keeps a transcript. api-batch is built so that none of those is needed.

## What api-batch does

- It stores the **name** of the key file, never the key. `config.json` and every project file are
  safe to look at and to commit.
- It reads the key file at run time, inside the process, and hands it to the provider SDK. The key is
  never printed, logged, or placed on a command line, not even by `deploy`, which copies the script
  and settings but **not** the key files.
- `init` reports whether the key file exists; nothing reports what is in it.

## What you do

**Save the key without showing it.** Type it at a hidden prompt that writes it straight into a file only you can read:

```sh
mkdir -p ~/.config/api-batch/keys
(umask 077; read -rs -p "API key: " k && printf '%s' "$k" > ~/.config/api-batch/keys/research.key; unset k); echo
```

**Check it without showing it.** The file's mode and size are enough to see that it is there. To see that the key works, ask for the model list, which is free. The key goes to curl on stdin, not on the command line:

```sh
stat -c 'mode=%a bytes=%s' ~/.config/api-batch/keys/research.key     # macOS: stat -f 'mode=%Lp bytes=%z'
{ printf 'header = "x-api-key: '; tr -d '\r\n' < ~/.config/api-batch/keys/research.key; printf '"\n'; } | curl -s -o /dev/null -w 'HTTP %{http_code}\n' -K - -H "anthropic-version: 2023-06-01" https://api.anthropic.com/v1/models
```

`HTTP 200` means the key works. `401` means it does not. In that case, save the key again, and do not display the file.

**If an agent is running api-batch.** Tell it the path of the key file, never the key. Let it run `estimate` as often as it needs, and have it stop there. `submit` spends money, so a person should run it. This happened to us once: an agent read a sentence that only described the submit command as approval, and two identical batches ran.

**If it leaks anyway.** Revoke the key in the provider's console and make a new one. Creating a new key
does not disable the old one.
