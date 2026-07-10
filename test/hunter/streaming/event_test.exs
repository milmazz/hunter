defmodule Hunter.Streaming.EventTest do
  use ExUnit.Case, async: true

  alias Hunter.Streaming.Event

  test "parses an update into a Status" do
    assert {:ok, event} = Event.parse(frame("update", fixture("status")))

    assert %Event{streams: ["user"], type: "update"} = event
    assert %Hunter.Status{id: "103270115826048975", visibility: "public"} = event.payload
    assert %Hunter.Account{username: "milmazz"} = event.payload.account
  end

  test "parses a status.update into a Status" do
    assert {:ok, %Event{type: "status.update", payload: %Hunter.Status{}}} =
             Event.parse(frame("status.update", fixture("status")))
  end

  test "parses a notification into a Notification" do
    assert {:ok, %Event{type: "notification", payload: payload}} =
             Event.parse(frame("notification", fixture("notification")))

    assert %Hunter.Notification{type: "mention"} = payload
  end

  test "parses a conversation into a Conversation" do
    assert {:ok, %Event{payload: %Hunter.Conversation{id: "418450"}}} =
             Event.parse(frame("conversation", fixture("conversation")))
  end

  test "parses an announcement into an Announcement" do
    assert {:ok, %Event{payload: %Hunter.Announcement{id: "8"}}} =
             Event.parse(frame("announcement", fixture("announcement")))
  end

  test "parses an announcement.reaction into a Reaction" do
    payload = ~s({"name": "bongoCat", "count": 9, "announcement_id": "8"})

    assert {:ok, %Event{payload: %Hunter.Announcement.Reaction{name: "bongoCat", count: 9}}} =
             Event.parse(frame("announcement.reaction", payload))
  end

  test "delete and announcement.delete carry the id string" do
    assert {:ok, %Event{payload: "103270115826048975"}} =
             Event.parse(frame("delete", "103270115826048975"))

    assert {:ok, %Event{payload: "8"}} =
             Event.parse(frame("announcement.delete", "8"))
  end

  test "payload-less events have a nil payload" do
    assert {:ok, %Event{type: "filters_changed", payload: nil}} =
             Event.parse(~s({"stream": ["user"], "event": "filters_changed"}))

    assert {:ok, %Event{type: "notifications_merged", payload: nil}} =
             Event.parse(~s({"stream": ["user"], "event": "notifications_merged"}))
  end

  test "unknown event types pass the payload through undecoded" do
    assert {:ok, %Event{type: "brand.new", payload: "whatever"}} =
             Event.parse(frame("brand.new", "whatever"))
  end

  test "rejects malformed frames" do
    assert {:error, _} = Event.parse("not json")
    assert {:error, _} = Event.parse(~s({"stream": ["user"]}))
    assert {:error, _} = Event.parse(frame("update", "not a status"))
  end

  # Mastodon frames double-encode the payload: it is a JSON *string*.
  defp frame(type, payload) do
    Poison.encode!(%{"stream" => ["user"], "event" => type, "payload" => payload})
  end

  defp fixture(name) do
    [__DIR__, "..", "..", "fixtures", name <> ".json"]
    |> Path.join()
    |> Path.expand()
    |> File.read!()
  end
end
