defmodule FileStorageApi.API.S3.Container do
  @moduledoc false
  @behaviour FileStorageApi.Container

  import FileStorageApi.API.S3.Base
  import FileStorageApi.Base

  alias ExAws.S3
  alias FileStorageApi.Container
  alias FileStorageApi.File

  @impl true
  def create(container_name, connection, options \\ %{}) do
    result =
      container_name
      |> S3.put_bucket(region(config(connection)))
      |> request(connection)

    case result do
      {:ok, result} ->
        public = read_from_map(options, :public, false)
        cors_policy = read_from_map(options, :cors_policy, false)

        public &&
          container_name
          |> put_public_policy()
          |> request(connection)

        (is_list(cors_policy) || cors_policy == true) &&
          container_name
          |> put_cors(cors_policy)
          |> request(connection)

        {:ok, result}

      error ->
        error
    end
  end

  @impl true
  def list_files(container_name, connection, options) do
    container_name
    |> S3.list_objects(convert_options(options))
    |> request(connection)
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

  @spec put_public_policy(String.t()) :: ExAws.Operation.t()
  defp put_public_policy(bucket_name) do
    bucket_name
    |> S3.put_bucket_policy(policy(bucket_name))
  end

  defp policy(bucket_name) do
    Jason.encode!(%{
      Version: "2012-10-17",
      Statement: [
        %{
          Sid: "AddPerm",
          Effect: "Allow",
          Principal: "*",
          Action: [
            "s3:GetObject"
          ],
          Resource: "arn:aws:s3:::#{bucket_name}/*"
        }
      ]
    })
  end

  defp put_cors(bucket, cors_policy) do
    cors =
      case cors_policy do
        true ->
          [
            %{
              allowed_methods: ["GET"],
              allowed_origins: ["*"],
              allowed_headers: ["*"],
              max_age_seconds: 3000
            }
          ]

        cors_rules ->
          cors_rules
      end

    bucket
    |> S3.put_bucket_cors(cors)
  end
end
