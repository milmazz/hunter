defmodule Hunter.DomainBlock do
  @moduledoc """
  DomainBlock entity

  A domain that is blocked by the instance, as returned by the instance
  domain blocks endpoint

  ## Fields

    * `domain` - the domain which is blocked; may be obfuscated or partially
      censored
    * `digest` - the SHA256 hash digest of the domain string
    * `severity` - the level to which the domain is blocked, one of:
      `silence`, `suspend`
    * `comment` - an optional reason for the domain block

  """

  @type t :: %__MODULE__{
          domain: String.t(),
          digest: String.t(),
          severity: String.t(),
          comment: String.t() | nil
        }

  @derive [Poison.Encoder]
  defstruct [:domain, :digest, :severity, :comment]
end
