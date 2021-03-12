# Terraform

This project uses terraform workspaces https://app.terraform.io/.

User terraform cli to setup locally.

```shell script
terraform init
# terraform workspace list
# terraform workspace select prod|stage

terraform plan | apply # to make changes
```

# EKS Cluster 

## Configure kubectl

To configure kubectl, you need both [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) and [AWS IAM Authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html).

The following command will get the access credentials for your cluster and automatically
configure `kubectl`.


```shell
$ aws eks --region us-west-2 update-kubeconfig
```

You can view these outputs again by running:

```shell
$ terraform output
```


## Deploy and access Kubernetes Dashboard

To verify that your cluster is configured correctly and running, you will install a Kubernetes dashboard and navigate to it in your local browser. 

### Deploy Kubernetes Metrics Server

The Kubernetes Metrics Server, used to gather metrics such as cluster CPU and memory usage
over time, is not deployed by default in EKS clusters.

Download and unzip the metrics server by running the following command.

```shell
helm install metrics-server stable/metrics-server \
  --namespace kube-system \
  -f metrics-server/values.yaml
```
### Deploy Kube2IAM

```shell
kubectl apply -f kube2iam/serviceaccount.yaml
kubectl apply -f kube2iam/clusterrole.yaml
kubectl apply -f kube2iam/daemonset.yaml
```

### Deploy autoscaler
```
helm install cluster-autoscaler --namespace kube-system autoscaler/cluster-autoscaler-chart --values=cluster-autoscaler-chart-values.yaml
```
