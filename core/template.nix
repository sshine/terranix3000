# Impure `lib.tf.template` — needs pkgs.writeText, so it is only added to
# `lib.tf` when the generator is called with `pkgs`.
#
# Returns a *bare* templatefile() expression; wrap with `tf.ref` to use as a
# field value:
#
#   templated_field = lib.tf.ref (lib.tf.template { text = "hello ${var.name}"; });
{ pkgs, assertMsg }:
{
  template =
    { text ? ""
    , source ? ""
    , variables ? { }
    }:
    assert assertMsg (text == "" || source == "") "template: provide either 'text' or 'source', not both";
    let
      file =
        if text != "" then pkgs.writeText "template.tftpl" text
        else source;
    in
    "templatefile(\"${file}\", ${builtins.toJSON variables})";
}
