# z.process

Install the `process` mod with `z.install.mod process`.

```zsh
z.process.list
z.process.list port=3000
z.process.list name=node
z.process.kill pid=12345
z.process.kill port=3000
z.process.kill name=node
```

`z.process.list` prints tab-separated PID, process name and TCP listening
ports. With no selector it lists all processes; one `pid=`, `port=` or
`name=` selector filters the rows. Multiple ports are comma-separated;
`-` means no TCP listeners were reported. Only ports visible to the current
user can be listed. `REPLY` contains the rows without the header.

Names match `ps -A -o comm=` exactly, including any OS name-length limit.
Listing ports and selecting by port require `lsof`. Port selection targets
TCP listeners and listing shows all reported listening ports of each selected
process.

`z.process.kill` requires exactly one selector and sends SIGTERM to every
matching PID. Success means that the signal was sent; the command returns
immediately without waiting for exit. `REPLY` contains successfully signaled
PIDs. Invalid selectors, no matches, lookup errors and signal failures return
status 1.
