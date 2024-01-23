defmodule FileStorageApi.API.Azure.Container do
  @moduledoc false
  @behaviour FileStorageApi.Container

  import FileStorageApi.API.Azure.Base

  alias ExMicrosoftAzureStorage.Storage.Container, as: AzureContainer
  alias FileStorageApi.Container
  alias FileStorageApi.File

  @impl true
  def create(container_name, connection, options \\ %{}) do
    container = container(container_name, connection)

    case AzureContainer.create_container(container) do
      {:ok, result} ->
        if Map.get(options, :public) do
          AzureContainer.set_container_acl_public_access_blob(container)
        end

        {:ok, result}

      error ->
        error
    end
  end

  @impl true
  def list_files(container_name, connection, options) do
    case AzureContainer.list_blobs(container(container_name, connection), convert_options(options)) do
      {:ok, %{blobs: files, max_results: max_results, next_marker: next_marker, date: date}} ->
        {:ok,
         %Container{
           max_results: max_results,
           next_marker: next_marker,
           date: date,
           files: Enum.map(files, fn file -> struct(File, file) end)
         }}

      error ->
        error
    end
  end
end
