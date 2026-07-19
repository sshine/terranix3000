# Development shell and formatter for hacking on terranix3000 itself.
{ ... }:
{
  perSystem = { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.opentofu
          pkgs.nixpkgs-fmt
        ];
      };

      formatter = pkgs.nixpkgs-fmt;
    };
}
