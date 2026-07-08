ExUnit.start(exclude: [:integration])
Mox.defmock(Hunter.ApiMock, for: Hunter.Api)
Application.put_env(:hunter, :hunter_api, Hunter.ApiMock)
Application.put_env(:hunter, :req_options, plug: {Req.Test, Hunter.ReqStub})

ExUnit.after_suite(fn _ ->
  "../tmp"
  |> Path.expand(__DIR__)
  |> File.rm_rf()
end)
