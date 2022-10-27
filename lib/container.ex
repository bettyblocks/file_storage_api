defmodule FileStorageApi.Container do
  @moduledoc """
  Module for handling asset containers
  """

  import FileStorageApi.Base

  alias FileStorageApi.API.Azure.Container, as: AzureContainer
  alias FileStorageApi.API.S3.Container, as: S3Container

  @type t :: %__MODULE__{
          name: String.t(),
          files: [FileStorageApi.File.t()],
          max_results: non_neg_integer,
          next_marker: String.t(),
          date: DateTime.t()
        }
  @callback create(String.t(), atom, map) :: {:ok, map} | {:error, map}
  @type options :: [{:max_results, non_neg_integer} | {:marker, String.t()}]
  @callback list_files(String.t(), atom, options) :: {:ok, [__MODULE__.t()]} | {:error, map}

  defstruct name: nil, files: [], max_results: nil, next_marker: nil, date: nil

  @doc """
  Will create container with binary as input for bucket name

  Opts allows for setting cors_policy as map or true will only be applied to S3
  """
  @spec create(String.t(), map) :: any
  def create(container_name, opts \\ %{}) do
    connection_name =
      if Map.has_key?(opts, :container_name) do
        opts[:container_name]
      else
        :default
      end

    module_container =
      case storage_engine(connection_name) do
        :s3 ->
          S3Container

        :mock ->
          FileStorageApi.API.Mock.Container

        :azure ->
          AzureContainer
      end

    module_container.create(container_name, connection_name, opts)
  end

  @doc """
  List all files in the container.

  Options are available for max_results: which can be adjusted.

  It's build around stream so will automatically use the markers to get as many items as are  in the bucket.
  """
  @spec list_files(String.t(), options) :: Enumerable.t()
  def list_files(container_name, options \\ []) do
    filtered_options =
      if Keyword.has_key?(options, :max_results) do
        [max_results: Keyword.fetch!(options, :max_results)]
      else
        []
      end

    connection_name = Keyword.get(options, :connection_name, :default)

    module_container =
      case storage_engine(connection_name) do
        :s3 ->
          S3Container

        :mock ->
          FileStorageApi.API.Mock.Container

        :azure ->
          AzureContainer
      end

    Stream.resource(
      fn -> module_container.list_files(container_name, connection_name, options) end,
      fn
        {:ok, %{files: files, next_marker: ""}} ->
          {files, :eos}

        {:ok, %{files: files, next_marker: next_marker}} ->
          {files,
           module_container.list_files(container_name, connection_name, [marker: next_marker] ++ filtered_options)}

        :eos ->
          {:halt, :eos}
      end,
      fn :eos ->
        :ok
      end
    )
  end
end
