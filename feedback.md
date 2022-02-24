
The gke network blueprint comes with a single subnet and has to be modified to use multiple regional subnets.

The nat in the subnet blueprint comes with ALL_SUBNETWORKS_ALL_IP_RANGES, which doesn't work with multiple subnets and needs to be modified to use LIST_OF_SUBNETWORKS and a subnetwork list.

The acm blueprint uses the config-control namespace but the network/vpc blueprint uses the projects namespace.

When I'm only managing one project with config-control, it's easier to have all the resources in the config-control namespace.

There's no mci blueprint.

Many blueprints use setters specified in their parent's setters.yaml, which make it a little harder to use them without their parent.

kpt fn render doesn't fail when setters are unset.

