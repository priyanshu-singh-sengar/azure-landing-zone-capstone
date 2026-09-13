# bootstrap/

## Purpose

The bootstrap directory solves the Terraform state bootstrapping problem. Before any Terraform layer can store its state remotely, the remote storage infrastructure must exist. Because you cannot use Terraform to manage the storage account that holds Terraform state (circular dependency), this directory is applied once, manually, using a local state file. Its outputs are then hard-coded into each layer's `backend.tf`.

---

## Files

### main.tf

The single file in this directory. It contains:

**Provider and Version Constraints**

```hcl
required_version = ">= 1.5.0"
azurerm ~> 3.110
random  ~> 3.5
```

No `backend` block is defined. Terraform uses local state for this directory, stored in `terraform.tfstate` within the directory.

**`random_string.suffix`**

Storage account names must be globally unique across all Azure tenants (they form part of a public DNS name: `<name>.blob.core.windows.net`). A 6-character random lowercase string is appended to `sttfstate` to make the name unique. The suffix is generated once and stored in local state, so repeated applies do not regenerate it.

**`azurerm_resource_group.tfstate`**

Creates `rg-terraform-state` in the selected region. Tagged with `Environment = Management`, `IaC_Managed = Terraform`, `Project = Azure-Landing-Zone`, `Purpose = Terraform Remote State Storage`.

**`azurerm_storage_account.tfstate`**

Creates the storage account with the following hardening:
- `account_tier = Standard`, `account_replication_type = GRS`: Data is replicated to a secondary region for disaster recovery.
- `min_tls_version = TLS1_2`: Enforces encrypted transport.
- `blob_properties.versioning_enabled = true`: Every state write creates a new blob version, enabling rollback.
- `blob_properties.delete_retention_policy.days = 30`: Soft delete protects against accidental deletion.

**`azurerm_storage_container.tfstate`**

Creates a private blob container named `tfstate`. All state files for all layers are stored in this single container, differentiated by the `key` value in each layer's `backend.tf`.

**Outputs**

- `resource_group_name`: The resource group name, for use in `backend.tf`.
- `storage_account_name`: The storage account name, for use in `backend.tf`.
- `container_name`: The container name, for use in `backend.tf`.

---

## How to Apply

```bash
cd bootstrap
terraform init        # initialises with local state
terraform apply       # creates the storage infrastructure
terraform output      # copy values into each layer's backend.tf
```

After applying, the outputs are hard-coded into `layers/*/backend.tf`. The bootstrap directory itself is never run again unless the storage infrastructure needs to be recreated.

---

## Why Not Manage Bootstrap State Remotely?

Some teams store the bootstrap state in a different storage account (created manually or by a pipeline). This adds complexity. The simpler approach — local state for a one-time bootstrap — is standard practice. Because the bootstrap creates durable, rarely-changed resources, the risk of local state being lost is low, and the resources can be re-imported if needed.
