# BoundaryWorkerCleanup Deployment

Why:
AWS can terminate EC2 but cannot remove the corresponding HCP Boundary worker object.

Steps:
1. Create Lambda `BoundaryWorkerCleanup`.
2. Attach `BoundaryWorkerCleanup-role-ro7ij99a`.
3. Put it in the VPC/subnet/security group that can reach private Vault.
4. Configure:
   - `VAULT_ADDR`
   - `VAULT_NAMESPACE=admin`
   - `VAULT_AWS_ROLE=boundary-worker-cleanup`
   - `BOUNDARY_ADDR`
   - `BOUNDARY_AUTH_METHOD_ID`
5. Add EventBridge rule `boundary-worker-termination-cleanup`.
6. Ensure the Lambda role can call `autoscaling:CompleteLifecycleAction`.
7. Test a real ASG scale-in and confirm:
   - matching `aws-asg-<instance-id>` worker is deleted
   - lifecycle action returns `CONTINUE`
