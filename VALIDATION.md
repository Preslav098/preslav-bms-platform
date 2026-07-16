# Template validation and deployment checklist

The template package was validated against the Fleet Manager source tree using:

```bash
cd /var/www/fleet-management/frontend
npm ci

npm run validate:customization -- \
  /var/www/preslav-bms-platform/deploy-request.json

npm run validate:template-package -- \
  /var/www/preslav-bms-platform \
  preslav-bms \
  /var/www/preslav-bms-platform/deploy-request.json

npm run check:template-boundaries -- \
  /var/www/preslav-bms-platform/templates/preslav-bms
```

Observed result during development:

- customization validation: passed;
- template package validation: passed (`preslav-bms@1`);
- template boundary check: passed.

Final BM deployment command used by the Fleet Manager build pipeline:

```bash
cd /var/www/fleet-management

./deploy.sh \
  --mode bm \
  --manifest /var/www/preslav-bms-platform/deploy-request.json \
  --template-source /var/www/preslav-bms-platform
```

The repository also contains local helper scripts used during iterative development. The command above is the authoritative final build/deployment path required by the assignment.
