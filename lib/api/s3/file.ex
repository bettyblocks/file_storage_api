defmodule FileStorageApi.API.S3.File do
  @moduledoc false

  import FileStorageApi.API.S3.Base

  @behaviour FileStorageApi.File

  alias ExAws.S3
  alias FileStorageApi.File, as: BaseFile

  @impl true
  def upload(container_name, connection_name, filename, blob_name) do
    file_mime_type = BaseFile.mime_type(filename)
    object = blob_name || Path.basename(filename)

    container_name
    |> S3.put_object(object, File.read!(filename), content_type: file_mime_type)
    |> request(connection_name)
    |> case do
      {:ok, %{status_code: 200}} ->
        {:ok, object}

      {:error, error} ->
        handle_error(error)
    end
  end

  @impl true
  def delete(bucket, filename, connection_name) do
    bucket
    |> S3.delete_object(Path.basename(filename))
    |> request(connection_name)
  end

  defp mime_type(filename) do
    case System.shell("which mimetype") do
      {_location, 0} ->
        {result, 0} = System.shell("mimetype #{filename}")

        result
        |> String.trim()
        |> String.split(" ")
        |> Enum.reverse()
        |> hd()

      {_empty, 1} ->
        [{_, file_mime_type}] = filename |> FileInfo.get_info() |> Map.to_list()
        file_mime_type
    end
  end

  @impl true
  def public_url(container_name, "/" <> file_path, start_time, expire_time, connection_name),
    do: public_url(container_name, file_path, start_time, expire_time, connection_name)

  def public_url(container_name, file_path, start_time, expire_time, connection_name) do
    expires_in = Timex.Comparable.diff(expire_time, start_time, :seconds)

    S3.presigned_url(config(connection_name), :get, container_name, file_path, expires_in: expires_in)
  end

  @impl true
  def last_modified(%FileStorageApi.File{properties: %{last_modified: timestamp}}) do
    Timex.parse(timestamp, "{ISO:Extended}")
  end

  def last_modified(_), do: {:error, :incorrect_format}

  defp handle_error({_, _, %{status_code: 404, body: body}} = error) do
    if String.contains?(body, "<Code>NoSuchBucket</Code>") do
      {:error, :container_not_found}
    else
      {:error, error}
    end
  end

  defp handle_error(error) do
    {:error, error}
  end
end
