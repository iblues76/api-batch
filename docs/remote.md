# Other machines

api-batch is one file, and its state is per machine: the projects registered in
`~/.config/api-batch/config.json`, their folders, and the key files. Three commands tie machines
together.

## `-H <host>`: run a command over there

```sh
api-batch -H lab-box estimate thesis
api-batch -H lab-box ls
```

`<host>` is an SSH alias from your `~/.ssh/config`. The command runs on that machine's copy of
api-batch, against that machine's projects. Nothing is copied: the project, its documents and the key
file must already exist there.

## `ls --all`: one table across machines

```sh
api-batch host add lab-box
api-batch host add office
api-batch ls --all
```

Prints this machine's projects, then each host's, with the host name in the header. Unreachable hosts
are reported, not fatal.

## `deploy <host>…`: install there

```sh
api-batch deploy lab-box office
```

Copies the script to `install_path` on each host (default `~/.local/bin/api-batch`), carries over
`key_dir`, `install_path` and `notify.*`, creates the virtual environment on first run, and runs `ls`
as a smoke test. Hosts that deploy successfully are added to `host ls`.

Key files are deliberately **not** copied. Put the key on the other machine the same way you did here
(a hidden prompt into a mode-600 file), or pipe it over SSH so it never touches a command line:

```sh
cat ~/.config/api-batch/keys/research.key | ssh lab-box 'umask 077; mkdir -p ~/.config/api-batch/keys && cat > ~/.config/api-batch/keys/research.key'
```

## Paths that travel

`config set` stores paths under your home directory with a leading `~`, so the same settings work on
a machine where your home is `/Users/you` instead of `/home/you`.
