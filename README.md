# [Elixir official Mix & OTP Guide](https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html)

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

## Agent

## GenServer
## Supervisor and Application
## ETS
## Dependencies and umbrella apps
## Task and gen-tcp
## Docs, tests and with
## Distributed tasks and configuration
