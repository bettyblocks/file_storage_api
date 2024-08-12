defmodule FileStorageApi.API.S3.FileTest do
  use ExUnit.Case

  import Mox

  alias FileStorageApi.API.S3.File

  setup :verify_on_exit!

  test "module exists" do
    assert is_list(File.module_info())
  end

  describe "use atom key for env config" do
    test "able to create a public url for files" do
      {:ok, url} =
        File.public_url(
          "block-store-container",
          "test.png",
          start_time: Timex.now(),
          expire_time: Timex.add(Timex.now(), Timex.Duration.from_days(1)),
          connection: :default
        )

      uri = URI.parse(url)

      assert "/block-store-container/test.png" == uri.path
    end

    test "able to create a public url for files also works with / at start" do
      {:ok, url} =
        File.public_url(
          "block-store-container",
          "/test.png",
          start_time: Timex.now(),
          expire_time: Timex.add(Timex.now(), Timex.Duration.from_days(1)),
          connection: :default
        )

      uri = URI.parse(url)

      assert "/block-store-container/test.png" == uri.path
    end

    test "timestamps should be correctly set in url" do
      start_time = Timex.now()
      expire_time = Timex.add(Timex.now(), Timex.Duration.from_hours(1))

      {:ok, url} =
        File.public_url("block-store-container", "test.png",
          start_time: start_time,
          expire_time: expire_time,
          connection: :default
        )

      uri = URI.parse(url)

      %{"X-Amz-Expires" => "3600"} = URI.decode_query(uri.query)
    end

    test "delete bucket operation" do
      path = "awesome/test.png"

      expect(AwsMock, :request, fn operation, _config ->
        assert %{http_method: :delete, path: ^path} = operation
        {:ok, %{}}
      end)

      assert {:ok, %{}} == File.delete("block-store-container", path, :default)
    end

    test "upload a file with mime type" do
      file_path = "./test/support/test_icon.png"

      expect(AwsMock, :request, fn operation, _config ->
        assert %{http_method: :put, path: "test_icon.png", headers: %{"content-type" => "image/png"}} = operation
        {:ok, %{status_code: 200}}
      end)

      assert {:ok, Path.basename(file_path)} ==
               File.upload("block-store-container", :default, file_path, nil, content_type: "image/png")
    end

    test "failing upload should return error tuple" do
      file_path = "./test/support/test_icon.png"

      expect(AwsMock, :request, fn operation, _config ->
        assert %{http_method: :put, path: "test_icon.png", headers: %{"content-type" => "image/png"}} = operation
        {:error, %{status_code: 400}}
      end)

      assert {:error, %{}} = File.upload("block-store-container", :default, file_path, nil, content_type: "image/png")
    end

    test "should be able to correctly convert modified at" do
      file = %FileStorageApi.File{
        name: "test.png",
        properties: %{key: "test.png", other: "waat", last_modified: "2021-08-19T15:17:22.775Z"}
      }

      assert {:ok, ~U[2021-08-19 15:17:22.775Z]} == File.last_modified(file)
    end
  end

  describe "use config map" do
    @connection %{
      engine: Mock,
      config: %{host: "test.docker", secret_key: "test123", access_key: "amazing", scheme: "http://"}
    }

    test "able to create a public url for files" do
      {:ok, url} =
        File.public_url(
          "block-store-container",
          "test.png",
          start_time: Timex.now(),
          expire_time: Timex.add(Timex.now(), Timex.Duration.from_days(1)),
          connection: @connection
        )

      uri = URI.parse(url)

      assert "/block-store-container/test.png" == uri.path
      assert "test.docker" == uri.host
      assert uri.query =~ "AWS4-HMAC-SHA256"
    end

    test "able to create a public url for files also works with / at start" do
      {:ok, url} =
        File.public_url(
          "block-store-container",
          "/test.png",
          start_time: Timex.now(),
          expire_time: Timex.add(Timex.now(), Timex.Duration.from_days(1)),
          connection: @connection
        )

      uri = URI.parse(url)

      assert "/block-store-container/test.png" == uri.path
      assert "test.docker" == uri.host
    end

    test "timestamps should be correctly set in url" do
      start_time = Timex.now()
      expire_time = Timex.add(Timex.now(), Timex.Duration.from_hours(1))

      {:ok, url} =
        File.public_url("block-store-container", "test.png",
          start_time: start_time,
          expire_time: expire_time,
          connection: @connection
        )

      uri = URI.parse(url)

      %{"X-Amz-Expires" => "3600"} = URI.decode_query(uri.query)
    end

    test "delete bucket operation" do
      path = "awesome/test.png"

      expect(AwsMock, :request, fn operation, _config ->
        assert %{http_method: :delete, path: ^path} = operation
        {:ok, %{}}
      end)

      assert {:ok, %{}} == File.delete("block-store-container", path, @connection)
    end

    test "upload a file with mime type" do
      file_path = "./test/support/test_icon.png"

      expect(AwsMock, :request, fn operation, _config ->
        assert %{http_method: :put, path: "test_icon.png", headers: %{"content-type" => "image/png"}} = operation
        {:ok, %{status_code: 200}}
      end)

      assert {:ok, Path.basename(file_path)} ==
               File.upload("block-store-container", @connection, file_path, nil, content_type: "image/png")
    end

    test "failing upload should return error tuple" do
      file_path = "./test/support/test_icon.png"

      expect(AwsMock, :request, fn operation, _config ->
        assert %{http_method: :put, path: "test_icon.png", headers: %{"content-type" => "image/png"}} = operation
        {:error, %{status_code: 400}}
      end)

      assert {:error, %{}} =
               File.upload("block-store-container", @connection, file_path, nil, content_type: "image/png")
    end

    test "signing with external host will replace the host" do
      {:ok, url} =
        File.public_url(
          "block-store-container",
          "test.png",
          start_time: Timex.now(),
          expire_time: Timex.add(Timex.now(), Timex.Duration.from_days(1)),
          connection: put_in(@connection, [:config, :external_host], "example.com")
        )

      uri = URI.parse(url)

      assert "/block-store-container/test.png" == uri.path
      assert "example.com" == uri.host
    end

    test "signing with public removes the signature" do
      {:ok, url} =
        File.public_url(
          "block-store-container",
          "test.png",
          start_time: Timex.now(),
          expire_time: Timex.add(Timex.now(), Timex.Duration.from_days(1)),
          connection: @connection,
          public: true
        )

      uri = URI.parse(url)

      assert "/block-store-container/test.png" == uri.path
      assert "test.docker" == uri.host
      assert is_nil(uri.query)
    end
  end
end
