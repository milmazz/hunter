defmodule Hunter.AttachmentTest do
  use Hunter.ReqCase, async: true

  alias Hunter.Attachment

  @conn Hunter.Client.new(base_url: "https://mastodon.example", access_token: "123456")

  @tag :tmp_dir
  test "uploads a media file as multipart form data", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "image.png")
    File.write!(file, "fake png bytes")

    stub_request(fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/v2/media"

      [ct] = Plug.Conn.get_req_header(conn, "content-type")
      assert ct =~ "multipart/form-data"

      {:ok, body, _conn} = Plug.Conn.read_body(conn)
      assert body =~ "image.png"
      assert body =~ ~s(name="description")
      assert body =~ "a test upload"

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

    assert Attachment.delete_media(@conn, 22_345_792)
  end

  test "API errors raise Hunter.Error" do
    stub_request(fn conn ->
      respond_with(conn, %{error: "Record not found"}, 404)
    end)

    assert_raise Hunter.Error, fn -> Attachment.media_attachment(@conn, 0) end
  end
end
