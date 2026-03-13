A Helm chart for the Rainstone app - an estimator of cloud costs for
bioinformatics tools and Galaxy workflows. See the
[rainstone-ui](https://github.com/afgane/rainstone-ui/) and
[rainstone-api](https://github.com/afgane/rainstone-api/) repos for the web UI
and backend API.

## Chart deployment prerequisites

Ensure that the NGINX Ingress Controller is installed in the cluster. If not, install it using:

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

## Installing the chart

Take a look at the `values.yaml` file to see the available configuration
options. Will probably need to set hostnames or a path prefix.

Install the chart with:

```
helm install rainstone .
```

### Serving the UI from a path prefix

The chart supports serving the UI from a non-root path via
`frontend.basePath`. For example, to serve the app from `/rainstone/`, the
backend will automatically be reached through `/rainstone/api`.

Example override values to use a path prefix:

```yaml
frontend:
  basePath: /rainstone
```

Install or upgrade with:

```sh
helm upgrade --install rainstone . \
  --namespace rainstone \
  --create-namespace \
  --set frontend.basePath=/rainstone
```

The chart will automatically adjust the Ingress paths and inject the correct
configuration into the UI and API.

Verification:

```sh
kubectl -n rainstone get all,ingress
curl http://<public-ip>/<base-path>/
curl http://<public-ip>/<base-path>/api/
```

### Setting a TLS certificate

If wanting to serve the app over https, we'll need to set up a cert manager.
Start by installing it:

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.15.3 \
  --set installCRDs=true
```

Create a certificate issuer on the cluster. There are 2 files in this repo, one
for a dev staging issuer and one for production: `staging-issuer.yaml` and
`production-issuer.yaml` respectively. Apply the issuers and check that they
installed correctly:

```
kubectl apply -f staging-issuer.yaml
kubectl apply -f production-issuer.yaml

kubectl describe clusterissuer letsencrypt-staging
kubectl describe clusterissuer letsencrypt-prod
```

Next we need to update the `values.yaml` file to include the issuer name and
request the TLS certificate. Make sure the ingress hosts and `ingress.tls`
entries exactly match the DNS names you want on the certificate. To start,
we'll test with the staging issuer. Set `ingress.annotations` to:
`cert-manager.io/cluster-issuer: "letsencrypt-staging"`, set hosts, and tls
entries. Then update the chart with:

```sh
helm upgrade --install rainstone . \
  --namespace rainstone \
  --create-namespace \
  -f values.yaml
```

If the certificate stays pending and the HTTP-01 challenge is getting the app
page or an HTTPS redirect instead of the solver token, disable nginx redirect
on the application ingress during issuance by adding:

```yaml
ingress:
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
```

Once the certificate is issued, verify both the certificate and the ingress:

```sh
kubectl -n rainstone get ingress,certificate,certificaterequest,challenge,order
curl -I https://rainstone.cloudve.org/
curl -I https://rainstone.anvilproject.org/
```

Check that the certificate was issued:

```sh
kubectl get certificate
```

If it worked, `Ready` should be `True`. If it's `False`, check the logs of the

```sh
kubectl describe certificate rainstone-tls
```

Once it is all set, update the `values.yaml` file to use the production issuer
and update the chart again.
