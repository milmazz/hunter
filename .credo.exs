# Overrides Credo's defaults; every check not listed here keeps its
# default configuration.
%{
  configs: [
    %{
      name: "default",
      checks: %{
        extra: [
          # Entity structs mirror the upstream Mastodon API entities, whose
          # field counts we don't control (Status has 33 attributes)
          {Credo.Check.Warning.StructFieldAmount, max_fields: 40}
        ]
      }
    }
  ]
}
