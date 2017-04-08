defmodule Hunter.Media do

  @hunter_api Application.get_env(:hunter, :hunter_api)

  @type t :: %__MODULE__{
    id: non_neg_integer,
    url: URI.t,
    preview_url: URI.t,
    type: String.t
  }

  @derive [Poison.Encoder]
  defstruct [:id, :url, :preview_url, :type]

  @doc """
  Upload a media file

  ## Parameters

    * `conn` - Connection credentials
    * `file` - [HTTP::FormData::File]

  """
  @spec upload_media(Hunter.Client.t, Path.t) :: Hunter.Media.t
  def upload_media(conn, file) do
    @hunter_api.upload_media(conn, file)
  end
end
