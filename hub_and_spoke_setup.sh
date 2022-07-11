sudo sysctl fs.inotify.max_user_watches=524288
sudo sysctl fs.inotify.max_user_instances=512

cc=controller
wc1=worker1
wc2=worker2
kind create cluster --name $cc --config controller.yaml
kind create cluster --name $wc1 --config worker.yaml
kind create cluster --name $wc2 --config worker.yaml

for c in $cc $wc1 $wc2
do
  kctx kind-$c
  kubectl create -f https://projectcalico.docs.tigera.io/manifests/tigera-operator.yaml
  curl https://projectcalico.docs.tigera.io/manifests/custom-resources.yaml -O
  kubectl create -f custom-resources.yaml
  kubectl get ns
  kubectl get pods -n calico-system
done

helm repo add kubeslice https://kubeslice.github.io/charts/
helm repo update
helm search repo kubeslice

kctx kind-$cc
helm install cert-manager kubeslice/cert-manager --namespace cert-manager  --create-namespace --set installCRDs=true
kubectl get pods -n cert-manager
kubectl get nodes -o wide

kctx kind-$cc
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $cc-control-plane | xargs -I{} yq -i '.kubeslice.controller.endpoint = "https://{}:6443"'  values.yaml
helm install kubeslice-controller kubeslice/kubeslice-controller -f values.yaml --namespace kubeslice-controller --create-namespace
kubectl get pods -n kubeslice-controller

kubectl apply -f project.yaml -n kubeslice-controller
kubectl get project -n kubeslice-controller

kctx kind-$cc
kubectl apply -f worker_registration.yaml -n kubeslice-avesha

kctx kind-$cc
for w in $wc1 $wc2
do
	sh secrets.sh $(kubectl get secrets -n kubeslice-avesha -o name|grep $w | cut -d / -f 2) kind-$w kubeslice-avesha > slice_operator_$w.yaml
	docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $w-control-plane | xargs -I{} yq -i '.cluster.nodeIp = "{}"' slice_operator_$w.yaml
done

for w in $wc1 $wc2
do
	kctx kind-$w
	helm upgrade --install kubeslice-worker kubeslice/kubeslice-worker -f slice_operator_$w.yaml --namespace kubeslice-system  --create-namespace
	kubectl get pods -n kubeslice-system
done
