defmodule Hunter.Api.RequestTest do
  use ExUnit.Case, async: true

  alias Hunter.Api.Request

  describe "process_request_body/1" do
    test "empty payload becomes an empty JSON object" do
      assert Request.process_request_body([]) == "{}"
    end

    test "multipart payloads pass through untouched" do
      payload = {:multipart, [{:file, "/tmp/image.png"}]}
      assert Request.process_request_body(payload) == payload
    end

    test "binary payloads pass through untouched" do
      assert Request.process_request_body(~s({"status":"hi"})) == ~s({"status":"hi"})
    end

    test "maps are JSON-encoded" do
      assert Request.process_request_body(%{status: "hi"}) == ~s({"status":"hi"})
    end
  end

  describe "process_request_header/1" do
    test "sets JSON content-type and accept defaults" do
      headers = Request.process_request_header([])

      assert headers[:"Content-Type"] == "application/json"
      assert headers[:Accept] == "Application/json; Charset=utf-8"
    end

    test "caller headers are preserved and win over defaults" do
      headers =
        Request.process_request_header(
          Authorization: "Bearer 123",
          "Content-Type": "multipart/form-data"
        )

      assert headers[:Authorization] == "Bearer 123"
      assert headers[:"Content-Type"] == "multipart/form-data"
    end
  end

  describe "handle_response/1" do
    test "2xx responses return the body" do
      assert Request.handle_response({:ok, %{status_code: 200, body: "ok"}}) == {:ok, "ok"}
      assert Request.handle_response({:ok, %{status_code: 204, body: ""}}) == {:ok, ""}
    end

    test "non-2xx responses return the body as error" do
      body = ~s({"error":"Record not found"})
      assert Request.handle_response({:ok, %{status_code: 404, body: body}}) == {:error, body}
    end

    test "transport errors return the reason" do
      assert Request.handle_response({:error, %HTTPoison.Error{reason: :econnrefused}}) ==
               {:error, :econnrefused}
    end
  end
end
