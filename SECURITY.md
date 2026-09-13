# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| main branch | Yes |
| All other branches | No (report against main) |

## Reporting a Vulnerability

We take security vulnerabilities seriously in this Landing Zone infrastructure codebase. Since this repository contains Terraform configurations that manage Azure cloud infrastructure, security issues can have real operational impact.

### How to Report

**Please do NOT open a public GitHub Issue for security vulnerabilities.**

Instead, use **GitHub Private Security Advisories**:
1. Navigate to the **Security** tab of this repository
2. Click **"Report a vulnerability"**
3. Fill in the advisory form with as much detail as possible

Alternatively, email the repository owner directly (see GitHub profile for contact).

### What to Include

Please include the following in your report:
- **Description**: A clear description of the vulnerability
- **Location**: The specific file(s) and line numbers affected
- **Impact**: What an attacker could achieve by exploiting this
- **Reproduction**: Step-by-step instructions to reproduce the issue
- **Suggested Fix**: If you have one, please share it

### Scope

Issues we are particularly interested in:
- Hard-coded credentials or secrets in Terraform code
- Overly permissive IAM role assignments (`*` actions or `*` resources)
- Public endpoints where private connectivity should be used
- NSG rules that allow unrestricted inbound traffic (`0.0.0.0/0` on sensitive ports)
- Insecure storage account configurations (public blob access, no TLS enforcement)
- Missing encryption at rest or in transit for sensitive resources

### Response Timeline

| Stage | Target |
|---|---|
| Acknowledgement | Within **2 business days** |
| Initial Assessment | Within **5 business days** |
| Resolution / Patch | Within **14 business days** for High/Critical findings |

### Security Best Practices for Contributors

Before submitting a PR, please ensure:
- Run `tfsec` or `Checkov` locally and resolve all HIGH/CRITICAL findings
- No secrets, passwords, or tokens are present in code or tfvars files
- All resources follow the principle of least privilege
- The `.gitignore` excludes `*.tfvars` files containing sensitive values and `.terraform/` directories

### Preferred Languages

English preferred. Other languages accepted.
