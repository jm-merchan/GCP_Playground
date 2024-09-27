Let's deploy Vault in GKE, with options for both autopilot and standard GKE. To that end we are going to use [this](https://cloud.google.com/kubernetes-engine/docs/quickstarts/create-cluster-using-terraform) Google Cloud doc as reference. 

* The first thing is to enable the GKE API
* Next, let's prepare our cli environment

```bash
rm -rf ~/.config/gcloud
gcloud auth application-default login
gcloud auth login && gcloud components update
```
