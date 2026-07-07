defmodule Hunter.RelationshipTest do
  use ExUnit.Case, async: true

  import Mox

  alias Hunter.Relationship

  @conn Hunter.Client.new(base_url: "https://example.com", bearer_token: "123456")

  setup :verify_on_exit!

  test "returns relationships to other accounts" do
    expect(Hunter.ApiMock, :relationships, fn %Hunter.Client{}, [8039] ->
      [%Relationship{id: "8039", following: true}]
    end)

    assert [%Relationship{following: true}] = Relationship.relationships(@conn, [8039])
  end

  test "follows and unfollows an account" do
    expect(Hunter.ApiMock, :follow, fn %Hunter.Client{}, 8039 ->
      %Relationship{id: "8039", following: true}
    end)

    expect(Hunter.ApiMock, :unfollow, fn %Hunter.Client{}, 8039 ->
      %Relationship{id: "8039", following: false}
    end)

    assert %Relationship{following: true} = Relationship.follow(@conn, 8039)
    assert %Relationship{following: false} = Relationship.unfollow(@conn, 8039)
  end

  test "blocks and unblocks an account" do
    expect(Hunter.ApiMock, :block, fn %Hunter.Client{}, 8039 ->
      %Relationship{id: "8039", blocking: true}
    end)

    expect(Hunter.ApiMock, :unblock, fn %Hunter.Client{}, 8039 ->
      %Relationship{id: "8039", blocking: false}
    end)

    assert %Relationship{blocking: true} = Relationship.block(@conn, 8039)
    assert %Relationship{blocking: false} = Relationship.unblock(@conn, 8039)
  end

  test "mutes and unmutes an account" do
    expect(Hunter.ApiMock, :mute, fn %Hunter.Client{}, 8039 ->
      %Relationship{id: "8039", muting: true}
    end)

    expect(Hunter.ApiMock, :unmute, fn %Hunter.Client{}, 8039 ->
      %Relationship{id: "8039", muting: false}
    end)

    assert %Relationship{muting: true} = Relationship.mute(@conn, 8039)
    assert %Relationship{muting: false} = Relationship.unmute(@conn, 8039)
  end
end
