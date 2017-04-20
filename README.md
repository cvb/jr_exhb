# JrExhb

Umbrella app contains:
* `Timer` - tool that allows to launch code with specified intervals of time
* `GhTrends` - main app, contains db handling, data fetching, HTTP API and react ui
* `GhTrendsCli` - command line tool for GhTrends HTTP API, after build it will be located in `bin/cli`

## Build
There is `Dockerfile` provided, that could be used as build instructions, or
to build docker container.

There is also `docker-compose.yml` that is suitable to configure and launch app.

### Docker compose
To build and launch `docker-compose up` should be enough. It will build
everything and launch app.

There is also `bin/dcli` helper that can launch `bin/cli` tool inside running
container.

### Usual mix
This is usual umbrella project, nothing special, so usual
```
mix deps.get &&\
mix compile  &&\
cd apps/gh_trends_cli/ &&\
mix escript.build
```
should work.

## Launch
The only app that expose some ui is `GhTrends`, it can be configured with env
variables:
- GH_TRENDS_PORT - port for HTTP API, default @default_port
- GH_TRENDS_START_SYNC - if true, github sync will be launched with app init,
  default is false
- GH_TRENDS_SYNC_INTERVAL - interval in ms of github sync, default is 10000
- MNESIA_DIR - directory for mnesia, default is not set, si it will use current
  dir

If using `docker-compose` they are already set to sane values, reac ui should be
accessible at `docker-host:4001/index.html`.

## Cli
Usage: `cli command [options]`
common options:
- `--host` (`-h`) - to specify host, default `http://localhost:4001`
commands:
- `repo` - to get infor about repository by name or id
  options:
  - `--name name` (`-n name`) for name or id, required
  - `--verbose` (`-v`) for verbose repository info

- `repos` - to get all repositories
  options:
  - `--verbose` (`-v`) for verbose repository info

- `start_sync` - to start sync
  options:
  - `--ms` (`-m`) interval in ms
  - `--force` (`-f`) restart timer if it's running

- `stop_sync` - stop sync

## Db
Mnesia is used as persistent database. This looks like sane choice because:
- it's relatively simple to use
- it's already included into erlang, which means less operation cost for the whole app
- amount of data is small, fits into memory and won't grow
