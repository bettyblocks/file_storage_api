defmodule FileStorageApi.API.S3.File do
  @moduledoc false

  import FileStorageApi.API.S3.Base

  @behaviour FileStorageApi.File

  alias ExAws.Config
  alias ExAws.S3

  @impl true
  def upload(container_name, connection, filename, blob_name, opts \\ []) do
    object = blob_name || Path.basename(filename)

    container_name
    |> S3.put_object(object, File.read!(filename), opts)
    |> request(connection)
    |> case do
      {:ok, %{status_code: 200}} ->
        {:ok, object}

      {:error, error} ->
        handle_error(error)
    end
  end

  @impl true
  def delete(bucket, filename, connection) do
    bucket
    |> S3.delete_object(filename)
    |> request(connection)
  end

  @impl true
  def public_url(container_name, "/" <> file_path, opts), do: public_url(container_name, file_path, opts)

  def public_url(container_name, file_path, opts) do
    public? = Keyword.get(opts, :public, false)
    connection = Keyword.get(opts, :connection)
    start_time = Keyword.get(opts, :start_time)
    expire_time = Keyword.get(opts, :expire_time)

    expires_in = Timex.Comparable.diff(expire_time, start_time, :seconds)
    storage_config = config(connection)

    s3_signed = S3.presigned_url(Config.new(:s3, storage_config), :get, container_name, file_path, expires_in: expires_in)

    case s3_signed do
      {:ok, url} -> {:ok, transform_url(url, public?, storage_config)}
      error -> error
    end
  end

  @spec transform_url(binary, boolean, Keyword.t()) :: binary
  defp transform_url(signed_url, public?, storage_config) do
    url
    |> URI.parse()
    |> replace_host(storage_config[:external_host])
    |> remove_query_params(public?)
    |> URI.to_string()
  end

  @spec replace_host(URI.t(), binary | nil) :: URI.t()
  defp replace_host(url, nil), do: url

  defp replace_host(url, external_host) when is_binary(external_host) do
    Map.put(parsed_url, :host, external_host)
  end

  @spec remove_query_params(URI.t(), boolean) :: URI.t()
  defp remove_query_params(url, true) do
    Map.put(parsed_url, :query, nil)
  end

  defp remove_query_params(url, _), do: url

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
