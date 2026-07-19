# L2 — the flake-parts app layer.
#
# Declares `terranix.configurations.<name>` and wires each configuration into
# packages / apps / devShells. The Terraform/OpenTofu binary is overridden with a
# single top-level `package =` knob.
#
# The passthru trick: `nix run .#foo` runs `apply`; `nix run .#foo.destroy` runs
# `destroy` — both live inside one derivation's passthru, because the flake `apps`
# schema forbids nested attrsets.
{ ... }:
{
  perSystem = { config, pkgs, lib, ... }:
    let
      cfg = config.terranix;
      terranix = import ../core/generator.nix;
    in
    {
      options.terranix.configurations = lib.mkOption {
        default = { };
        description = "terranix configurations, wired into packages/apps/devShells.";
        type = lib.types.attrsOf (lib.types.submodule ({ name, config, ... }: {
          options = {
            modules = lib.mkOption {
              type = lib.types.listOf lib.types.deferredModule;
              default = [ ];
              description = "terranix modules to evaluate for this configuration.";
            };

            extraArgs = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = { };
              description = "Extra specialArgs available inside the modules.";
            };

            package = lib.mkOption {
              type = lib.types.package;
              default = pkgs.opentofu;
              defaultText = lib.literalExpression "pkgs.opentofu";
              example = lib.literalExpression "pkgs.terraform";
              description = ''
                The Terraform / OpenTofu implementation. Override directly, e.g.
                `package = pkgs.opentofu.withPlugins (p: [ p.local p.random ]);`.
              '';
            };

            extraRuntimeInputs = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [ ];
              description = "Extra runtime inputs available to the wrapper.";
            };

            prefix = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = "Shell commands to run before each invocation.";
            };

            suffix = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = "Shell commands to run after each invocation.";
            };

            workdir = lib.mkOption {
              type = lib.types.str;
              default = name;
              description = "Working directory (defaults to the configuration name).";
            };

            result = lib.mkOption {
              readOnly = true;
              default = { };
              description = "Read-only outputs produced by this configuration.";
              type = lib.types.submodule {
                options = {
                  configuration = lib.mkOption { description = "The config.tf.json derivation."; };
                  bin = lib.mkOption { description = "The tofu/terraform binary name."; };
                  scripts = lib.mkOption { description = "init/plan/apply/destroy scripts."; };
                  app = lib.mkOption { description = "Default app (apply) with the scripts in passthru."; };
                  devShell = lib.mkOption { description = "devShell with the scripts and the wrapper."; };
                };
              };
            };
          };

          config.result =
            let
              bin = config.package.meta.mainProgram;

              configuration = terranix.json {
                inherit pkgs;
                modules = config.modules;
                specialArgs = config.extraArgs;
              };

              wrapper = pkgs.writeShellApplication {
                name = bin;
                runtimeInputs = [ config.package ] ++ config.extraRuntimeInputs;
                text = ''
                  mkdir -p ${config.workdir}
                  cd ${config.workdir}
                  ${config.prefix}
                  ${bin} "$@"
                  ${config.suffix}
                '';
              };

              mkScript = sname: body: pkgs.writeShellApplication {
                name = sname;
                runtimeInputs = [ wrapper ];
                text = ''
                  mkdir -p ${config.workdir}
                  ln -sf ${configuration} ${config.workdir}/config.tf.json
                  ${body}
                '';
              };

              scripts = {
                init = mkScript "init" "${bin} init";
                plan = mkScript "plan" "${bin} init && ${bin} plan";
                apply = mkScript "apply" "${bin} init && ${bin} apply";
                destroy = mkScript "destroy" "${bin} init && ${bin} destroy";
              };

              app = scripts.apply.overrideAttrs {
                inherit name;
                passthru = scripts // {
                  inherit configuration;
                  terraform = wrapper;
                };
              };

              devShell = pkgs.mkShell {
                packages = (builtins.attrValues scripts) ++ [ wrapper ];
              };
            in
            { inherit configuration bin scripts app devShell; };
        }));
      };

      config = {
        packages = lib.mapAttrs (_: c: c.result.app) cfg.configurations;

        apps = lib.optionalAttrs (cfg.configurations ? default)
          (builtins.mapAttrs
            (_: script: { type = "app"; program = lib.getExe script; })
            cfg.configurations.default.result.scripts);

        devShells = lib.mapAttrs (_: c: c.result.devShell) cfg.configurations;
      };
    };
}
