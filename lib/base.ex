defmodule FileStorageApi.Base do
  @moduledoc false

  def api_module(connection, module) when module in [Container, File] do
    Module.concat([FileStorageApi.API, storage_engine(connection), module])
  end

  @spec read_from_map(map, atom, any) :: any
  def read_from_map(options, key, fallback_value) do
    if Map.has_key?(options, key) do
      options[key]
    else
      fallback_value
    end
  end

  @spec storage_engine(atom | map | keyword) :: S3 | Azure | Mock
  defp storage_engine(:default) do
    :file_storage_api
    |> Application.get_env(:storage_api)
    |> storage_engine()
  end

  defp storage_engine(connection_name) when is_atom(connection_name) do
    engine_key = String.to_existing_atom("#{connection_name}_conn")

    :file_storage_api
    |> Application.get_env(engine_key)
    |> storage_engine()
  end

  defp storage_engine(connection) do
    connection
    |> Access.get(:engine)
    |> convert_to_module()
  end

  defp convert_to_module(engine) when engine in [:s3, "s3", "S3", S3] do
    S3
  end

  defp convert_to_module(Mock), do: Mock
  defp convert_to_module(_), do: Azure
end
