defmodule FileStorageApi.API.Azure.Base do
  @moduledoc false

  alias ExMicrosoftAzureStorage.Storage
  alias ExMicrosoftAzureStorage.Storage.Container

  def storage(connection_name) do
    azure_blob =
      case connection_name do
        :default ->
          Application.get_env(:file_storage_api, :azure_blob)

        name ->
          Application.get_env(:file_storage_api, String.to_existing_atom("#{name}_azure_blob"))
      end

    if Keyword.fetch!(azure_blob, :development) do
      Storage.development_factory(Keyword.get(azure_blob, :host, "127.0.0.1"))
    else
      %Storage{
        account_name: Keyword.fetch!(azure_blob, :account_name),
        account_key: Keyword.fetch!(azure_blob, :account_key),
        endpoint_suffix: Keyword.fetch!(azure_blob, :environment_suffix)
      }
    end
  end

  def container(container_name, connection_name) do
    Container.new(storage(connection_name), container_name)
  end

  @spec convert_options(FileStorageApi.Container.options()) :: [
          {:maxresults, non_neg_integer} | {:marker, String.t()}
        ]
  def convert_options(options) do
    Enum.map(options, fn
      {:max_results, value} -> {:maxresults, value}
      option -> option
    end)
  end
end
