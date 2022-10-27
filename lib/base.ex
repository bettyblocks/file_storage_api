defmodule FileStorageApi.Base do
  @moduledoc false

  @spec storage_engine(atom) :: :s3 | :azure | :mock
  def storage_engine(:default) do
    :file_storage_api
    |> Application.get_env(:storage_api)
    |> Keyword.get(:engine)
    |> convert_storage_setting()
  end

  def storage_engine(container_name) do
    engine_key = String.to_existing_atom(container_name <> "_conn")

    engine_key
    |> Application.get_env(:storage_api)
    |> Keyword.get(:engine)
    |> convert_storage_setting()
  end

  defp convert_storage_setting("s3"), do: :s3
  defp convert_storage_setting("S3"), do: :s3
  defp convert_storage_setting(S3), do: :s3
  defp convert_storage_setting(Mock), do: :mock
  defp convert_storage_setting(_), do: :azure
end
