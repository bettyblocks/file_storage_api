defmodule FileStorageApi.API.S3.ContainerTest do
  use ExUnit.Case

  import Mox

  alias FileStorageApi.API.S3.Container

  setup :verify_on_exit!

  test "module exists" do
    assert is_list(Container.module_info())
  end

  describe "atom configuration" do
    test "able to create the bucket operation" do
      expect(AwsMock, :request, fn operation, _config ->
        assert %{http_method: :put, path: "/", bucket: "block-store-container"} = operation
        {:ok, %{}}
      end)

      assert {:ok, %{}} == Container.create("block-store-container", :default, %{})
    end

    test "able to set cors with create bucket operation" do
      expect(AwsMock, :request, 2, fn
        %{resource: ""} = operation, _ ->
          assert %{http_method: :put, path: "/", bucket: "block-store-container"} = operation
          {:ok, %{}}

        operation, _ ->
          assert %{
                   body:
                     "<CORSConfiguration><CORSRule><MaxAgeSeconds>3000</MaxAgeSeconds><AllowedOrigin>*</AllowedOrigin><AllowedMethod>GET</AllowedMethod><AllowedHeader>*</AllowedHeader></CORSRule></CORSConfiguration>",
                   resource: "cors"
                 } = operation

          {:ok, %{}}
      end)

      assert {:ok, %{}} == Container.create("block-store-container", :default, %{cors_policy: true})
    end

    test "able to set public policy with create bucket operation" do
      expect(AwsMock, :request, 2, fn
        %{resource: ""} = operation, _ ->
          assert %{http_method: :put, path: "/", bucket: "block-store-container"} = operation
          {:ok, %{}}

        operation, _ ->
          assert %{
                   body:
                     "{\"Statement\":[{\"Action\":[\"s3:GetObject\"],\"Effect\":\"Allow\",\"Principal\":\"*\",\"Resource\":\"arn:aws:s3:::block-store-container/*\",\"Sid\":\"AddPerm\"}],\"Version\":\"2012-10-17\"}",
                   resource: "policy"
                 } = operation

          {:ok, %{}}
      end)

      assert {:ok, %{}} == Container.create("block-store-container", :default, %{public: true})
    end

    test "be able to list files and correctly convert them" do
      expect(AwsMock, :request, fn operation, _config ->
        assert %{http_method: :get, path: "/", bucket: "block-store-container"} = operation
        {:ok, %{body: %{contents: [%{key: "test.png", other: "waat"}], max_keys: 50, next_marker: ""}}}
      end)

      assert {:ok,
              %FileStorageApi.Container{
                date: nil,
                files: [
                  %FileStorageApi.File{name: "test.png", properties: %{key: "test.png", other: "waat"}}
                ],
                max_results: 50,
                name: nil,
                next_marker: ""
              }} == Container.list_files("block-store-container", :default, [])
    end

    test "errors should be returned" do
      expect(AwsMock, :request, fn operation, _config ->
        assert %{http_method: :get, path: "/", bucket: "block-store-container"} = operation
        {:error, %{status_code: 400}}
      end)

      assert {:error, %{}} = Container.list_files("block-store-container", :default, [])
    end
  end

  describe "use configmap as input" do
    @connection %{
      engine: Mock,
      config: %{host: "test.docker", secret_key: "test123", access_key: "amazing", scheme: "http://"}
    }
    test "able to create the bucket operation" do
      expect(AwsMock, :request, fn operation, _config ->
        assert %{http_method: :put, path: "/", bucket: "block-store-container"} = operation
        {:ok, %{}}
      end)

      assert {:ok, %{}} == Container.create("block-store-container", @connection, %{})
    end

    test "able to set cors with create bucket operation" do
      expect(AwsMock, :request, 2, fn
        %{resource: ""} = operation, _ ->
          assert %{http_method: :put, path: "/", bucket: "block-store-container"} = operation
          {:ok, %{}}

        operation, _ ->
          assert %{
                   body:
                     "<CORSConfiguration><CORSRule><MaxAgeSeconds>3000</MaxAgeSeconds><AllowedOrigin>*</AllowedOrigin><AllowedMethod>GET</AllowedMethod><AllowedHeader>*</AllowedHeader></CORSRule></CORSConfiguration>",
                   resource: "cors"
                 } = operation

          {:ok, %{}}
      end)

      assert {:ok, %{}} == Container.create("block-store-container", @connection, %{cors_policy: true})
    end

    test "able to set public policy with create bucket operation" do
      expect(AwsMock, :request, 2, fn
        %{resource: ""} = operation, _ ->
          assert %{http_method: :put, path: "/", bucket: "block-store-container"} = operation
          {:ok, %{}}

        operation, _ ->
          assert %{
                   body:
                     "{\"Statement\":[{\"Action\":[\"s3:GetObject\"],\"Effect\":\"Allow\",\"Principal\":\"*\",\"Resource\":\"arn:aws:s3:::block-store-container/*\",\"Sid\":\"AddPerm\"}],\"Version\":\"2012-10-17\"}",
                   resource: "policy"
                 } = operation

          {:ok, %{}}
      end)

      assert {:ok, %{}} == Container.create("block-store-container", @connection, %{public: true})
    end

    test "be able to list files and correctly convert them" do
      expect(AwsMock, :request, fn operation, _config ->
        assert %{http_method: :get, path: "/", bucket: "block-store-container"} = operation
        {:ok, %{body: %{contents: [%{key: "test.png", other: "waat"}], max_keys: 50, next_marker: ""}}}
      end)

      assert {:ok,
              %FileStorageApi.Container{
                date: nil,
                files: [
                  %FileStorageApi.File{name: "test.png", properties: %{key: "test.png", other: "waat"}}
                ],
                max_results: 50,
                name: nil,
                next_marker: ""
              }} == Container.list_files("block-store-container", @connection, [])
    end

    test "errors should be returned" do
      expect(AwsMock, :request, fn operation, _config ->
        assert %{http_method: :get, path: "/", bucket: "block-store-container"} = operation
        {:error, %{status_code: 400}}
      end)

      assert {:error, %{}} = Container.list_files("block-store-container", @connection, [])
    end
  end
end
