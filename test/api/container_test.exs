defmodule FileStorageApi.ContainerTest do
  use ExUnit.Case

  alias FileStorageApi.API.Mock.Container, as: MockContainer
  alias FileStorageApi.{Container, File}

  import Mox

  setup :verify_on_exit!

  test "module exists" do
    assert is_list(Container.module_info())
  end

  test "listing files returns a function" do
    assert is_function(Container.list_files([]))
  end

  test "listing files" do
    expect(MockContainer, :list_files, fn _options ->
      {:ok,
       %Container{
         max_results: "5000",
         next_marker: "",
         date: Timex.now(),
         files: [%File{name: "test.jpg"}]
       }}
    end)

    assert [%File{name: "test.jpg", properties: %{}}] == Enum.map(Container.list_files([]), & &1)
  end

  test "be able to list files on multiple pages" do
    expect(MockContainer, :list_files, 2, fn
      [marker: "next_marker"] ->
        {:ok,
         %Container{
           files: [
             %File{
               name: "test_delete",
               properties: %{}
             }
           ],
           next_marker: ""
         }}

      _options ->
        {:ok,
         %Container{
           files: [
             %File{name: "test", properties: %{}}
           ],
           next_marker: "next_marker"
         }}
    end)

    assert [
             %File{
               name: "test",
               properties: %{}
             },
             %File{
               name: "test_delete",
               properties: %{}
             }
           ] == Enum.map(Container.list_files([]), & &1)
  end

  test "able to create the container" do
    expect(MockContainer, :create, fn "block-store-container" ->
      {:ok, %{}}
    end)

    assert {:ok, %{}} == Container.create("block-store-container")
  end
end
