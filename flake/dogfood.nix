# A runnable example configuration, so terranix3000 can be dogfooded end-to-end.
#
#   nix build .#example        # the config.tf.json
#   nix run   .#example        # tofu init && apply
#   nix run   .#example.destroy
{ ... }:
{
  perSystem = { ... }:
    {
      terranix.configurations.example.modules = [ ../example/hello.nix ];

      # Try Terraform instead of the OpenTofu default (requires allowUnfree):
      #   terranix.configurations.example.package = pkgs.terraform;
    };
}
