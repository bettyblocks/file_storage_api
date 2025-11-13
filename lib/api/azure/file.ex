defmodule FileStorageApi.API.Azure.File do
  @moduledoc false

  import FileStorageApi.API.Azure.Base

  @behaviour FileStorageApi.File

  alias ExMicrosoftAzureStorage.Storage
  alias ExMicrosoftAzureStorage.Storage.ApiVersion
  alias ExMicrosoftAzureStorage.Storage.Blob
  alias ExMicrosoftAzureStorage.Storage.SharedAccessSignature

  @impl true
  def upload(container_name, connection, filename, blob_name, opts \\ []) do
    converted_opts = convert_opts(opts)

    case Blob.upload_file(
           container(container_name, connection),
           filename,
           blob_name,
           converted_opts
         ) do
      {:ok, %{request_url: _request_url}} ->
        {:ok, blob_name || Path.basename(filename)}

      {:error, %{error_code: "ContainerNotFound"}} ->
        {:error, :container_not_found}

      error ->
        error
    end
  end

  @impl true
  def delete(container_name, filename, connection) do
    container_name
    |> container(connection)
    |> Blob.new(filename)
    |> Blob.delete_blob()
  end

  @impl true
  def public_url(container_name, "/" <> file_path, opts),
    do: public_url(container_name, file_path, opts)

  def public_url(container_name, file_path, opts) do
    is_public = Keyword.get(opts, :public, false)
    connection = Keyword.get(opts, :connection)
    start_time = Keyword.get(opts, :start_time)
    expire_time = Keyword.get(opts, :expire_time)

    %{
      container_name: container_name,
      storage_context:
        %{
          account_name: account_name
        } = storage
    } = container(container_name, connection)

    if is_public do
      {:ok, "#{Storage.endpoint_url(storage, :blob_service)}/#{container_name}/#{file_path}"}
    else
      signature =
        SharedAccessSignature.new()
        |> SharedAccessSignature.service_version(ApiVersion.get_api_version(:storage))
        |> SharedAccessSignature.for_blob_service()
        |> SharedAccessSignature.add_permission_read()
        |> SharedAccessSignature.start_time(start_time)
        |> SharedAccessSignature.expiry_time(expire_time)
        |> SharedAccessSignature.protocol(storage_protocol(storage))
        |> SharedAccessSignature.add_resource_blob_blob()
        |> SharedAccessSignature.add_canonicalized_resource("/blob/#{account_name}/#{container_name}/#{file_path}")
        |> SharedAccessSignature.sign(storage)

      {:ok, "#{Storage.endpoint_url(storage, :blob_service)}/#{container_name}/#{file_path}?#{signature}"}
    end
  end

  @impl true
  def last_modified(%FileStorageApi.File{properties: %{last_modified: timestamp}}) do
    {:ok, timestamp}
  end

  def last_modified(_), do: {:error, :incorrect_format}

  defp storage_protocol(%{is_development_factory: true}), do: "http"
  defp storage_protocol(_context), do: "https"

  defp convert_opts(opts) do
    opts
    |> Enum.map(fn {key, value} ->
      case key do
        :meta -> {key, Enum.map(value, fn {k, v} -> {String.replace(k, "-", "_"), v} end)}
        _ -> {key, value}
      end
    end)
    |> Enum.into(%{})
  end
end
