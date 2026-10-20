#!/bin/sh
echo "Solving 03-iss-import" >> /tmp/progress.log

# Copy the exported data to satellite-2.lab.
scp -o "StrictHostKeyChecking no" -rp /var/lib/pulp/exports/Acme_Org/ISS_Export/1.0/*/ root@satellite-2.lab:/var/lib/pulp/imports/Acme_Org/

# Change the ownership of the imported data to the pulp account and
# group, then import the exported data on satellite-2.lab.
ssh -o "StrictHostKeyChecking no" -o UserKnownHostsFile=/dev/null root@satellite-2.lab "chown -R pulp:pulp /var/lib/pulp/imports/Acme_Org/ && hammer content-import version --organization 'Acme Org' --path '/var/lib/pulp/imports/Acme_Org'"

echo "Solved 03-iss-import" >> /tmp/progress.log
