#!/bin/sh
echo "Solving 06-iss-network-sync" >> /tmp/progress.log

# Download and import the upstream satellite.lab SSL certificate.
wget -P ~ http://satellite.lab/pub/katello-server-ca.crt

hammer content-credential create \
--content-type cert \
--name "satellite.lab" \
--organization "Acme Org" \
--path ~/katello-server-ca.crt

echo "Solved 06-iss-network-sync" >> /tmp/progress.log
