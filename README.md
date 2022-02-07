# Skynet

**Sarah kills robots :boom: :robot:**

## Requirements

Skynet requires Erlang/OTP and Elixir. See [.tool-versions](.tool-versions) for the specific versions.

## Initial setup

Install the [required language versions](#requirements), if using [asdf](https://asdf-vm.com/), just run:

```console
asdf install
```

Then download the dependencies and compile the app:

```console
mix do deps.get, compile
```

### Running the application locally

To run Skynet you can do it by running:

```console
SKYNET_LOG_LEVEL=debug mix run --no-halt

# or using Docker
docker build -t skynet .
docker run -it -p 4000:4000 -e SKYNET_LOG_LEVEL=debug skynet

# alternatively you can run Skynet in interactive mode
SKYNET_LOG_LEVEL=debug iex -S mix
```

You can now use the Rest API running on [`localhost:4000`](http://localhost:4000). There is an attached [Insomnia](https://insomnia.rest/download) collection to interact with the API [here](support/skynet_api.insomnia.json) or see the [API Endpoints documentation](#api-endpoints).

## Configuration

Some Skynet settings can be set at runtime by using environment variables. For easier convenience you can use [Direnv](https://direnv.net/) and copy the `.envrc.local.tpl` file to `.envrc.local` and set your own values there:

```console
# copy the provided template file
cp .envrc.local.tpl .envrc.local

# edit and add your values
$EDITOR .envrc.local

# allow direnv to read the variables
direnv allow
```

### Supported Variables

- **SKYNET_PORT** - sets the port for the Skynet API. Default "4000".
- **SKYNET_LOG_LEVEL** - sets the Elixir Legger's log level for Skynet. Default "info".

## Testing

```console
mix test
```

## API Endpoints

### `GET /_health`

Returns the application version, can be used for load balancer health checks.

**Sample Response:**

```json
{
  "version": "0.1.0"
}
```

### `POST /terminators`

Creates a new Terminator.

**Sample Request:**

```json
{
  "name": "T-800" // OPTIONAL Terminator name
}
```

**Note:** _If Terminator name is omitted, it will generate a random one_

**Sample Response:**

```json
{
  "data": {
    "name": "T-800",
    "pid": "#PID<0.1087.0>"
  }
}
```

### `GET /terminators`

List all the alive Terminators.

**Sample Response:**

```json
{
  "data": [
    { "name": "T-800" },
    { "name": "T-900" },
    { "name": "hajasjsa" },
    { "name": "foob@r" },
    { "name": "Another" }
  ]
}
```
