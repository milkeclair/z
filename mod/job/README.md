# z.job

A modifier for running functions as background jobs and collecting their results later.

## Installation

`z.install.mod job`

## Overview

`z.job` runs a function in a child process.
The child process writes its status, exit code, stdout, stderr, and result file under a job directory.
The parent shell collects finished jobs and runs callbacks.

Use it when a function can run asynchronously and the parent shell only needs the result after the command finishes.

## Workflow

1. Define a job command function.
2. Define optional success or failure callback functions.
3. Start the job with `z.job.run`.
4. Let `z.job.collect` run from `precmd`, or call it manually.

```zsh
my.cache.build() {
  z.arg.named result "$@" && local result=$REPLY

  echo "cache content" > "$result"
}

my.cache.load() {
  z.arg.named result "$@" && local result=$REPLY

  z.file.read path="$result"
  z.io "loaded: $REPLY"
}

z.job.run name=cache command=my.cache.build on_success=my.cache.load
```

## Commands

### run

- `z.job.run`
  - start a background job
  - return the job id in `REPLY`
  - register `z.job.collect` in `precmd`

Arguments:

- `name`
  - job name
- `command`
  - function to run in the child process
- `on_success`
  - callback function to run when the job succeeds
- `on_failure`
  - callback function to run when the job fails

```zsh
z.job.run name=cache command=my.cache.build on_success=my.cache.load
local job_id=$REPLY
```

### collect

- `z.job.collect`
  - collect finished jobs
  - run callbacks
  - remove collected job directories
  - return collected job ids in `REPLY`
  - return `1` when any callback fails

```zsh
z.job.collect
echo $REPLY
```

### list

- `z.job.list`
  - list jobs as separated lines: `<id> <name> <status>`

```zsh
z.job.list
```

### status

- `z.job.status id=<id>`
  - return the current job status in `REPLY`

```zsh
z.job.status id="$job_id"
echo $REPLY
```

### is.running

- `z.job.is.running id=<id>`
  - return true when the job status is `running` and the recorded process is alive

```zsh
if z.job.is.running id="$job_id"; then
  z.io "running"
fi
```

### cancel

- `z.job.cancel id=<id>`
  - kill the child process when a pid exists
  - remove the job directory

```zsh
z.job.cancel id="$job_id"
```

## Job Command

The command function runs in a child process.
It receives these named arguments:

- `id`
  - job id
- `name`
  - job name
- `dir`
  - job directory
- `result`
  - file path for durable command output

```zsh
my.job.command() {
  z.arg.named result "$@" && local result=$REPLY

  echo "result text" > "$result"
}
```

The child process writes:

- `running` before calling the command
- `success` when the command exits with `0`
- `failure` when the command exits with a non-zero status

The command must be available after sourcing `main.zsh` in the child process.

## Callback

Callbacks run in the parent shell when `z.job.collect` collects a finished job.

Callback functions receive these named arguments:

- `id`
  - job id
- `name`
  - job name
- `dir`
  - job directory
- `result`
  - result file path
- `exit_status`
  - child command exit status

```zsh
my.job.success() {
  z.arg.named result "$@" && local result=$REPLY
  z.arg.named exit_status "$@" && local exit_status=$REPLY

  z.file.read path="$result"
  z.io "exit=$exit_status result=$REPLY"
}
```

`on_success` runs for `success`.
`on_failure` runs for `failure`.
If no callback is configured, the job is still collected and removed.

## Lifecycle

Job statuses:

- `queued`
- `running`
- `success`
- `failure`

`z.job.collect` skips `queued` jobs and live `running` jobs.
If a `running` job no longer has a live process, it is collected as `failure`.

## Files

Job files are stored under:

```zsh
/tmp/z/job/$$/jobs/<job-id>
```

Files:

- `meta`
  - sourceable metadata for the job
- `pid`
  - child process id
- `status`
  - `queued`, `running`, `success`, or `failure`
- `exit`
  - child command exit status
- `result`
  - output for callbacks
- `stdout`
  - child process stdout
- `stderr`
  - child process stderr
