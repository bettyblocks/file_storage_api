defmodule FileStorageApi.API.S3.ContainerTest do
  use ExUnit.Case

  import Mox

  alias FileStorageApi.API.S3.Container

  setup :verify_on_exit!

  test "module exists" do
    assert is_list(Container.module_info())
  end

  test "able to create the bucket operation" do
    expect(AwsMock, :request, fn operation, _config ->
      assert %{http_method: :put, path: "/", bucket: "block-store-container"} = operation
      {:ok, %{}}
    end)

    assert {:ok, %{}} == Container.create()
  end

  test "be able to list files and correctly convert them" do
    expect(AwsMock, :request, fn operation, _config ->
      assert %{http_method: :get, path: "/", bucket: "block-store-container"} = operation
      {:ok, %{body: %{contents: [%{key: "test.png", other: "waat"}], max_keys: 50, next_marker: ""}}}
    end)

    assert {:ok,
            %FileCachingService.Storage.Container{
              date: nil,
              files: [
                %FileStorageApi.File{name: "test.png", properties: %{key: "test.png", other: "waat"}}
              ],
              max_results: 50,
              name: nil,
              next_marker: ""
            }} == Container.list_files([])
  end

  test "errors should be returned" do
    expect(AwsMock, :request, fn operation, _config ->
      assert %{http_method: :get, path: "/", bucket: "block-store-container"} = operation
      {:error, %{status_code: 400}}
    end)

    assert {:error, %{}} = Container.list_files([])
  end
end
