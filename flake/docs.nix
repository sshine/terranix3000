# L3 — documentation from a single source.
#
#   eval {...}.options  ->  nixosOptionsDoc  ->  options.json (website)
#                                             \-> options.md   (-> pandoc -> man page, terminal)
{ ... }:
{
  perSystem = { pkgs, ... }:
    let
      terranix = import ../core/generator.nix;

      eval = terranix.eval {
        inherit pkgs;
        modules = [ ];
      };

      optionsDoc = pkgs.nixosOptionsDoc {
        options = removeAttrs eval.options [ "_module" ];
        warningsAreErrors = false;
      };
    in
    {
      packages.docs = pkgs.runCommand "terranix-docs"
        { nativeBuildInputs = [ pkgs.pandoc ]; }
        ''
          mkdir -p $out/share/man/man5
          cp ${optionsDoc.optionsJSON}/share/doc/nixos/options.json $out/options.json
          cp ${optionsDoc.optionsCommonMark} $out/options.md
          pandoc --standalone --from commonmark --to man \
            --metadata title=TERRANIX-OPTIONS \
            --metadata section=5 \
            ${optionsDoc.optionsCommonMark} \
            -o $out/share/man/man5/terranix-options.5
        '';
    };
}
