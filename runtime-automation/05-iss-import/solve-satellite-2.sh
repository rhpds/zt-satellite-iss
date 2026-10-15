#!/bin/sh
echo "Solving 05-iss-import" >> /tmp/progress.log

# Change the ownership of the imported data to the pulp account and
# group, then import the exported data.
chown -R pulp:pulp /var/lib/pulp/imports/Acme_Org/

hammer content-import version --organization "Acme Org" --path "/var/lib/pulp/imports/Acme_Org"

echo "Solved 05-iss-import" >> /tmp/progress.log
