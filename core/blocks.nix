# The complete set of Terraform / OpenTofu top-level JSON blocks.
#
# Single source of truth: both the option declarations (options.nix) and the
# output whitelist (generator.nix) are derived from this list, so adding a
# block is a one-line change here.
#
#   referenceable   attach a ${...} functor to each leaf so it can be referenced
#   referencePrefix qualifies the reference address (e.g. "data.")
#   dropEmpty       omit first-level entries whose body is {} (e.g. an empty resource)
[
  { name = "resource"; referenceable = true; referencePrefix = ""; dropEmpty = true;
    description = "Resources — the backbone of Terraform, creating and changing state."; }

  { name = "data"; referenceable = true; referencePrefix = "data."; dropEmpty = true;
    description = "Data sources — read-only queries against existing infrastructure."; }

  { name = "ephemeral"; referenceable = true; referencePrefix = "ephemeral."; dropEmpty = true;
    description = "Ephemeral resources — temporary objects that are never stored in state."; }

  { name = "check"; referenceable = false; dropEmpty = false;
    description = "Check blocks — custom validation and health assertions."; }

  { name = "provider"; referenceable = false; dropEmpty = false;
    description = "Provider configuration. Never put secrets here — use variables."; }

  { name = "variable"; referenceable = false; dropEmpty = false;
    description = "Input variables, settable via -var, TF_VAR_* or a tfvars file."; }

  { name = "output"; referenceable = false; dropEmpty = false;
    description = "Output values, useful with terraform_remote_state."; }

  { name = "locals"; referenceable = false; dropEmpty = false;
    description = "File-scoped local values."; }

  { name = "module"; referenceable = false; dropEmpty = false;
    description = "Terraform module calls (unrelated to the Nix/terranix module system)."; }

  { name = "terraform"; referenceable = false; dropEmpty = false;
    description = "Terraform settings: backend, cloud, required_providers, required_version, encryption (OpenTofu)."; }

  { name = "moved"; referenceable = false; dropEmpty = false;
    description = "Move a resource from one address to another."; }

  { name = "removed"; referenceable = false; dropEmpty = false;
    description = "Declare that a resource has been removed from configuration."; }

  { name = "import"; referenceable = false; dropEmpty = false;
    description = "Import existing objects into Terraform state."; }
]
