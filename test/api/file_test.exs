defmodule FileStorageApi.FileTest do
  use ExUnit.Case

  alias FileStorageApi.File

  import Mox

  setup :verify_on_exit!

  test "module exists" do
    assert is_list(File.module_info())
  end

  test "able to upload a file" do
    expect(FileStorageApi.API.Mock.File, :upload, fn "block-store-container", "testfile", _blob_name ->
      {:ok, %{}}
    end)

    assert {:ok, %{}} == File.upload("block-store-container", "testfile", "testfile")
  end

  test "able to request public url without setting expire" do
    expect(FileStorageApi.API.Mock.File, :public_url, fn container_name, filename, start_time, expire_time ->
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

    expect(FileStorageApi.API.Mock.File, :public_url, fn container_name, filename, start_time, expire_time ->
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
