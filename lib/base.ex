defmodule FileStorageApi.Base do
  @moduledoc false
  def api_module(module) when module in [Container, File] do
    Module.concat([FileStorageApi.API, storage_engine(), module])
  end

  defp storage_engine do
    :file_storage_api
    |> Application.get_env(:storage_api)
    |> Keyword.get(:engine)
  end
end
