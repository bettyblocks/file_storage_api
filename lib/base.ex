defmodule FileStorageApi.Base do
  @moduledoc false

  @spec storage_engine(atom) :: :s3 | :azure | :mock
  def storage_engine(:default) do
    :file_storage_api
    |> Application.get_env(:storage_api)
    |> Keyword.get(:engine)
    |> convert_storage_setting()
  end

  def storage_engine(connection_name) do
    engine_key = String.to_existing_atom("#{connection_name}_conn")

    :file_storage_api
    |> Application.get_env(engine_key)
    |> Keyword.get(:engine)
    |> convert_storage_setting()
  end

  defp convert_storage_setting(engine) when engine in [:s3, "s3", "S3"] do
    :s3
  end

  defp convert_storage_setting(Mock), do: :mock
  defp convert_storage_setting(_), do: :azure
end
