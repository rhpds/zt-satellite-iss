#!/bin/sh
echo "Solving 03-iss-export" >> /tmp/progress.log

# Export the "ISS Export" content view as an ISS export.
hammer content-export complete version --content-view "ISS Export" --version "1.0" --organization "Acme Org"

echo "Solved 03-iss-export" >> /tmp/progress.log
