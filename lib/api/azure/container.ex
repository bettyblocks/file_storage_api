defmodule FileStorageApi.API.Azure.Container do
  @moduledoc false
  @behaviour FileStorageApi.Container

  import FileStorageApi.API.Azure.Base
  alias ExMicrosoftAzureStorage.Storage.Container, as: AzureContainer
  alias FileStorageApi.{Container, File}

  @impl true
  def create(container_name, options \\ %{}) do
    container_object = container(container_name)

    container =
      if Map.get(options, :public) do
        AzureContainer.set_container_acl_public_access_blob(container_object)
      else
        container_object
      end

    AzureContainer.create_container(container)
  end

  @impl true
  def list_files(container_name, options) do
    case AzureContainer.list_blobs(container(container_name), convert_options(options)) do
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
