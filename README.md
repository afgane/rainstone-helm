A Helm chart for the Rainstone app - an estimator of cloud costs for
bioinformatics tools and Galaxy workflows. See the
[rainstone-ui](https://github.com/afgane/rainstone-ui/) and
[rainstone-api]((https://github.com/afgane/rainstone-api/) repos for the web UI
and backend API.

## Chart deployment prerequisites

Ensure that the NGINX Ingress Controller is installed in the cluster. If not, install it using:

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

## Installing the chart

Take a look at the `values.yaml` file to see the available configuration
options. Will probably need to set hostnames.

Install the chart with:

```
helm install rainstone ./rainstone-helm
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
request the TLS certificate. To start, we'll test with the staging issuer. Set
`ingress.annotations` to: `cert-manager.io/cluster-issuer:
"letsencrypt-staging"`, set hosts, and tls entries. Then update the chart with:

```sh
helm upgrade -f values.yaml rainstone ./rainstone-helm
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
