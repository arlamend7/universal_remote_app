# Publishing signed drivers

1. In the repository's Pages settings, select GitHub Actions as the publishing source. Protect the `github-pages` environment, restrict deployments to `main`, and require reviewers where available.
2. Create a P-256 signing key using your organization's approved key provisioning process. Add the PEM private key to the protected environment secret `DRIVER_SIGNING_KEY_PEM`. Set `DRIVER_SIGNING_KEY_ID` as an environment variable.
3. Configure release builds with the Pages base URL and the matching public key. Use the platform trust settings documented in [architecture](architecture.md). During key rotation, include both public keys in app builds before switching the signing key. Keep previous public keys until clients have refreshed the catalog.
4. List each approved release in `drivers/releases.json`. Keep existing releases in the index while they remain supported. Use versioned source directories and never reuse a published driver version for changed bytes.
5. After review and merge, run **Publish Universal Remote drivers** on `main`. Enter a catalog revision strictly greater than the last published revision. Verify the deployment URL from the workflow output.

Pull requests and the feature branch use an ephemeral key for validation. The production job is manual and uses its protected environment. The published directory contains `catalog.json` and `packages/<driver-id>/<version>/driver.zip`. All files are public. Driver packages and the catalog are independently signed with ECDSA P-256 and SHA-256. The ZIP contents are deterministic for unchanged source. Catalog revisions must increase, including after changing signing keys.

[GitHub Pages custom workflow documentation](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)
