defmodule FileStorageApi.API.Azure.BaseTest do
  use ExUnit.Case

  alias FileStorageApi.API.Azure.Base

  alias Azure.Storage
  alias Azure.Storage.Container

  test "module exists" do
    assert is_list(Base.module_info())
  end

  test "fetching correct storage config as non development" do
    azure_blob = Application.get_env(:file_storage_api, :azure_blob)

    assert false == Keyword.fetch!(azure_blob, :development)

    assert %Storage{
             account_name: "account_name",
             account_key: Keyword.fetch!(azure_blob, :account_key),
             endpoint_suffix: "env_suffix"
           } == Base.storage()
  end

  test "fetching correct storage config as development" do
    azure_blob = update_azure_blob(:development, true)

    on_exit(fn ->
      update_azure_blob(:development, false)
    end)

    assert true == Keyword.fetch!(azure_blob, :development)

    assert %Storage{
             account_name: "devstoreaccount1",
             account_key: "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==",
             host: "127.0.0.1",
             is_development_factory: true,
             default_endpoints_protocol: "http"
           } == Base.storage()
  end

  test "able to create a container context" do
    assert %Container{
             container_name: "block-store-container",
             storage_context: Base.storage()
           } == Base.container("block-store-container")
  end

  test "convert option key name to be compatible with library" do
    assert [maxresults: 5] == Base.convert_options(max_results: 5)
  end

  test "other options should still be around" do
    assert [maxresults: 5, marker: ""] == Base.convert_options(max_results: 5, marker: "")
  end

  defp update_azure_blob(key, value) do
    azure_blob = Application.get_env(:file_storage_api, :azure_blob)
    azure_blob = Keyword.put(azure_blob, key, value)
    Application.put_env(:file_storage_api, :azure_blob, azure_blob)
    azure_blob
  end
end
