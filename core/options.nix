# The top-level Terraform/OpenTofu block options, generated from ./blocks.nix.
#
# Every block is a recursive "magic merge" value that deep-merges across modules.
# Referenceable blocks additionally attach a __functor to each leaf, so
#   config.resource.aws_instance.web "id"  =>  "${aws_instance.web.id}"
{ lib, ... }:
let
  inherit (lib) mkOption id isAttrs mapAttrs types nameValuePair;

  blocks = import ./blocks.nix;

  # bool | int | float | str | list | attrs, recursively — the untyped body of
  # any Terraform block. This is what gives terranix universal provider coverage.
  valueType =
    with types;
    let
      vt =
        nullOr (oneOf [
          bool
          int
          float
          str
          (attrsOf vt)
          (listOf vt)
        ])
        // {
          description = "Terraform value (bool, int, float, str, list or attrs)";
          emptyValue.value = { };
        };
    in
    vt;

  mkBlockOption =
    { name, description, referenceable ? false, referencePrefix ? "", ... }:
    nameValuePair name (mkOption {
      inherit description;
      default = { };
      type = valueType;
      apply =
        if !referenceable then
          id
        else
          let
            mapOrSkip = f: attrs: if isAttrs attrs then mapAttrs f attrs else attrs;
          in
          mapOrSkip (
            type: v1:
            mapOrSkip (
              label: v2:
              if isAttrs v2 then
                v2 // { __functor = _self: attr: "\${${referencePrefix}${type}.${label}.${attr}}"; }
              else
                v2
            ) v1
          );
    });
in
{
  options = builtins.listToAttrs (map mkBlockOption blocks) // {
    # Out-of-band metadata, nixpkgs-passthru style. Never rendered to JSON.
    _meta = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      internal = true;
      description = "Arbitrary metadata attached to a terranix evaluation result.";
    };
  };
}
