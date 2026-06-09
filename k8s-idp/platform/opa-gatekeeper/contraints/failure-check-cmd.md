kubectl describe rs sanction-svc-57744b7bff -n grc-team 2>&1 | sed -n '/Events:/,$p'

kubectl get events -n grc-team --sort-by=.lastTimestamp 2>&1 | grep -i sanction | tail -5

kubectl get deploy sanction-svc -n grc-team -o jsonpath='image={.spec.template.spec.containers[0].image}{"\n"}resources={.spec.template.spec.containers[0].resources}{"\n"}labels={.spec.template.metadata.labels}{"\n"}securityContext={.spec.template.spec.securityContext}{"\n"}' 2>&1

