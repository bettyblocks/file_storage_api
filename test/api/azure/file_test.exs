defmodule FileStorageApi.API.Azure.FileTest do
  use ExUnit.Case

  alias FileStorageApi.API.Azure.File

  test "module exists" do
    assert is_list(File.module_info())
  end

  test "able to create a public url for files" do
    {:ok, url} =
      File.public_url(
        "block-store-container",
        "test.png",
        Timex.now(),
        Timex.add(Timex.now(), Timex.Duration.from_days(1)),
        :default
      )

    uri = URI.parse(url)

    assert "/block-store-container/test.png" == uri.path
  end

  test "timestamps should be correctly set in url" do
    start_time = Timex.now()
    expire_time = Timex.add(Timex.now(), Timex.Duration.from_hours(1))
    {:ok, url} = File.public_url("block-store-container", "test.png", start_time, expire_time, :default)
    uri = URI.parse(url)

    start_time_str = Timex.format!(start_time, "{YYYY}-{0M}-{0D}T{0h24}:{0m}:{0s}Z")
    expire_time_str = Timex.format!(expire_time, "{YYYY}-{0M}-{0D}T{0h24}:{0m}:{0s}Z")

    %{"se" => ^expire_time_str, "st" => ^start_time_str} = URI.decode_query(uri.query)
  end

  test "should be able to correctly convert modified at" do
    file = %FileStorageApi.File{
      name: "test.png",
      properties: %{key: "test.png", other: "waat", last_modified: ~U[2021-08-19 15:17:22.775Z]}
    }

    assert {:ok, ~U[2021-08-19 15:17:22.775Z]} == File.last_modified(file)
  end
end
