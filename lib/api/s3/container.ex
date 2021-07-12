defmodule FileStorageApi.API.S3.Container do
  @moduledoc false
  @behaviour FileStorageApi.Container

  import FileStorageApi.API.S3.Base
  alias ExAws.S3
  alias FileStorageApi.{Container, File}

  @impl true
  def create(container_name) do
    container_name
    |> S3.put_bucket(region())
    |> request()
  end

  @impl true
  def list_files(options) do
    "block-store-container"
    |> S3.list_objects(convert_options(options))
    |> request()
    |> case do
      {:ok, %{body: %{contents: files, max_keys: max_results, next_marker: next_marker}}} ->
        {:ok,
         %Container{
           max_results: max_results,
           next_marker: next_marker,
           files: Enum.map(files, fn file -> struct(File, %{name: file.key, properties: file}) end)
         }}

      error ->
        error
    end
  end
end
