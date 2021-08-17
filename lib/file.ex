defmodule FileStorageApi.File do
  @moduledoc """
  Module for file handling
  """

  @type t :: %__MODULE__{name: String.t(), properties: map}
  @callback upload(String.t(), String.t(), String.t()) :: {:ok, String.t()} | {:error, map}
  @callback delete(String.t(), String.t()) :: {:ok, map} | {:error, map}
  @callback public_url(String.t(), String.t(), DateTime.t(), DateTime.t()) :: {:ok, String.t()} | {:error, String.t()}

  defstruct name: nil, properties: %{}

  import FileStorageApi.Base

  @spec upload(String.t(), String.t(), String.t()) :: {:ok, String.t()} | {:error, map}
  def upload(container_name, filename, blob_name) do
    case api_module(File).upload(container_name, filename, blob_name) do
      {:ok, file} -> {:ok, file}
      {:error, error} -> {:file_upload_error, error}
    end
  end

  @spec delete(String.t(), String.t()) :: {:ok, map} | {:error, map}
  def delete(container_name, filename) do
    api_module(File).delete(container_name, filename)
  end

  @spec public_url(String.t(), String.t(), DateTime.t(), DateTime.t()) :: {:ok, String.t()} | {:error, String.t()}
  def public_url(
        container_name,
        file_path,
        start_time \\ Timex.now(),
        expire_time \\ Timex.add(Timex.now(), Timex.Duration.from_days(1))
      ) do
    api_module(File).public_url(container_name, file_path, start_time, expire_time)
  end

  @spec upload_file_from_content(binary, binary, binary, binary) :: {:ok, String.t()} | {:error, map}
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
