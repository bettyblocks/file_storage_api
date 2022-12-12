defmodule FileStorageApi.FileTest do
  use ExUnit.Case

  alias FileStorageApi.API.Mock.Container, as: ContainerMock
  alias FileStorageApi.API.Mock.File, as: FileMock
  alias FileStorageApi.File

  import Mox

  setup :verify_on_exit!

  test "module exists" do
    assert is_list(File.module_info())
  end

  test "able to upload a file" do
    file_path = "./test/support/test_icon.png"

    expect(FileMock, :upload, fn "block-store-container", :default, ^file_path, _blob_name, _ ->
      {:ok, %{}}
    end)

    assert {:ok, %{}} == File.upload("block-store-container", file_path, "testfile")
  end

  test "upload a file with mime type" do
    file_path = "./test/support/test_icon.png"

    expect(FileMock, :upload, fn "block-store-container", :default, _, filename, [content_type: "image/png"] ->
      {:ok, filename}
    end)

    assert {:ok, Path.basename(file_path)} ==
             File.upload("block-store-container", file_path, "test_icon.png")
  end

  test "upload a file with mime type application/javascript" do
    file_path = "./test/support/hello.js"

    expect(FileMock, :upload, fn "block-store-container", :default, _, filename, [content_type: "text/javascript"] ->
      {:ok, filename}
    end)

    assert {:ok, Path.basename(file_path)} == File.upload("block-store-container", file_path, "hello.js")
  end

  test "not creating a container if not forcing on a failed upload" do
    file_path = "./test/support/hello.js"

    FileMock
    |> expect(:upload, 1, fn "block-store-container", :default, _file_path, "testfile", _ ->
      {:error, "Some Error"}
    end)

    assert {:file_upload_error, "Some Error"} ==
             File.upload("block-store-container", file_path, "testfile", force_container: false)
  end

  test "creating a container once, if file upload fails because of it" do
    file_path = "./test/support/hello.js"

    FileMock
    |> expect(:upload, 1, fn "block-store-container", :default, ^file_path, _blob_name, _ ->
      {:error, :container_not_found}
    end)
    |> expect(:upload, 1, fn "block-store-container", :default, ^file_path, _blob_name, _ ->
      {:ok, "file uploaded!"}
    end)

    ContainerMock
    |> expect(:create, 1, fn "block-store-container", :default, _ ->
      {:ok, %{}}
    end)

    assert {:ok, "file uploaded!"} == File.upload("block-store-container", file_path, "testfile")
  end

  test "returning the error if creating container didn't help" do
    file_path = "./test/support/hello.js"

    FileMock
    |> expect(:upload, 2, fn "block-store-container", :default, ^file_path, _blob_name, _ ->
      {:error, :container_not_found}
    end)

    ContainerMock
    |> expect(:create, 1, fn "block-store-container", :default, _ ->
      {:ok, %{}}
    end)

    assert {:file_upload_error, :container_not_found} == File.upload("block-store-container", file_path, "testfile")
  end

  test "able to request public url without setting expire" do
    expect(FileMock, :public_url, fn container_name, filename, start_time, expire_time, :default ->
      start_time_str = Timex.format!(start_time, "{YYYY}-{0M}-{0D}T{0h24}:{0m}:{0s}Z")
      expire_time_str = Timex.format!(expire_time, "{YYYY}-{0M}-{0D}T{0h24}:{0m}:{0s}Z")

      "http://test.test/#{container_name}/#{filename}?st=#{start_time_str}&et=#{expire_time_str}"
    end)

    assert String.starts_with?(
             File.public_url("test-container", "test.png"),
             "http://test.test/test-container/test.png"
           )
  end

  test "able to request public url with custom expire" do
    start_time = Timex.now()
    expire_time = Timex.add(Timex.now(), Timex.Duration.from_hours(1))

    expect(FileMock, :public_url, fn container_name, filename, start_time, expire_time, :default ->
      start_time_str = Timex.format!(start_time, "{YYYY}-{0M}-{0D}T{0h24}:{0m}:{0s}Z")
      expire_time_str = Timex.format!(expire_time, "{YYYY}-{0M}-{0D}T{0h24}:{0m}:{0s}Z")

      "http://test.test/#{container_name}/#{filename}?st=#{start_time_str}&et=#{expire_time_str}"
    end)

    start_time_str = Timex.format!(start_time, "{YYYY}-{0M}-{0D}T{0h24}:{0m}:{0s}Z")
    expire_time_str = Timex.format!(expire_time, "{YYYY}-{0M}-{0D}T{0h24}:{0m}:{0s}Z")

    assert "http://test.test/test-container/test.png?st=#{start_time_str}&et=#{expire_time_str}" ==
             File.public_url("test-container", "test.png", start_time, expire_time)
  end
end
