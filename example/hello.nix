# A minimal terranix configuration that needs no providers.
#
# `terraform_data` is a built-in managed resource (Terraform 1.4+ / OpenTofu), so
# `apply` works offline. It also exercises the referenceable functor: calling the
# resource leaf as a function yields a "${terraform_data.hello.output}" reference.
{ config, lib, ... }:
{
  terraform.required_version = ">= 1.6";

  resource.terraform_data.hello.input = "hello from terranix3000";

  output.greeting = {
    value = config.resource.terraform_data.hello "output";
    description = "Echoed back from the terraform_data resource.";
  };

  # A taste of the helper library: a bare jsonencode() wrapped as a field value.
  output.encoded = {
    value = lib.tf.ref (lib.tf.jsonencode { framework = "terranix3000"; ok = true; });
  };
}
