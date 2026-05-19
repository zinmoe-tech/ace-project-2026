kubectl get deployment -A --show-labels | grep grc
grc-team              grc-istio-ingressgateway              1/1     1            1           76m   app.kubernetes.io/instance=istio,
app.kubernetes.io/managed-by=Helm,
app.kubernetes.io/name=istio-ingressgateway,
app.kubernetes.io/part-of=istio,
app.kubernetes.io/version=1.29.2,
app=istio-ingressgateway,
helm.sh/chart=istio-ingress-1.29.2,install.operator.istio.io/owning-resource-namespace=istio-system,
install.operator.istio.io/owning-resource=unknown,
istio.io/dataplane-mode=none,i
stio.io/rev=default,
istio=ingressgateway,
operator.istio.io/component=IngressGateways,
operator.istio.io/managed=Reconcile,
operator.istio.io/version=1.29.2,release=istio