# terranix3000

A minimal, clean-slate reimplementation of [terranix](https://terranix.org), built to be dogfooded.

## Layers

- **`core/`** — the pure generator (`lib`-only, no `pkgs` needed): modules → Terraform/OpenTofu JSON.
- **`flake/`** — dendritic flake-parts modules: the public `lib`, the `configurations` app layer,
  docs, devshell, and a dogfood example.
- **`example/`** — a real configuration you can `apply`.

## Try it

```sh
# the core API, in isolation
nix eval .#lib.terranix --apply builtins.attrNames     # [ "blocks" "eval" "json" "toJSON" ]

# generate config.tf.json
nix build .#example.config && cat result

# run it (OpenTofu by default)
nix run .#example
nix run .#example.destroy

# single-source docs: options.json + options.md + man page
nix build .#docs && ls result
```

## Use from another flake

```nix
{
  inputs.terranix3000.url = "path:/path/to/terranix3000";
  # ...
  # pure, no pkgs:
  #   inputs.terranix3000.lib.terranix.eval { inherit lib; modules = [ ./main.nix ]; }
  # the file:
  #   inputs.terranix3000.lib.terranix.json { inherit pkgs; modules = [ ./main.nix ]; }
}
```
