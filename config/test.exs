import Config

config :file_storage_api, :storage_api, engine: Mock

config :file_storage_api, :s3_config, module: AwsMock
