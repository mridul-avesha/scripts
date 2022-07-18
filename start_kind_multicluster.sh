#!/bin/bash

set -euo pipefail

if [ $(kind get clusters | grep controller) ];then
  echo \
'cluster already exists, skipping creation..
Run the following to generate kubeconfig for the same

  kind get kubeconfig --name controller > assets/kubeconfig/kind.yaml

Then run `./run.sh` to start e2e tests
'
  exit 0
fi

clusters=(controller worker-1 worker-2)
output_loc=assets/kubeconfig/config

for cluster_name in ${clusters[@]}
do
    kind create cluster --name $cluster_name --config assets/kind/cluster.yaml --image kindest/node:v1.22.7
done

# Provide correct IP in kind profile, since worker operator cannot detect internal IP as nodeIp
# sed -i "s/NodeIP:.*/NodeIP: $ip/g" profile/mg.yaml

cp ~/.kube/config $output_loc

for i in ${!clusters[@]}
do
    ip=$(docker inspect ${clusters[$i]}-control-plane | jq -r '.[0].NetworkSettings.Networks.kind.IPAddress')
    yq -i ".clusters[$i].cluster.server=\"https://$ip:6443\"" $output_loc
done
