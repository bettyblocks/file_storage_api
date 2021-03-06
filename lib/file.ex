defmodule FileStorageApi.File do
  @moduledoc """
  Module for uploading deleting and fetching url of file
  """

  @type t :: %__MODULE__{name: String.t(), properties: map}
  @callback upload(String.t(), String.t(), String.t()) :: {:ok, String.t()} | {:file_upload_error, map | tuple}
  @callback delete(String.t(), String.t()) :: {:ok, map} | {:error, map}
  @callback public_url(String.t(), String.t(), DateTime.t(), DateTime.t()) :: {:ok, String.t()} | {:error, String.t()}
  @callback last_modified(t) :: {:ok, DateTime.t()} | {:error, atom}

  defstruct name: nil, properties: %{}

  import FileStorageApi.Base

  @spec upload(String.t(), String.t(), String.t()) :: {:ok, String.t()} | {:file_upload_error, map | tuple}
  @doc """
  Function to upload file has input args
  container_name: name of the container
  filename: path to the file with the data to store
  blob_name: how the blob is going to be called after storage

  Returns reference to the file in the asset store
  """
  def upload(container_name, filename, blob_name, opts \\ []) do
    force_container = Keyword.get(opts, :force_container, true)

    case {api_module(File).upload(container_name, filename, blob_name), force_container} do
      {{:ok, file}, _} -> {:ok, file}
      {{:error, :container_not_found}, true} ->
        api_module(Container).create(container_name, %{})
        upload(container_name, filename, blob_name, Keyword.put(opts, :force_container, false))

      {{:error, error}, _} -> {:file_upload_error, error}
    end
  end

  @spec delete(String.t(), String.t()) :: {:ok, map} | {:error, map}
  @doc """
  Function to delete files

  Has 2 inputs
  container_name: name of container file is stored in
  filename: reference path of the file stored in the container
  """
  def delete(container_name, filename) do
    api_module(File).delete(container_name, filename)
  end

  @spec public_url(String.t(), String.t(), DateTime.t(), DateTime.t()) :: {:ok, String.t()} | {:error, String.t()}
  @doc """
  public_url returns an full url to be able to fetch the file with security tokens needed by default 1 day valid
  """
  def public_url(
        container_name,
        file_path,
        start_time \\ Timex.now(),
        expire_time \\ Timex.add(Timex.now(), Timex.Duration.from_days(1))
      ) do
    api_module(File).public_url(container_name, file_path, start_time, expire_time)
  end

  def last_modified(file), do: api_module(File).last_modified(file)

  @spec upload_file_from_content(binary, binary, binary | iodata, binary) ::
          {:ok, String.t()} | {:file_upload_error, map | tuple}
  @doc """
  This function will create a temporary file and upload to asset store
  """
  def upload_file_from_content(filename, container_name, content, blob_name) do
    Temp.track!()
    {:ok, dir_path} = Temp.mkdir("file-cache")
    file_path = Path.join(dir_path, filename)
    File.write(file_path, content)
    upload(container_name, file_path, blob_name)
  after
    Temp.cleanup()
  end

  @spec sanitize(binary) :: binary
  def sanitize(name) do
    name
    |> String.trim()
    |> Recase.to_kebab()
    |> String.replace(~r/[^0-9a-z\-]/u, "")
    |> String.trim("-")
  end
end
