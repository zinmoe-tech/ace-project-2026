# BoundarySessionCounter Deployment

1. Create Lambda `BoundarySessionCounter`.
2. Attach `BoundarySessionMonitorLambdaRole`.
3. Put Lambda in the VPC/subnet/security group that can reach private Vault.
4. Configure the environment variables documented in `docs/05-session-counter.md`.
5. Add EventBridge schedule `rate(1 minute)`.
6. Test and confirm logs show:
   - Vault AWS authentication successful
   - Boundary authentication successful
   - Active Boundary sessions: X
   - Published Datadog metric
