defmodule Hunter.AttachmentTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Attachment

  @conn Hunter.Client.new(base_url: "https://example.com", access_token: "123456")

  setup :verify_on_exit!

  test "uploads a media file" do
    expect(Hunter.ApiMock, :upload_media, fn %Hunter.Client{}, "image.png", [] ->
      %Attachment{id: "22345792", type: "image"}
    end)

    assert %Attachment{type: "image"} = Attachment.upload_media(@conn, "image.png")
  end
end
