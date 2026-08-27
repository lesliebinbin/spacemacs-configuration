# emacs-jupyter REPL `tqdm` progress fix

This runbook is for an agent repairing live `tqdm` progress rendering in this
Spacemacs Jupyter REPL. It deliberately separates automated checks from the
two GUI checks that only the user can perform.

## Scope and diagnosis

`M-x jupyter-run-repl` starts the selected Jupyter kernel directly. For the
`Causal AI` kernel, this is Python's `ipykernel_launcher`, communicating with
Emacs through the native Jupyter ZeroMQ channels; it is not a browser notebook
or terminal IPython session.

The failing call is:

```python
from pgmpy.datasets import load_dataset
dataset = load_dataset("sachs_discrete")
```

`pgmpy` uses `tqdm` while downloading the three Sachs files. `tqdm` redraws one
line by writing carriage returns (`\r`) in Jupyter IOPub `stream` messages.
The existing `emacs-jupyter` REPL appends those chunks with
`jupyter-insert-ansi-coded-text`; it does not replace the current transient
output line. The result is stale `0%` lines.

This is not an Emacs-buffer limitation: `vterm` renders terminal `tqdm`
progress successfully. It is also unrelated to `ipywidgets` browser rendering.
The target is plain stream-output handling in the Emacs REPL.

## Required baseline check

**Read this `.spacemacs.d` repository before changing the fork.** In
particular, inspect:

```sh
cd /home/lesliebinbinhuang/.spacemacs.d
sed -n '150,170p' emacs-config/layers.el
sed -n '1,140p' user-config/emacs-jupyter.org
git --no-pager status --short
```

Expected baseline:

- `emacs-config/layers.el` points `jupyter` at the local clone:
  `/home/lesliebinbinhuang/codings/custom-emacs-jupyter`.
- `user-config/emacs-jupyter.org` does not redefine `jupyter-get-client`; the
  former compatibility override is commented out.
- Treat unrelated dirty worktree changes as user-owned and do not revert them.

Verify the active development repository before making code changes:

```sh
cd /home/lesliebinbinhuang/codings/custom-emacs-jupyter
git remote -v
git --no-pager log -1 --format='%H%n%s'
git status --short
```

The intended fork is `git@github.com:lesliebinbin/custom-emacs-jupyter.git`,
initially based on upstream commit
`05ea84067f784fb7cd1f829d7a0fadcad20466aa`.

## Step 1: reproduce and establish the visual baseline

Start or reload Spacemacs so it uses the local clone. In the Causal AI REPL,
clear only the pgmpy Hugging Face dataset cache to force a fresh download:

```sh
rm -rf ~/.cache/huggingface/hub/datasets--pgmpy--example_datasets
```

Then evaluate the Sachs load call above.

**PAUSE — ask the user to confirm:** the REPL shows the stale three `0%` lines,
or otherwise describe exactly what it shows. Do not begin the code change until
this confirms that the local fork is active and the issue is reproducible.

## Step 2: inspect the narrow implementation surface

Read, do not modify, these locations first:

```sh
cd /home/lesliebinbinhuang/codings/custom-emacs-jupyter
sed -n '250,285p' jupyter-repl.el
sed -n '995,1030p' jupyter-repl.el
sed -n '475,500p' jupyter-mime.el
find test -maxdepth 1 -type f -name '*.el' -print | sort
```

The primary target is `jupyter-handle-stream` in `jupyter-repl.el`. Preserve
the existing behaviors for:

- normal multi-line stdout and stderr;
- ANSI coloring via `jupyter-insert-ansi-coded-text`;
- stream output not associated with the current request;
- widget/`comm_msg` output, which uses a separate display buffer;
- read-only output text and existing cell/prompt boundaries.

Do not globally reinterpret carriage returns in `jupyter-mime.el`: that helper
is shared by more than REPL stream output.

## Step 3: write focused tests first

Use the existing ERT conventions under `test/`. Add focused coverage for the
new REPL stream behavior, preferably in a dedicated REPL test file if one does
not already exist. At minimum, cover:

1. ordinary stream text appends unchanged;
2. a single chunk containing `\r` overwrites only the active output line;
3. a progress update split across multiple IOPub messages still rewrites the
   same line;
4. a terminating newline makes the completed progress line permanent and the
   next normal output append normally;
5. ANSI-colored stream text retains its text properties after replacement.

Run the smallest relevant ERT selector while iterating. The project exposes:

```sh
cd /home/lesliebinbinhuang/codings/custom-emacs-jupyter
make test PATTERN=repl
```

If `eldev` is unavailable, report that dependency failure clearly; do not
silently skip the tests. Run the full suite after focused tests pass:

```sh
make test
```

## Step 4: implement the minimal REPL-only fix

Design a request-scoped transient-output marker or equivalent state in
`jupyter-repl-client` so successive carriage-return updates replace only the
current progress line belonging to that request. Keep the state valid when:

- IOPub chunks split at arbitrary positions;
- output includes a final newline;
- a request completes, errors, is interrupted, or the REPL cell is cleared;
- another request's output is inserted.

Use existing REPL insertion macros, particularly `jupyter-repl-append-output`,
to preserve output placement, control-code handling, read-only properties, and
the current buffer/window behavior. Avoid broad rewrites of MIME insertion or
the kernel protocol implementation.

Byte-compile and rerun the focused test after each coherent edit:

```sh
cd /home/lesliebinbinhuang/codings/custom-emacs-jupyter
make compile
make test PATTERN=repl
```

Then run `make test` once before manual validation.

## Step 5: GUI validation

Reload the changed local package in a fresh Emacs session. Do not assume a
reload succeeded merely because the source changed; confirm the loaded library
comes from the local clone with `M-x locate-library RET jupyter-repl RET`.

Clear the pgmpy dataset cache again, then rerun the Sachs load.

**PAUSE — ask the user to confirm all of the following before committing:**

1. progress advances in the *Emacs Jupyter REPL buffer* rather than remaining
   at `0%`;
2. each completed download leaves a sensible final line;
3. ordinary `print`, traceback, and ANSI-colored output still render normally;
4. no new Jupyter errors appear in `*Messages*`.

If any check fails, capture the exact REPL text and relevant messages, extend
the focused test to reproduce it, and iterate from Step 3.

## Step 6: commit and publish only after validation

Once tests and the GUI check pass, inspect the fork diff carefully:

```sh
cd /home/lesliebinbinhuang/codings/custom-emacs-jupyter
git --no-pager diff --check
git --no-pager diff
git status --short
```

Commit only the stream-output fix and its tests to the fork, then push it.
Keep `.spacemacs.d` pointed at the local path while actively iterating.

After the fork commit is pushed and the user accepts the result, replace the
local `jupyter` declaration in `.spacemacs.d/emacs-config/layers.el` with the
GitHub recipe:

```elisp
(jupyter :location (recipe :fetcher github
                           :repo "lesliebinbin/custom-emacs-jupyter"))
```

Restart or sync Spacemacs and repeat the GUI validation once. Do not switch the
recipe before the local implementation is validated and pushed.

## Rollback

If the fix regresses normal output, reset only the fork's fix commit using its
Git history, then restore the prior known-good local revision. Do not use
destructive Git commands in `.spacemacs.d`, and do not remove the whole
Hugging Face cache: only
`datasets--pgmpy--example_datasets` is relevant to this reproduction.
