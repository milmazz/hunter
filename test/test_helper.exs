ExUnit.start()
Mox.defmock(Hunter.ApiMock, for: Hunter.Api)
Application.put_env(:hunter, :hunter_api, Hunter.ApiMock)

ExUnit.after_suite(fn _ ->
  "../tmp"
  |> Path.expand(__DIR__)
  |> File.rm_rf()
end)
