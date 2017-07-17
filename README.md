# [Elixir official Mix & OTP Guide](https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html)

## [Processes](https://elixir-lang.org/getting-started/processes.html)

### spawn

`spawn/1` spawns new processes.
- returns `PID`
- most likely dies as soon as it executes the fn
- `self/0` return PID of current process


```elixir
spawn fn -> 1 + 2 end #PID<0.43.0>

pid = spawn fn -> 1 + 2 end #PID<0.44.0>

Process.alive?(pid) # false

self() #PID<0.41.0>

Process.alive?(self()) # true
```

### send and receive

`send/2` message to process and `receive/1`

```elixir
send self(), {:hello, "world"}
# {:hello, "world"}

receive do
  {:hello, msg} -> msg
  {:world, msg} -> "won't match"
end
# "world"
```

- `send/2` stores message in **process mailbox**
- `receive/1` searches process mailbox for matching **pattern**
  - also supports **guard** and **many** clauses such as `case/2`

Use `after` to specify timeout
```elixir
receive do
  {:hello, msg}  -> msg
after
  1_000 -> "nothing after 1s"
end
# "nothing after 1s"
```

Full example
```elixir
parent = self() # #PID<0.41.0>

# Uses parent proc
send(parent, {:hello, self()}) # #PID<0.41.0>

# spawns a new proc
spawn fn -> send(parent, {:hello, self()}) end # #PID<0.48.0>
spawn fn -> send(parent, {:hello, self()}) end # #PID<0.51.0>

receive do
  {:hello, pid} -> "Got hello from #{inspect pid}"
end # "Got hello from #PID<0.48.0>"
```

`flush/0` flushes and prints all messages in a mailbox
```elixir
send self(), :hello
#:hello

flush()
#:hello
#:ok
```

### Links

Procs are isolated so failures don't propogate
```elixir
spawn fn -> raise "oops" end
#[error] Process #PID<0.116.0> raised an exception
#** (RuntimeError) oops
#    (stdlib) ...
```
Use `spawn_link\1` to propogate errors
```elixir
spawn_link fn -> raise "oops" end
#PID<0.41.0>

#** (EXIT from #PID<0.41.0>) an exception was raised:
#    ** (RuntimeError) oops
#        :erlang.apply/2
```
Link manually with `Process.link/1`

### Tasks

**Task** provides better error reports and introspection
```elixir
Task.start fn -> raise "oops" end # {:ok, #PID<0.55.0>}

#15:22:33.046 [error] Task #PID<0.55.0> started from #PID<0.53.0> terminating
#** (RuntimeError) oops
#    (elixir) lib/task/supervised.ex:74: Task.Supervised.do_apply/2
#    (stdlib) proc_lib.erl:239: :proc_lib.init_p_do_apply/3
#Function: #Function<20.90072148/0 in :erl_eval.expr/5>
#    Args: []
```

### State

To store state, write a process that **loops infinitely**.

:shipit: [Stateful task](https://github.com/arafatm/edu_elixir/commit/23f0e7c)
- `start_link` starts a new proc that calls `loop`
- `loop` waits for messages
- on `:get` loop sends message back and calls itself to wait on new message

To test
```elixir
{:ok, pid} = KV.start_link       # {:ok, #PID<0.62.0>}
send pid, {:get, :hello, self()} # {:get, :hello, #PID<0.41.0>}
flush() # nil
#:ok

send pid, {:put, :hello, :world} # {:put, :hello, :world}
send pid, {:get, :hello, self()} # {:get, :hello, #PID<0.41.0>}
flush() # :world
#:ok
```
- on the 1st `:get` there are no messages in mailbox so flush shows `nil`
- `:put` stores the message in a map

Processes can also be **named**
```elixir
Process.register(pid, :kv)       # true
send :kv, {:get, :hello, self()} # {:get, :hello, #PID<0.41.0>}
flush()                          # :world
#:ok
```

[Agent](https://hexdocs.pm/elixir/Agent.html) is another abstraction around state
```elixir
{:ok, pid} = Agent.start_link(fn -> %{} end)                  # {:ok, #PID<0.72.0>}
Agent.update(pid, fn map -> Map.put(map, :hello, :world) end) # :ok
Agent.get(pid, fn map -> Map.get(map, :hello) end)            # :world
```

## Intro to MIX

### Our First Project

:shipit: [mix new kv --module KV](https://github.com/arafatm/edu_elixir/commit/70cdef8)

Note the generated dirs
- `config/`
- `lib/`
- `test/`

### Project Compilation

`mix.exs` has 2 main sections
- `def project` for project configuration e.g. name, version
- `def application` to generate application file
- `def deps` invoked from `project` to define dependencies

Also generated a `lib/kv.ex` as a starting point

:shipit: `mix compile`
- geerates `kv.app`
- compiled artifacts in `_build`

:boom: `iex -S mix` to run iex session

### Running Tests

- test files are of form `test/<filename>_test.exs`
- test files are `*.exs` so they don't need to be compiled
- `use ExUnit.Case` to inject testing API
- `test/test_helper.exs` sets up test framework e.g. `ExUnit.start()`

`mix test test/kv_test.exs:5` to run specific test file on specific line number

### Environments

3 environments by default
- `:dev` default environment
- `:test` used by `mix test`
- `:prod`

`MIX_ENV=prod mix compile` to run command  in specific environment

### Exploring

`mix help` to see available tasks

## State

Elixir is **immutable**. To share state we need **buckets** via:
- Processes
- ETS

Available Process abstractions

- **Agent** - Simple wrappers around state.
- **Task** - Asynchronous units of computation that allow spawning a process and potentially retrieving its result at a later time.
- **GenServer** - “Generic servers” (processes) that encapsulate state, provide sync and async calls, support code reloading, and more.
- **GenEvent** - “Generic event” managers that allow publishing events to multiple handlers.

All abstractions above build on processes with basic features like `send`, `receive`, `spawn`, `link`

### Agents

```elixir
{:ok, agent} = Agent.start_link fn -> [] end
# {:ok, #PID<0.57.0>}
Agent.update(agent, fn list -> ["eggs" | list] end)
# :ok
Agent.get(agent, fn list -> list end)
# ["eggs"]
Agent.stop(agent)
# :ok
```

- `Agent.update` takes current state as input and returns new desired state
- `Agent.get` takes current state as input and returns value agent would return
- `Agent.stop` terminates agent process

:shipit: [Agent implementation](https://github.com/arafatm/edu_elixir/commit/72290f4)

:shipit: [Agent delete key](https://github.com/arafatm/edu_elixir/commit/b7eae15)

:shipit: [Agent client vs server](https://github.com/arafatm/edu_elixir/commit/7dd8e5b)
- The first `Process` puts client to sleep
- The second `Process` puts server to sleep

## GenServer

### 

We can name buckets with `Agent.start_link(fn -> %{} end, name: shopping)` but **not a good idea**
- atoms are **not garbage collected**
- instead we can create a **registry process** that holds a map associating bucket name to process
- registry needs to **monitor** each bucket to clean up stale entries

### Our first GenServer

**GenServer** has client API and server callbacks

:shipit: [GenServer implementation](https://github.com/arafatm/edu_elixir/commit/f1b774a)

In `start_link\3`
- `__MODULE__` = _this_ module will implement server callbacks
- calls `init` and blocks until complete
- `init` sets up the state

GenServer must implement `init` and return `{:ok, somestate}`

GenServer has 2 request types:
- `call` is synchronous and **must return** a response
- `cast` is asynchronous with no response

On the client API
- `lookup` calls `handle_call({:lookup ...`
- `create` casts `handle_cast({:create ...`

`def stop` is used to stop GenServer. Not used in our tests because an implicit `:shutdown` signal is sent

### The need for monitoring

The registry may become stale if a bucket stops or crashes

:shipit: [stale registry](https://github.com/arafatm/edu_elixir/commit/d114d93)
- The test fails since the bucket remains in registry even after we stop the bucket process
- To fix, we need registry to monitor every spawned bucket

### call, cast or info?
### Monitors or links?
## Supervisor and Application
## ETS
## Dependencies and umbrella apps
## Task and gen-tcp
## Docs, tests and with
## Distributed tasks and configuration
