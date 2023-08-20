# Kaniko

## Overview

Tool developed by Google (not supported) written in Go. Builds container images from a dockerfile (plus other operations), where the build process is done inside a container in k8s which does not depend on a Docker daemon. This ensures a build process in a user namespace more secure and less privileged than a docker process, where you need to give root privileges. So you can run kaniko for building container in a non privileged space like k8s (GKE etc.)

Build process works as following:

- Kaniko executor image only contains the Go binary and the utility needed to execute and push the build

- For each Dockerfile stage (the FROM instruction) the base-image is extracted to root in a local directory (./kaniko/{image})

- For each instruction in the stage it is executed in order, and a snapshot of the file system is taken (as a diff of the previous file system stage), appending a layer of changed file to the bases image and updating image metadata

- After executing each step in the stage, the base file image is deleted

- After executing the Dockerfile, the final image is pushed to the docker registry

Every step of the build process is entirely executed in the userspace within the executor image of Kaniko, without privileged access to the local machine (dockerd or CLI are never involved).


<b> Build Windows container is not supported </b>

Kaniko executor needs a build context containing a Dockerfile and any file that Dockerfile needs (COPY commands) in the same build context. Build context must be accessible from Kaniko (bucket, local directory mounted in kaniko container, standard input, git repo).

Kaniko can also cache layers on remote repository, fetching them in case of cache hit on checksum instead of executing the Dockerfile instructions.

The Kaniko default image does not contain a shell, for debugging purposes a dedicated debug image is provided with an additional busybox shell to enter and debug


## Quickstart minikube (with local cache) + Dockerhub


### Create env variables:

```
export DOCKERHUB_REGISTRY=<dockerhub_username>/<repo_name>
export LOCAL_CONTEXT_DIRECTORY=$(pwd)/local-demo/app
export LOCAL_CACHE_DIRECTORY=/tmp/kaniko-cache
```

### Start minikube cluster and mount directories to minikube machine

```
minikube start
minikube mount $LOCAL_CONTEXT_DIRECTORY:/minikube-dockerfile &
minikube mount $LOCAL_CACHE_DIRECTORY:/minikube-cache &
```


### Create secret storing docker registry credentials, used by kaniko

```
kubectl create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ --docker-username=<your-name> --docker-password=<your-pword> --docker-email=<your-email>
```

### Create kaniko resources and check for image being build and pushed to remote registry

```
kubectl apply -f local-demo/local-cache.yaml
kubectl apply -f local-demo/pv-pvc.yaml
envsubst < local-demo/kaniko.yaml | kubectl apply -f -

kubectl logs kaniko -f
```

## Quickstart GKE + GCP Artifact Registry + GCS

Create env variables

```
export GCP_PROJECT_ID=<GCP_PROJECT_ID>
export GCP_REGION=<GCP_REGION>
export GCP_ZONE=<GCP_ZONE>
export GCP_GKE=<GCP_GKE>
```

Create GCP resources

```
cd gke-ar/tf-setup
terraform init
terraform plan
terraform apply
cd ../../
```

Prepare the tar.gz archive to upload to cloud storage

```
tar -C ./gke-ar/app* -cvf ./gke-ar/context.tar.gz Dockerfile
gsutil cp ./gke-ar/context.tar.gz gs://$GCP_PROJECT_ID-$GCP_GKE
```

Create the kaniko pod

```
gcloud container clusters get-credentials $GCP_GKE --zone $GCP_ZONE --project $GCP_PROJECT_ID

envsubst < ./gke-ar/kaniko.yaml | kubectl apply -f -
```


## Reference 

- https://github.com/GoogleContainerTools/kaniko

- https://cloud.google.com/blog/products/containers-kubernetes/introducing-kaniko-build-container-images-in-kubernetes-and-google-container-builder-even-without-root-access