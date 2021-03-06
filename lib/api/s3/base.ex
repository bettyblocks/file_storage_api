defmodule FileStorageApi.API.S3.Base do
  @moduledoc false

  alias ExAws.Config

  @ex_aws_module Application.compile_env(:file_storage_api, [:s3_config, :module], ExAws)

  @spec config :: Config.t()
  def config do
    s3_config = Application.get_env(:file_storage_api, :s3_config)
    storage_api = Application.get_env(:file_storage_api, :storage_api)

    http_opts =
      case Keyword.get(storage_api, :custom_ca_cert) do
        cert when is_binary(cert) and byte_size(cert) > 0 -> [{:ssl_options, [cacertfile: cert]}]
        _ -> []
      end

    Config.new(
      :s3,
      access_key_id: Keyword.get(s3_config, :access_key_id),
      secret_access_key: Keyword.get(s3_config, :secret_access_key),
      s3_auth_version: Keyword.get(s3_config, :s3_auth_version),
      host: Keyword.get(s3_config, :host),
      scheme: Keyword.get(s3_config, :scheme),
      port: Keyword.get(s3_config, :port),
      region: region(s3_config),
      http_opts: http_opts
    )
  end

  @spec region(keyword) :: String.t()
  def region(s3_config \\ Application.get_env(:file_storage_api, :s3_config)) do
    region = Keyword.get(s3_config, :region)

    if(region, do: region, else: "")
  end

  @spec request(ExAws.Operation.t()) :: {:ok, term} | {:error, term}
  def request(operation) do
    @ex_aws_module.request(operation, config())
  end

  @spec convert_options(FileStorageApi.Container.options()) :: [
          {:maxresults, non_neg_integer} | {:marker, String.t()}
        ]
  def convert_options(options) do
    Enum.map(options, fn
      {:max_results, value} -> {:max_keys, value}
      option -> option
    end)
  end
end
