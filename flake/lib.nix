# L0 exposed: flake.lib.terranix = the core API (eval / json / toJSON / blocks).
#
#   inputs.terranix3000.lib.terranix.eval { inherit lib; modules = [ ./main.nix ]; }
#   inputs.terranix3000.lib.terranix.json { inherit pkgs; modules = [ ./main.nix ]; }
{ ... }:
{
  flake.lib.terranix = import ../core/generator.nix;
}
