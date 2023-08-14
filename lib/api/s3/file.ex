defmodule FileStorageApi.API.S3.File do
  @moduledoc false

  import FileStorageApi.API.S3.Base

  @behaviour FileStorageApi.File

  alias ExAws.Config
  alias ExAws.S3

  @impl true
  def upload(container_name, connection_name, filename, blob_name, opts \\ []) do
    object = blob_name || Path.basename(filename)

    container_name
    |> S3.put_object(object, File.read!(filename), opts)
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
    |> S3.delete_object(filename)
    |> request(connection_name)
  end

  @impl true
  def public_url(container_name, "/" <> file_path, opts), do: public_url(container_name, file_path, opts)

  def public_url(container_name, file_path, opts) do
    is_public = Keyword.get(opts, :public, false)
    connection_name = Keyword.get(opts, :connection_name)
    start_time = Keyword.get(opts, :start_time)
    expire_time = Keyword.get(opts, :expire_time)

    expires_in = Timex.Comparable.diff(expire_time, start_time, :seconds)

    s3_signed =
      S3.presigned_url(Config.new(:s3, config(connection_name)), :get, container_name, file_path, expires_in: expires_in)

    case s3_signed do
      {:ok, url} ->
        if is_public do
          public_url =
            url
            |> URI.parse()
            |> Map.put(:query, nil)
            |> URI.to_string()

          {:ok, public_url}
        else
          url
        end

      error ->
        error
    end
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
