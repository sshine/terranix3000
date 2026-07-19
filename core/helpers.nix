# Pure terraform helpers, added to lib as `lib.tf.*` (no pkgs required).
#
# The one rule: HCL interpolation cannot nest. So we separate *bare* expression
# builders from the single `ref`/`expr` wrap that turns a bare expression into a
# field value. Build bare, wrap once, last.
#
#   value = tf.ref (tf.call "join" [ (tf.str ",") (tf.raw "var.things") ]);
#         => "${join(\",\", var.things)}"
_self: super:
let
  inherit (builtins) toJSON concatStringsSep;
in
{
  tf = {
    # wrap a bare HCL expression as an interpolated field value (do this once, last)
    ref = expr: "\${${expr}}";
    expr = expr: "\${${expr}}";

    # a bare HCL fragment, passed through unchanged (references, other calls, ...)
    raw = e: e;

    # a quoted HCL string literal — a bare argument
    str = s: "\"${s}\"";

    # embed arbitrary Nix data as a bare HCL literal (JSON is valid HCL)
    lit = v: toJSON v;

    # a bare HCL function call from bare arguments
    call = name: args: "${name}(${concatStringsSep ", " args})";

    # convenience: a complete `${file("path")}` field value
    file = path: "\${file(\"${path}\")}";

    # convenience: a bare `jsonencode(<nix data>)` — wrap with tf.ref to use as a value
    jsonencode = v: "jsonencode(${toJSON v})";
  };
}
