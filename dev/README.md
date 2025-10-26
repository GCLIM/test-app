# Method 1: Helm install
Use `helm-install.sh` to prep the namespace.
- configmap
- rolebinding

To create `service account`, run the following command:
```
kubectl create serviceaccount test-app-sa -n test-app-namespace
```

# Method 2: Use raw manifest files
The raw manifest files are stored under `kiv` folder.
- configmap
- rolebinding
- serviceaccount
