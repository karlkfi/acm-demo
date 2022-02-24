# Anthos Config Management Demo - Feb 2021

Hosted Services:
- ACM: Config Sync
- ACM: Policy Controller (TODO)

Managed Services:
- Google Kubernetes Engine (GKE)
- ACM: Config Controller
  - Feature: Config Connector (KCC)
- Anthos Fleet
  - Feature: Anthos Config Management (ACM)
  - Feature: Multi Cluster Ingress (MCI)
- HTTP Load Balancer
- Virtual Private Network (VPC)
  - Feature: Subnetwork
  - Feature: Cloud NAT
- Project

Tools:
- gcloud
- kpt
- nomos

## Walkthrough

### Config Controller

Create the following with the GCP Console or gcloud CLI:

- Project
- Network
- Firewall for public egress
- Config Controller instance
- Role Binding to authorize KCC on CC in config-control namespace to manage the project

### Infrastructure

Configure the following with kpt from [blueprints](https://github.com/GoogleCloudPlatform/blueprints):

- Network
- 2x Subnets (east & west regions)
- 2x GKE clusters (east & west regions)
- 2x Fleet Membership of GKE clusters
- 2x ACM install on GKE cluster
- Configure MCI to use the west cluster for fleet config

### Platform

Configure the following from [tutorial](https://github.com/GoogleCloudPlatform/anthos-config-management-samples/tree/main/multi-cluster-ingress):

- [GitHub repo for platform config](https://github.com/karlkfi/acm-examples-platform)
  - 2x Cluster Roles to allow view/edit of GKE networking resources
  - Namespace (zoneprinter)
    - RepoSync for Config Sync to sync from app repo (zoneprinter)
    - Role Binding to authorize Config Sync to manage GKE networking resources

### Application

Configure the following from [tutorial](https://github.com/GoogleCloudPlatform/anthos-config-management-samples/tree/main/multi-cluster-ingress):

- [GitHub repo for application config (zoneprinter)](https://github.com/karlkfi/acm-examples-zoneprinter)
  - Deployment (east and west clusters)
  - MultiClusterIngress config (west cluster)
