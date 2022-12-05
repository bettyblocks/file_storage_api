defmodule FileStorageApi.File do
  @moduledoc """
  Module for uploading deleting and fetching url of file
  """

  import FileStorageApi.Base

  @type t :: %__MODULE__{name: String.t(), properties: map}
  @callback upload(String.t(), atom, String.t(), String.t()) ::
              {:ok, String.t()} | {:file_upload_error, map | tuple}
  @callback delete(String.t(), String.t(), atom) :: {:ok, map} | {:error, map}
  @callback public_url(String.t(), String.t(), DateTime.t(), DateTime.t(), atom) ::
              {:ok, String.t()} | {:error, String.t()}
  @callback last_modified(t, atom) :: {:ok, DateTime.t()} | {:error, atom}

  defstruct name: nil, properties: %{}

  @doc """
  Function to upload file has input args
  container_name: name of the container
  filename: path to the file with the data to store
  blob_name: how the blob is going to be called after storage

  Option field is available that has options for missing container fallback
  force_container: with false you can disable auto creation of container
  public: with public on true it will create bucket by default as public
  cors_policy: can have true or a configuration for configuring cors settings of bucket

  Returns reference to the file in the asset store
  """
  @spec upload(String.t(), String.t(), String.t(), keyword) ::
          {:ok, String.t()} | {:file_upload_error, map | tuple}
  def upload(container_name, filename, blob_name, opts \\ []) do
    force_container = Keyword.get(opts, :force_container, true)
    connection_name = Keyword.get(opts, :connection, :default)

    case {api_module(connection_name, File).upload(container_name, connection_name, filename, blob_name),
          force_container} do
      {{:ok, file}, _} ->
        {:ok, file}

      {{:error, :container_not_found}, true} ->
        container_options = Keyword.take(opts, [:cors_policy, :public])
        api_module(connection_name, Container).create(container_name, connection_name, Map.new(container_options))
        upload(container_name, filename, blob_name, Keyword.put(opts, :force_container, false))

      {{:error, error}, _} ->
        {:file_upload_error, error}
    end
  end

  @doc """
  Function to delete files

  Has 2 inputs
  container_name: name of container file is stored in
  filename: reference path of the file stored in the container
  """
  @spec delete(String.t(), String.t(), atom) :: {:ok, map} | {:error, map}
  def delete(container_name, filename, connection_name \\ :default) do
    api_module(connection_name, Container).delete(container_name, filename)
  end

  @doc """
  public_url returns an full url to be able to fetch the file with security tokens needed by default 1 day valid
  """
  @spec public_url(String.t(), String.t(), DateTime.t(), DateTime.t(), atom) ::
          {:ok, String.t()} | {:error, String.t()}
  def public_url(
        container_name,
        file_path,
        start_time \\ Timex.now(),
        expire_time \\ Timex.add(Timex.now(), Timex.Duration.from_days(1)),
        connection_name \\ :default
      ) do
    api_module(connection_name, File).public_url(container_name, file_path, start_time, expire_time, connection_name)
  end

  def last_modified(file, connection_name \\ :default) do
    api_module(connection_name, File).last_modified(file, connection_name)
  end

  @doc """
  This function will create a temporary file and upload to asset store

  Opts field described at the upload function
  """
  @spec upload_file_from_content(binary, binary, binary | iodata, binary, keyword) ::
          {:ok, String.t()} | {:file_upload_error, map | tuple}
  def upload_file_from_content(filename, container_name, content, blob_name, opts \\ []) do
    Temp.track!()
    {:ok, dir_path} = Temp.mkdir("file-cache")
    file_path = Path.join(dir_path, filename)
    File.write(file_path, content)
    upload(container_name, file_path, blob_name, opts)
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

  def mime_type(filename) do
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
        to_string(file_mime_type)
    end
  end
end
