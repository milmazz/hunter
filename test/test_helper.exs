ExUnit.start()
Mox.defmock(Hunter.ApiMock, for: Hunter.Api)
Application.put_env(:hunter, :hunter_api, Hunter.ApiMock)
