![elixir workflow](https://github.com/bettyblocks/file_storage_api/actions/workflows/elixir.yml/badge.svg)
[![Hex.pm](https://img.shields.io/hexpm/v/file_storage_api.svg)]()
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/file_storage_api)

# FileStorageApi

Library to be able to upload and manage files to different storage service azure/s3 

## Installation

It can be added to your project by adding

```elixir
def deps do
  [
    {:file_storage_api, "~> 1.0"}
  ]
end
```

Configuration

Ability to set storage engine currently S3 and Azure supported. 
For tests Mock can be used with the mox library.
```elixir
config :file_storage_api, :storage_api, engine: Azure
```

S3 configuration (options from ex_aws_s3 library)
```elixir
config :file_storage_api, :s3_config,
host: "127.0.0.1",
scheme: "http://",
port: 9000,
access_key_id: "admin",
secret_access_key: "password",
path_style: true
```

For test S3 can also be mocked by

```elixir
config :file_storage_api, :s3_config, module: AwsMock
```

Azure configuration (options from azure library)
```elixir
config :file_storage_api, :azure_blob,
  account_key: "password",
  account_name: "user",
  environment_suffix: "core.windows.net",
  host: ,
  development: "true" || "false"
```
