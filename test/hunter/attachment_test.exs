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

  test "returns a media attachment" do
    expect(Hunter.ApiMock, :media_attachment, fn %Hunter.Client{}, 22_345_792 ->
      %Attachment{id: "22345792", type: "image", url: "https://example.com/image.png"}
    end)

    assert %Attachment{id: "22345792"} = Attachment.media_attachment(@conn, 22_345_792)
  end

  test "updates a media attachment" do
    expect(Hunter.ApiMock, :update_media, fn %Hunter.Client{}, 22_345_792, opts ->
      %Attachment{id: "22345792", description: opts[:description]}
    end)

    assert %Attachment{description: "a cat"} =
             Attachment.update_media(@conn, 22_345_792, description: "a cat")
  end

  test "deletes a media attachment" do
    expect(Hunter.ApiMock, :delete_media, fn %Hunter.Client{}, 22_345_792 -> true end)

    assert Attachment.delete_media(@conn, 22_345_792)
  end
end
