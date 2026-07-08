ExUnit.start(exclude: [:integration])
Application.put_env(:hunter, :req_options, plug: {Req.Test, Hunter.ReqStub})

ExUnit.after_suite(fn _ ->
  "../tmp"
  |> Path.expand(__DIR__)
  |> File.rm_rf()
end)
