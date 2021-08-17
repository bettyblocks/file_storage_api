defmodule FileStorageApi.API.Azure.Base do
  @moduledoc false

  alias Azure.Storage
  alias Azure.Storage.Container

  def storage do
    azure_blob = Application.get_env(:file_storage_api, :azure_blob)

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

  def container(container_name) do
    Container.new(storage(), container_name)
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
