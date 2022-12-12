import Config

config :file_storage_api, :azure_blob,
  account_name: "account_name",
  account_key: "YWNjb3VudF9rZXk=",
  environment_suffix: "env_suffix",
  development: false

config :file_storage_api, :storage_api, engine: S3

config :file_storage_api, :s3_config, module: ExAws

config :file_storage_api, :s3_config,
  host: "127.0.0.1",
  scheme: "http://",
  port: 9000,
  access_key_id: "admin",
  secret_access_key: "password",
  path_style: true

import_config "#{Mix.env()}.exs"
