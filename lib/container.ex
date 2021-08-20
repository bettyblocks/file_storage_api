defmodule FileStorageApi.Container do
  @moduledoc """
  Module for handling asset containers
  """

  @type t :: %__MODULE__{
          name: String.t(),
          files: [FileStorageApi.File.t()],
          max_results: non_neg_integer,
          next_marker: String.t(),
          date: DateTime.t()
        }
  @callback create(String.t()) :: {:ok, map} | {:error, map}
  @type options :: [{:max_results, non_neg_integer} | {:marker, String.t()}]
  @callback list_files(String.t(), options) :: {:ok, [__MODULE__.t()]} | {:error, map}

  defstruct name: nil, files: [], max_results: nil, next_marker: nil, date: nil

  import FileStorageApi.Base

  @spec create(String.t()) :: any
  @doc """
  Will create container with binary as input for bucket name
  """
  def create(container_name) do
    api_module(Container).create(container_name)
  end

  @spec list_files(String.t(), options) :: Enumerable.t()
  @doc """
  List all files in the container.

  Options are available for max_results: which can be adjusted.

  It's build around stream so will automatically use the markers to get as many items as are  in the bucket.
  """
  def list_files(container_name, options \\ []) do
    filtered_options =
      if Keyword.has_key?(options, :max_results) do
        [max_results: Keyword.fetch!(options, :max_results)]
      else
        []
      end

    Stream.resource(
      fn -> api_module(Container).list_files(container_name, options) end,
      fn
        {:ok, %{files: files, next_marker: ""}} ->
          {files, :eos}

        {:ok, %{files: files, next_marker: next_marker}} ->
          {files, api_module(Container).list_files(container_name, [marker: next_marker] ++ filtered_options)}

        :eos ->
          {:halt, :eos}
      end,
      fn :eos ->
        :ok
      end
    )
  end
end
