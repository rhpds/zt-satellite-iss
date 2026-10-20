#!/bin/sh
echo "Solving 02-iss-export" >> /tmp/progress.log

# Create a new CV "ISS Export" containing "My custom repository" and
# publish and promote it to the Library lifecycle environment.
tee ~/createandpublishissexport.yml << EOF
---
- name: Create a new CV "ISS Export".
  hosts: localhost
  remote_user: root

  tasks:
  - name: "Create ISS Export content view"
    redhat.satellite.content_view:
      username: "admin"
      password: "bc31c9a6-9ff0-11ec-9587-00155d1b0702"
      server_url: "https://satellite.lab"
      name: "ISS Export"
      organization: "Acme Org"
      repositories:
        - name: 'My custom repository'
          product: 'My custom product'

  - name: "Publish and promote ISS Export to Library lifecycle environment"
    redhat.satellite.content_view_version:
      username: "admin"
      password: "bc31c9a6-9ff0-11ec-9587-00155d1b0702"
      server_url: "https://satellite.lab"
      organization: "Acme Org"
      content_view: "ISS Export"
      lifecycle_environments:
        - "Library"
EOF

ansible-playbook createandpublishissexport.yml

# Export the "ISS Export" content view as an ISS export.
hammer content-export complete version --content-view "ISS Export" --version "1.0" --organization "Acme Org"

echo "Solved 02-iss-export" >> /tmp/progress.log
