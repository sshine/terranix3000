# terranix3000 core — the generator.
#
# Pure: every dependency (lib, pkgs) arrives through function arguments, so this
# file can be imported and used in complete isolation:
#
#   let t = import ./core/generator.nix;
#   in t.eval { inherit lib; modules = [ ./main.nix ]; }   # no pkgs needed
#
# Public API:
#   eval   { pkgs? , lib? , modules, specialArgs?, strip_nulls? } -> { config; meta; options; }
#   json   { pkgs, modules, ... }                                 -> config.tf.json derivation
#   toJSON { lib? / pkgs? , modules, ... }                        -> JSON string
#   blocks                                                        -> the top-level block metadata
let
  blocks = import ./blocks.nix;
  optionsModule = import ./options.nix;
  pureHelpers = import ./helpers.nix;

  # Strip module-system bookkeeping and (optionally) nulls from the eval output.
  sanitize = lib: strip_nulls:
    let
      inherit (builtins) typeOf getAttr attrNames length toString;
      inherit (lib) filterAttrs mapAttrs const;
      go = value:
        getAttr (typeOf value) {
          bool = value;
          int = value;
          float = value;
          string = value;
          str = value;
          path = toString value;
          null = null;
          list = map go value;
          set =
            let
              keep = name: _: name != "_module" && name != "_ref" && name != "__functor";
              kept = filterAttrs (n: v: keep n v && (!strip_nulls || v != null)) value;
            in
            if length (attrNames value) == 0 then { } else mapAttrs (const go) kept;
        };
    in
    go;

  eval =
    { pkgs ? null
    , lib ? pkgs.lib
    , modules
    , specialArgs ? { }
    , strip_nulls ? true
    }:
    let
      # lib.tf.* — pure helpers always; the impure `template` only when pkgs is given.
      libWithHelpers = lib.extend pureHelpers;
      libFinal =
        if pkgs == null then
          libWithHelpers
        else
          libWithHelpers.extend (_self: super: {
            tf = super.tf // (import ./template.nix { inherit pkgs; inherit (super) assertMsg; });
          });

      evaluated = libFinal.evalModules {
        modules =
          [ optionsModule ]
          ++ lib.optional (pkgs != null) { _module.args.pkgs = pkgs; }
          ++ (if builtins.isList modules then modules else [ modules ]);
        inherit specialArgs;
      };

      raw = evaluated.config;
      meta = raw._meta or { };
      sane = sanitize libFinal strip_nulls (removeAttrs raw [ "_meta" ]);

      # Assemble only the known top-level blocks, dropping empties.
      pick = acc: block:
        let
          value = sane.${block.name} or { };
          value' = if block.dropEmpty then lib.filterAttrs (_: v: v != { }) value else value;
        in
        if value' == null || value' == { } then acc else acc // { ${block.name} = value'; };

      config = builtins.foldl' pick { } blocks;
    in
    {
      inherit config meta;
      inherit (evaluated) options;
    };

  json = args@{ pkgs, ... }:
    (pkgs.formats.json { }).generate "config.tf.json" (eval args).config;

  toJSON = args: builtins.toJSON (eval args).config;
in
{
  inherit eval json toJSON blocks;
}
