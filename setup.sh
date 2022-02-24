

export PROJECT_ID="acm-demo-2022"

export NETWORK="default"

gcloud compute networks create "${NETWORK}" \
    --project ${PROJECT_ID}

gcloud compute firewall-rules create allow-all-internal \
    --network ${NETWORK} \
    --allow tcp,udp,icmp \
    --source-ranges 10.0.0.0/8 \
    --project ${PROJECT_ID}

gcloud services enable krmapihosting.googleapis.com \
    container.googleapis.com \
    cloudresourcemanager.googleapis.com \
    --project ${PROJECT_ID}

gcloud anthos config controller create demo \
    --location us-east1 \
    --network ${NETWORK} \
    --project ${PROJECT_ID}

CC_CONTEXT=$(kubectl config current-context)

export SA_EMAIL="$(kubectl get ConfigConnectorContext -n config-control \
    -o jsonpath='{.items[0].spec.googleServiceAccount}' 2> /dev/null)"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member "serviceAccount:${SA_EMAIL}" \
    --role "roles/owner" \
    --project "${PROJECT_ID}"

export NETWORK="demo"

kpt pkg init

kpt live init --namespace config-control

kpt pkg get https://github.com/GoogleCloudPlatform/blueprints/tree/main/catalog/networking/network

rm vpn.yaml
rm -rf network/subnet/

kpt pkg get https://github.com/GoogleCloudPlatform/blueprints/tree/main/catalog/networking/network/subnet network/subnet-us-east4

kpt pkg get https://github.com/GoogleCloudPlatform/blueprints/tree/main/catalog/networking/network/subnet network/subnet-us-west4

cat > network/setters.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata: # kpt-merge: /setters
  name: setters
  annotations:
    config.kubernetes.io/local-config: "true"
data:
  project-id: ${PROJECT_ID}
  network-name: ${NETWORK}
  region: us-central1
  namespace: config-control
  prefix: ""
EOF

kpt fn render network

export REGION="us-east4"

cat > network/subnet-${REGION}/setters.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata: # kpt-merge: /setters
  name: setters
  annotations:
    config.kubernetes.io/local-config: "true"
data:
  network-name: ${NETWORK}
  region: ${REGION}
  prefix: ${REGION}-
  ip-cidr-range: 10.2.0.0/16
  source-subnetwork-ip-ranges-to-nat: LIST_OF_SUBNETWORKS
EOF

vim network/subnet-${REGION}/nat.yaml 
subnetworks:
  - name: us-west4-demo-subnetwork # kpt-set: ${prefix}${network-name}-subnetwork
  sourceIpRangesToNat:
  - ALL_IP_RANGES

vim network/subnet-${REGION}/subnet.yaml 
secondaryIpRange:
- ipCidrRange: 172.17.0.0/16
  rangeName: pods
- ipCidrRange: 172.18.0.0/16
  rangeName: services

kpt fn render network/subnet-${REGION}

export REGION="us-west4"

cat > network/subnet-${REGION}/setters.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata: # kpt-merge: /setters
  name: setters
  annotations:
    config.kubernetes.io/local-config: "true"
data:
  network-name: ${NETWORK}
  region: ${REGION}
  prefix: ${REGION}-
  ip-cidr-range: 10.3.0.0/16
  source-subnetwork-ip-ranges-to-nat: LIST_OF_SUBNETWORKS
EOF

vim network/subnet-${REGION}/nat.yaml 
subnetworks:
  - name: us-west4-demo-subnetwork # kpt-set: ${prefix}${network-name}-subnetwork
  sourceIpRangesToNat:
  - ALL_IP_RANGES

vim network/subnet-${REGION}/subnet.yaml 
secondaryIpRange:
- ipCidrRange: 172.19.0.0/16
  rangeName: pods
- ipCidrRange: 172.20.0.0/16
  rangeName: services

kpt fn render network/subnet-${REGION}

# hack to fix services.yaml which is missing a setter
kpt fn eval --image gcr.io/kpt-fn/set-namespace:v0.2.0 network -- 'namespace=config-control'

kpt live apply --output table

export EMAIL_DOMAIN="environblueprint.joonix.net"
export REGION="us-east4"

kpt pkg get https://github.com/GoogleCloudPlatform/blueprints/tree/main/catalog/gke gke-east

cat > gke-east/setters.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata: # kpt-merge: /setters
  name: setters
  annotations:
    config.kubernetes.io/local-config: "true"
data:
  project-id: ${PROJECT_ID}
  cluster-name: demo-${REGION}
  location: ${REGION}
  master-ip-range: 10.254.0.0/28
  network-ref: projects/${PROJECT_ID}/global/networks/${NETWORK}
  subnet-ref: projects/${PROJECT_ID}/regions/${REGION}/subnetworks/${REGION}-${NETWORK}-subnetwork
  pods-range-name: pods
  services-range-name: services
  security-group: gke-security-groups@${EMAIL_DOMAIN}
EOF

kpt fn render gke-east

export REGION="us-west4"

kpt pkg get https://github.com/GoogleCloudPlatform/blueprints/tree/main/catalog/gke gke-west

cat > gke-west/setters.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata: # kpt-merge: /setters
  name: setters
  annotations:
    config.kubernetes.io/local-config: "true"
data:
  project-id: ${PROJECT_ID}
  cluster-name: demo-${REGION}
  location: ${REGION}
  master-ip-range: 10.254.0.16/28
  network-ref: projects/${PROJECT_ID}/global/networks/${NETWORK}
  subnet-ref: projects/${PROJECT_ID}/regions/${REGION}/subnetworks/${REGION}-${NETWORK}-subnetwork
  pods-range-name: pods
  services-range-name: services
  security-group: gke-security-groups@${EMAIL_DOMAIN}
EOF

kpt fn render gke-west

kpt live apply --output table

export GITHUB_USER_NAME=karlkfi
export GITHUB_REPO_NAME=acm-examples-platform

export PLATFORM_REPO_HTTPS="https://github.com/${GITHUB_USER_NAME}/${GITHUB_REPO_NAME}/"
export PLATFORM_REPO_SSH="git@github.com:${GITHUB_USER_NAME}/${GITHUB_REPO_NAME}.git"

export REGION="us-west4"

kpt pkg get https://github.com/GoogleCloudPlatform/blueprints/tree/main/catalog/acm gke-west-acm

cat > gke-west-acm/setters.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata: # kpt-merge: /setters
  name: setters
  annotations:
    config.kubernetes.io/local-config: "true"
data:
  project-id: ${PROJECT_ID}
  cluster-name: demo-${REGION}
  location: ${REGION}
  sync-repo: https://github.com/karlkfi/acm-examples-platform/
EOF

vim gke-west-acm/config-mgmt-csr.yaml
      git:
        syncRepo: https://github.com/${GITHUB_USER_NAME}/${GITHUB_REPO_NAME}/ # kpt-set: ${sync-repo}
        syncBranch: main
        policyDir: configsync/clusters/cluster-west
        secretType: none

vim gke-west-acm/config-mgmt-iam.yaml
# delete IAMPartialPolicy source-reader-

mv gke-west-acm/config-mgmt-csr.yaml gke-west-acm/config-mgmt-github.yaml

kpt fn render gke-west-acm

kpt live init --namespace config-control gke-west-acm

kpt live apply gke-west-acm

export REGION="us-east4"

kpt pkg get https://github.com/GoogleCloudPlatform/blueprints/tree/main/catalog/acm gke-east-acm

cat > gke-east-acm/setters.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata: # kpt-merge: /setters
  name: setters
  annotations:
    config.kubernetes.io/local-config: "true"
data:
  project-id: ${PROJECT_ID}
  cluster-name: demo-${REGION}
  location: ${REGION}
  sync-repo: https://github.com/${GITHUB_USER_NAME}/${GITHUB_REPO_NAME}/
EOF

vim gke-east-acm/config-mgmt-csr.yaml
      git:
        syncRepo: https://github.com/${GITHUB_USER_NAME}/${GITHUB_REPO_NAME}/ # kpt-set: ${sync-repo}
        syncBranch: main
        policyDir: configsync/clusters/cluster-east
        secretType: none

vim gke-east-acm/config-mgmt-iam.yaml
# delete IAMPartialPolicy source-reader-

mv gke-east-acm/config-mgmt-csr.yaml gke-east-acm/config-mgmt-github.yaml

kpt fn render gke-east-acm

kpt live init --namespace config-control gke-east-acm

kpt live apply gke-east-acm

gcloud container clusters get-credentials demo-us-east4 --region us-east4 \
  --project ${PROJECT_ID}
CLUSTER_EAST_CONTEXT=$(kubectl config current-context)

kubectl get ConfigManagement -n config-control -o yaml
kubectl get RootSync -n config-management-system -o yaml

gcloud container clusters get-credentials demo-us-west4 --region us-west4 \
  --project ${PROJECT_ID}
CLUSTER_WEST_CONTEXT=$(kubectl config current-context)

kubectl get ConfigManagement -n config-control -o yaml
kubectl get RootSync -n config-management-system -o yaml

## Enable MCI

kubectx ${CC_CONTEXT}

mkdir mci

kpt pkg init mci
kpt live init --namespace config-control mci

cat > mci/mci.yaml << EOF
apiVersion: gkehub.cnrm.cloud.google.com/v1beta1
kind: GKEHubFeature
metadata:
  name: feat-mci
  namespace: config-control
spec:
  projectRef:
    external: acm-demo-2022
  location: global
  resourceID: multiclusteringress
  spec:
    multiclusteringress:
      configMembershipRef:
        name: hub-membership-demo-us-west4
EOF

cat > mci/services.yaml << EOF
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  name: acm-demo-2022-mci
  namespace: config-control
  annotations:
    cnrm.cloud.google.com/project-id: acm-demo-2022
    cnrm.cloud.google.com/deletion-policy: abandon
spec:
  resourceID: multiclusteringress.googleapis.com
---
# TODO: MCSD should not be required for MCI, but is for some reason...
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  name: acm-demo-2022-mcsd
  namespace: config-control
  annotations:
    cnrm.cloud.google.com/project-id: acm-demo-2022
    cnrm.cloud.google.com/deletion-policy: abandon
spec:
  resourceID: multiclusterservicediscovery.googleapis.com
EOF

kpt live apply mci --output table

## Platform Repo
## Switch to new Tab

cd ~/workspace
git clone git@github.com:${GITHUB_USER_NAME}/${GITHUB_REPO_NAME}.git
cd ${GITHUB_REPO_NAME}

# copy from tutorial repo
cp -r ~/workspace/anthos-config-management-samples/multi-cluster-ingress/repos/platform/* ./

./scripts/render.sh

git add .
git commit -m "init config"
git push

nomos status

## Zonerinter Repo
## Switch to new Tab

export GITHUB_USER_NAME=karlkfi
export GITHUB_REPO_NAME=acm-examples-zoneprinter
export ZONEPRINTER_REPO_HTTPS="https://github.com/${GITHUB_USER_NAME}/${GITHUB_REPO_NAME}/"

cd ~/workspace
git clone git@github.com:${GITHUB_USER_NAME}/${GITHUB_REPO_NAME}.git
cd ${GITHUB_REPO_NAME}

# copy from tutorial repo
cp -r ~/workspace/anthos-config-management-samples/multi-cluster-ingress/repos/zoneprinter/* ./

./scripts/render.sh

git add .
git commit -m "init config"
git push

nomos status

## Switch to main Tab

gcloud container clusters get-credentials demo-us-west4 --region us-west4 \
  --project ${PROJECT_ID}
CLUSTER_WEST_CONTEXT=$(kubectl config current-context)

INGRESS_VIP="$(
  kubectl get MultiClusterIngress zoneprinter \
    -n zoneprinter \
    --context ${CLUSTER_WEST_CONTEXT} \
    -o=custom-columns=VIP:.status.VIP \
    --no-headers
)"

curl -L "http://${INGRESS_VIP}/ping"
