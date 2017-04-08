# Hunter (alpha)

A Elixir client for [Mastodon](https://github.com/Gargron/mastodon/), a GNU social-compatible micro-blogging service

## Installation

```elixir
def deps do
  [{:hunter, "~> 0.1.0"}]
end
```

## Examples

Assumming that you already know your *instance* and your *bearer token* you can do
the following:

```elixir
iex(1)> conn = Hunter.new([base_url: "https://example.com", bearer_token: "123456"])
%Hunter.Client{base_url: "https://example.com",
 bearer_token: "123456"}
``` 

### Getting the current user

```elixir
iex(2)> Hunter.verify_credentials(conn)
%Hunter.Account{acct: "milmazz",
 avatar: "https://social.lou.lt/avatars/original/missing.png",
 created_at: "2017-04-06T17:43:55.325Z", display_name: "Milton Mazzarri",
 followers_count: 2, following_count: 3,
 header: "https://social.lou.lt/headers/original/missing.png", id: 8039,
 locked: false, note: "", statuses_count: 1,
 url: "https://social.lou.lt/@milmazz", username: "milmazz"}
```

### Fetching an account

```elixir 
iex(3)> Hunter.account(conn, 8039)
%Hunter.Account{acct: "milmazz",
 avatar: "https://social.lou.lt/avatars/original/missing.png",
 created_at: "2017-04-06T17:43:55.325Z", display_name: "Milton Mazzarri",
 followers_count: 2, following_count: 3,
 header: "https://social.lou.lt/headers/original/missing.png", id: 8039,
 locked: false, note: "", statuses_count: 1,
 url: "https://social.lou.lt/@milmazz", username: "milmazz"}
```

### Getting an account's followers

Returns a list of `Accounts`

```elixir
iex(4)> Hunter.followers(conn, 8039)
[%Hunter.Account{acct: "atmantree@mastodon.club",
  avatar: "https://social.lou.lt/system/accounts/avatars/000/008/518/original/7715529d4ceb4554.jpg?1491509276",
  created_at: "2017-04-06T20:07:57.119Z", display_name: "Carlos Gustavo Ruiz",
  followers_count: 2, following_count: 2,
  header: "https://social.lou.lt/system/accounts/headers/000/008/518/original/394f31473de7c64a.png?1491509277",
  id: 8518, locked: false,
  note: "Programmer, Pythonista, Web Creature, Blogger, C++ and Haskell Fan. Never stop learning, because life never stops teaching.",
  statuses_count: 1, url: "https://mastodon.club/@atmantree",
  username: "atmantree"},
  ...
 ]
```

### Getting who account is following

Returns a list of `Accounts`

```elixir
iex(5)> Hunter.following(conn, 8039)
[%Hunter.Account{acct: "sebasmagri@mastodon.cloud",
  avatar: "https://social.lou.lt/system/accounts/avatars/000/007/899/original/19b4d8c1e9d4e68a.jpg?1491498458",
  created_at: "2017-04-06T17:07:38.912Z",
  display_name: "Sebastián Ramírez Magrí", followers_count: 2,
  following_count: 1,
  header: "https://social.lou.lt/system/accounts/headers/000/007/899/original/missing.png?1491498458",
  id: 7899, locked: false, note: "", statuses_count: 2,
  url: "https://mastodon.cloud/@sebasmagri", username: "sebasmagri"},
  ...]
 ```

### Following a remote user

```elixir
iex(6)> Hunter.follow_by_uri(conn, "paperswelove@mstdn.io")
%Hunter.Account{acct: "paperswelove@mstdn.io",
 avatar: "https://social.lou.lt/system/accounts/avatars/000/007/126/original/60ecc8225809c008.png?1491486258",
 created_at: "2017-04-06T13:44:18.281Z", display_name: "Papers We Love",
 followers_count: 1, following_count: 0,
 header: "https://social.lou.lt/system/accounts/headers/000/007/126/original/missing.png?1491486258",
 id: 7126, locked: false,
 note: "Building Bridges Between Academia and Industry\r\n\r\n<a href=\"http://paperswelove.org\" rel=\"nofollow noopener\"><span class=\"invisible\">http://</span><span class=\"\">paperswelove.org</span><span class=\"invisible\"></span></a>\r\n<a href=\"http://pwlconf.org\" rel=\"nofollow noopener noopener\"><span class=\"invisible\">http://</span><span class=\"\">pwlconf.org</span><span class=\"invisible\"></span></a>",
 statuses_count: 1, url: "https://mstdn.io/@paperswelove",
 username: "paperswelove"}
 ```

### Muting/unmuting an account

```elixir
iex(7)> Hunter.mute(conn, 7899)
%Hunter.Relationship{blocking: false, followed_by: false, following: true,
 muting: true, requested: false}
iex(8)> Hunter.unmute(conn, 7899)
%Hunter.Relationship{blocking: false, followed_by: false, following: true,
 muting: false, requested: false}
```

### Getting an account's statuses

```elixir
iex(9)> Hunter.statuses(conn, 8039, [limit: 1])
[%Hunter.Status{account: %{"acct" => "milmazz",
    "avatar" => "https://social.lou.lt/avatars/original/missing.png",
    "created_at" => "2017-04-06T17:43:55.325Z",
    "display_name" => "Milton Mazzarri", "followers_count" => 2,
    "following_count" => 4,
    "header" => "https://social.lou.lt/headers/original/missing.png",
    "id" => 8039, "locked" => false, "note" => "", "statuses_count" => 1,
    "url" => "https://social.lou.lt/@milmazz", "username" => "milmazz"},
  application: %{"name" => "Web", "website" => nil},
  content: "<p><a href=\"http://tootplanet.space/@Shutsumon\" class=\"h-card u-url p-nickname mention\">@<span>Shutsumon</span></a> You should read &quot;How to design programs&quot; book <a href=\"http://htdp.org\" rel=\"nofollow noopener\" target=\"_blank\"><span class=\"invisible\">http://</span><span class=\"\">htdp.org</span><span class=\"invisible\"></span></a></p>",
  created_at: "2017-04-06T18:28:59.392Z", favourited: nil, favourites_count: 0,
  id: 59144, in_reply_to_account_id: 7742, in_reply_to_id: 59042,
  media_attachments: [],
  mentions: [%{"acct" => "Shutsumon@tootplanet.space", "id" => 7742,
     "url" => "http://tootplanet.space/@Shutsumon", "username" => "Shutsumon"}],
  reblog: nil, reblogged: nil, reblogs_count: 0, sensitive: false,
  spoiler_text: "", tags: [],
  uri: "tag:social.lou.lt,2017-04-06:objectId=59144:objectType=Status",
  url: "https://social.lou.lt/@milmazz/59144", visibility: "public"}]
```

### Fetching a user's favourites

```
iex(10)> Hunter.favourites(conn)
[]
```

### Favouriting/unfavouriting a status

```elixir
iex(11)> Hunter.favourite(conn, 442)
%Hunter.Status{account: %{"acct" => "FriendlyPootis",
   "avatar" => "https://social.lou.lt/system/accounts/avatars/000/000/034/original/565da0399c2c26cf.jpg?1491228302",
   "created_at" => "2017-04-03T13:50:06.485Z",
   "display_name" => "FriendlyPootis 🚉", "followers_count" => 61,
   "following_count" => 52,
   "header" => "https://social.lou.lt/system/accounts/headers/000/000/034/original/b009ddb5a8ce41c1.jpg?1491228302",
   "id" => 34, "locked" => false,
   "note" => "fermé comme un carré, Vladimir Pootin sur YT (<a href=\"https://www.youtube.com/VladimirPootin\" rel=\"nofollow noopener\" target=\"_blank\"><span class=\"invisible\">https://www.</span><span class=\"\">youtube.com/VladimirPootin</span><span class=\"invisible\"></span></a>)",
   "statuses_count" => 252, "url" => "https://social.lou.lt/@FriendlyPootis",
   "username" => "FriendlyPootis"},
 application: %{"name" => "Web", "website" => nil},
 content: "<p>les gens pensez à migrer d&apos;instance pour en aller sur une moins chargée tant que vous pouvez, plus vous attendrez plus vous aurez la flemme</p>",
 created_at: "2017-04-03T16:22:04.286Z", favourited: true, favourites_count: 5,
 id: 442, in_reply_to_account_id: nil, in_reply_to_id: nil,
 media_attachments: [], mentions: [], reblog: nil, reblogged: false,
 reblogs_count: 4, sensitive: false, spoiler_text: "", tags: [],
 uri: "tag:social.lou.lt,2017-04-03:objectId=442:objectType=Status",
 url: "https://social.lou.lt/@FriendlyPootis/442", visibility: "public"}
 ```

 ```elixir
 iex(12)> Hunter.unfavourite(conn, 442)
%Hunter.Status{account: %{"acct" => "FriendlyPootis",
   "avatar" => "https://social.lou.lt/system/accounts/avatars/000/000/034/original/565da0399c2c26cf.jpg?1491228302",
   "created_at" => "2017-04-03T13:50:06.485Z",
   "display_name" => "FriendlyPootis 🚉", "followers_count" => 61,
   "following_count" => 52,
   "header" => "https://social.lou.lt/system/accounts/headers/000/000/034/original/b009ddb5a8ce41c1.jpg?1491228302",
   "id" => 34, "locked" => false,
   "note" => "fermé comme un carré, Vladimir Pootin sur YT (<a href=\"https://www.youtube.com/VladimirPootin\" rel=\"nofollow noopener\" target=\"_blank\"><span class=\"invisible\">https://www.</span><span class=\"\">youtube.com/VladimirPootin</span><span class=\"invisible\"></span></a>)",
   "statuses_count" => 252, "url" => "https://social.lou.lt/@FriendlyPootis",
   "username" => "FriendlyPootis"},
 application: %{"name" => "Web", "website" => nil},
 content: "<p>les gens pensez à migrer d&apos;instance pour en aller sur une moins chargée tant que vous pouvez, plus vous attendrez plus vous aurez la flemme</p>",
 created_at: "2017-04-03T16:22:04.286Z", favourited: true, favourites_count: 5,
 id: 442, in_reply_to_account_id: nil, in_reply_to_id: nil,
 media_attachments: [], mentions: [], reblog: nil, reblogged: false,
 reblogs_count: 4, sensitive: false, spoiler_text: "", tags: [],
 uri: "tag:social.lou.lt,2017-04-03:objectId=442:objectType=Status",
 url: "https://social.lou.lt/@FriendlyPootis/442", visibility: "public"}
 ```

## TODO

* OAuth2 authentication
  - Register client for token-access
  - Token authentication for API usage
* Search for accounts or content
* Getting an account's relationship
* Register an application
* Fetching a user's blocks
* Fetching a list of follow requests
* Authorizing or rejecting follow requests
* Support arrays as parameter types
* Getting instance information
* Uploading media attachment
* Fetching a user's mutes
* Fetching a user's notifications
* Getting a single notification
* Clearing notifications
* Fetching user's reports
* Reporting a user
* Getting status context
* Getting a card associated with a status
* Getting who reblogged/favourited a status

## License

Hunter source code is released under Apache 2 License.

Check the [LICENSE](LICENSE) for more information.
