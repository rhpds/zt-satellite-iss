#!/bin/sh
echo "Solving 04-copy-export" >> /tmp/progress.log

# Copy the exported data to satellite-2.lab.
scp -o "StrictHostKeyChecking no" -rp /var/lib/pulp/exports/Acme_Org/ISS_Export/1.0/*/ root@satellite-2.lab:/var/lib/pulp/imports/Acme_Org/

echo "Solved 04-copy-export" >> /tmp/progress.log
