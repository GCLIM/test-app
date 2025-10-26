helm install namespace-prep cyberark/conjur-config-namespace-prep \
  --namespace test-app-namespace \
  --set authnK8s.goldenConfigMap="conjur-configmap" \
  --set authnK8s.namespace="cyberark-conjur"