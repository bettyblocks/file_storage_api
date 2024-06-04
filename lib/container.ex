defmodule FileStorageApi.Container do
  @moduledoc """
  Module for handling asset containers
  """

  import FileStorageApi.Base

  @type t :: %__MODULE__{
          name: String.t(),
          files: [FileStorageApi.File.t()],
          max_results: non_neg_integer,
          next_marker: String.t(),
          date: DateTime.t()
        }
  @callback create(String.t(), atom | map, map) :: {:ok, map} | {:error, map}
  @type options :: [
          {:max_results, non_neg_integer}
          | {:marker, String.t()}
          | {:connection, atom | map | keyword}
          | {atom, term}
        ]
  @callback list_files(String.t(), atom | map, options) :: {:ok, [__MODULE__.t()]} | {:error, map}

  defstruct name: nil, files: [], max_results: nil, next_marker: nil, date: nil

  @doc """
  Will create container with binary as input for bucket name

  Opts allows for setting cors_policy as map or true will only be applied to S3
  """
  @spec create(String.t(), map) :: any
  def create(container_name, opts \\ %{}) do
    connection = read_from_map(opts, :connection, :default)

    api_module(connection, Container).create(container_name, connection, opts)
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

    connection = Keyword.get(options, :connection, :default)

    Stream.resource(
      fn -> api_module(connection, Container).list_files(container_name, connection, options) end,
      fn
        {:ok, %{files: files, next_marker: ""}} ->
          {files, :eos}

        {:ok, %{files: files, next_marker: next_marker}} ->
          {files,
           api_module(connection, Container).list_files(
             container_name,
             connection,
             [marker: next_marker] ++ filtered_options
           )}

        :eos ->
          {:halt, :eos}
      end,
      fn :eos ->
        :ok
      end
    )
  end
end
