defmodule Hunter.AttachmentTest do
  use Hunter.ReqCase, async: true

  alias Hunter.Attachment

  @conn Hunter.Client.new(base_url: "https://mastodon.example", access_token: "123456")

  # a real 1x1 PNG: its signature contains \r\n, which catches any body
  # encoding that mangles binary content (e.g. line-mode file streaming)
  @png Base.decode64!(
         "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
       )

  @tag :tmp_dir
  test "uploads a media file as multipart form data", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "image.png")
    File.write!(file, @png)

    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v2/media"

      [ct] = Plug.Conn.get_req_header(conn, "content-type")
      assert ct =~ "multipart/form-data"

      {:ok, body, _conn} = Plug.Conn.read_body(conn)
      assert body =~ "image.png"
      assert body =~ ~s(name="description")
      assert body =~ "a test upload"

      # the transmitted body must contain the file bytes intact and match
      # the declared content-length, or real servers hang waiting for the rest
      assert String.contains?(body, @png)
      [content_length] = Plug.Conn.get_req_header(conn, "content-length")
      assert byte_size(body) == String.to_integer(content_length)

      respond_with_fixture(conn, "attachment")
    end)

    assert %Attachment{id: "22345792", type: "image"} =
             Attachment.upload_media(@conn, file, description: "a test upload")
  end

  test "returns a media attachment" do
    stub_request(fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/api/v1/media/22345792"
      respond_with_fixture(conn, "attachment")
    end)

    assert %Attachment{id: "22345792", description: "test media"} =
             Attachment.media_attachment(@conn, 22_345_792)
  end

  test "updates a media attachment with a JSON body" do
    stub_request(fn conn ->
      assert conn.method == "PUT"
      assert conn.request_path == "/api/v1/media/22345792"
      assert %{"description" => "a cat"} = read_json_body!(conn)
      respond_with_fixture(conn, "attachment")
    end)

    assert %Attachment{id: "22345792"} =
             Attachment.update_media(@conn, 22_345_792, description: "a cat")
  end

  test "deletes a media attachment" do
    stub_request(fn conn ->
      assert conn.method == "DELETE"
      assert conn.request_path == "/api/v1/media/22345792"
      respond_with(conn, %{})
    end)

    assert Attachment.delete_media(@conn, 22_345_792) == true
  end

  test "API errors raise Hunter.Error" do
    stub_request(fn conn ->
      respond_with(conn, %{error: "Record not found"}, 404)
    end)

    assert_raise Hunter.Error, fn -> Attachment.media_attachment(@conn, 0) end
  end
end
