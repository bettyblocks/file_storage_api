defmodule FileStorageApi.API.S3.File do
  @moduledoc false
  @behaviour FileStorageApi.File
  import FileStorageApi.API.S3.Base
  alias ExAws.S3

  @impl true
  def upload(container_name, filename, blob_name) do
    [{_, file_mime_type}] = filename |> FileInfo.get_info() |> Map.to_list()
    object = blob_name || Path.basename(filename)

    container_name
    |> S3.put_object(object, File.read!(filename), content_type: to_string(file_mime_type))
    |> request()
    |> case do
      {:ok, %{status_code: 200}} ->
        {:ok, object}

      error ->
        error
    end
  end

  @impl true
  def delete(bucket, filename) do
    bucket
    |> S3.delete_object(Path.basename(filename))
    |> request()
  end

  @impl true
  def public_url(container_name, "/" <> file_path, start_time, expire_time),
    do: public_url(container_name, file_path, start_time, expire_time)

  def public_url(container_name, file_path, start_time, expire_time) do
    expires_in = Timex.Comparable.diff(expire_time, start_time, :seconds)

    S3.presigned_url(config(), :get, container_name, file_path, expires_in: expires_in)
  end

  @impl true
  def last_modified(%FileStorageApi.File{properties: %{last_modified: timestamp}}) do
    Timex.parse(timestamp, "{ISO:Extended}")
  end

  def last_modified(_), do: {:error, :incorrect_format}
end
