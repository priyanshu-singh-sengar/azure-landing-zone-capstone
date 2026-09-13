---
name: Feature Request / Infrastructure Change
about: Request a new infrastructure component or change to the Landing Zone
title: '[FEAT]: '
labels: enhancement, infrastructure
assignees: ''
---

## Summary
<!-- One-sentence description of the infrastructure change -->

## Acceptance Criteria
<!-- List the conditions that must be true for this issue to be considered done -->
- [ ] 
- [ ] 
- [ ] 

## Architecture Impact
<!-- Which layers/modules are affected? -->
- **Layer(s)**: `00-governance` / `01-connectivity-hub` / `02-spokes`
- **Module(s)**: 

## Implementation Notes
<!-- Any specific HCL patterns, naming conventions, or constraints to follow -->

## Definition of Done
- [ ] Terraform code implemented following module conventions in `modules/`
- [ ] `terraform fmt` clean
- [ ] `terraform validate` passes
- [ ] `tfsec` / Checkov shows no HIGH/CRITICAL findings (or findings are documented + accepted)
- [ ] CI pipeline passes on the PR (fmt -> validate -> tfsec -> plan)
- [ ] Human code review completed + all comments resolved
- [ ] Copilot code review requested and discussed
- [ ] Squash-merged to `main` with a linked release tag
- [ ] LZ component confirmed live in Azure Portal after `terraform apply`

## References
<!-- Link to relevant architecture docs, Azure docs, or related issues -->
- [ARCHITECTURE_DESIGN_AND_REPO_STRUCTURE.md](../../ARCHITECTURE_DESIGN_AND_REPO_STRUCTURE.md)
