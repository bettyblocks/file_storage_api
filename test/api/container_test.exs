defmodule FileStorageApi.ContainerTest do
  use ExUnit.Case

  alias FileStorageApi.API.Mock.Container, as: MockContainer
  alias FileStorageApi.{Container, File}

  import Mox

  setup :verify_on_exit!

  test "module exists" do
    assert is_list(Container.module_info())
  end

  describe "connection atom key test" do
    test "listing files returns a function" do
      assert is_function(Container.list_files("test-container", []))
    end

    test "listing files" do
      expect(MockContainer, :list_files, fn container_name, :default, _options ->
        assert container_name == "test-container"

        {:ok,
         %Container{
           max_results: "5000",
           next_marker: "",
           date: Timex.now(),
           files: [%File{name: "test.jpg"}]
         }}
      end)

      assert [%File{name: "test.jpg", properties: %{}}] ==
               Enum.map(Container.list_files("test-container", []), & &1)
    end

    test "be able to list files on multiple pages" do
      expect(MockContainer, :list_files, 2, fn
        container_name, :default, [marker: "next_marker"] ->
          assert container_name == "test-container"

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

        container_name, :default, _options ->
          assert container_name == "test-container"

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
             ] == Enum.map(Container.list_files("test-container", []), & &1)
    end

    test "able to create the container" do
      expect(MockContainer, :create, fn "block-store-container", :default, %{} ->
        {:ok, %{}}
      end)

      assert {:ok, %{}} == Container.create("block-store-container")
    end

    test "able to delete the container" do
      expect(MockContainer, :delete, fn "block-store-container", :default ->
        {:ok, %{}}
      end)

      assert {:ok, %{}} == Container.delete("block-store-container")
    end

    test "delete errors should be returned" do
      expect(MockContainer, :delete, fn "block-store-container", :default ->
        {:error, %{status_code: 404, body: "NoSuchBucket"}}
      end)

      assert {:error, %{status_code: 404, body: "NoSuchBucket"}} = Container.delete("block-store-container")
    end
  end

  describe "connection configmap test" do
    @connection %{
      engine: Mock,
      config: %{host: "test.docker"}
    }

    test "listing files returns a function" do
      assert is_function(Container.list_files("test-container", connection: @connection))
    end

    test "listing files" do
      expect(MockContainer, :list_files, fn container_name, @connection, _options ->
        assert container_name == "test-container"

        {:ok,
         %Container{
           max_results: "5000",
           next_marker: "",
           date: Timex.now(),
           files: [%File{name: "test.jpg"}]
         }}
      end)

      assert [%File{name: "test.jpg", properties: %{}}] ==
               Enum.map(Container.list_files("test-container", connection: @connection), & &1)
    end

    test "be able to list files on multiple pages" do
      expect(MockContainer, :list_files, 2, fn
        container_name, @connection, [marker: "next_marker"] ->
          assert container_name == "test-container"

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

        container_name, @connection, _options ->
          assert container_name == "test-container"

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
             ] == Enum.map(Container.list_files("test-container", connection: @connection), & &1)
    end

    test "able to create the container" do
      expect(MockContainer, :create, fn "block-store-container", @connection, %{} ->
        {:ok, %{}}
      end)

      assert {:ok, %{}} == Container.create("block-store-container", %{connection: @connection})
    end

    test "able to delete the container" do
      expect(MockContainer, :delete, fn "block-store-container", @connection ->
        {:ok, %{}}
      end)

      assert {:ok, %{}} == Container.delete("block-store-container", @connection)
    end

    test "delete errors should be returned" do
      expect(MockContainer, :delete, fn "block-store-container", @connection ->
        {:error, %{status_code: 404, body: "NoSuchBucket"}}
      end)

      assert {:error, %{status_code: 404, body: "NoSuchBucket"}} = Container.delete("block-store-container", @connection)
    end
  end
end
