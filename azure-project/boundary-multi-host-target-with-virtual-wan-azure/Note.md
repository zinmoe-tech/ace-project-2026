"Branch-to-branch" in Virtual WAN controls routing between branch connections — VPN Sites, ExpressRoute circuits, and Point-to-Site VPN clients — through the hub. It does not affect VNet-to-VNet connectivity.

Your current setup (bastion-vn, boundary-uae-north-vn, boundary-uae-central-india-vn) uses only azurerm_virtual_hub_connection resources — VNet connections, not branch connections. So disabling Branch-to-branch would have zero effect on the ping testing you just did between bastion, intermediate-worker, and target; that connectivity is governed by the hub route table association/propagation I wired up in vhub_connections.tf, which is a separate mechanism.

It only matters once you add an actual VPN gateway, ExpressRoute circuit, or P2S VPN to this hub. At that point:

Enabled: those branches could route to each other through the hub (e.g., two VPN sites reaching one another).
Disabled: each branch could still reach the VNets connected to the hub, but not other branches.


