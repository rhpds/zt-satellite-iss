#!/bin/bash

# Download the hello RPM. It is uploaded to "My custom repository" below.
wget -P /root https://github.com/myee111/hello-rpm/releases/download/0.0.1/hello-0.0.1-1.el9.noarch.rpm

# Create the custom product and repository required by the ISS export
# modules.
hammer product create --name "My custom product" --organization "Acme Org"
hammer repository create --name "My custom repository" --content-type yum --product "My custom product" --organization "Acme Org"
hammer repository upload-content --path /root/hello-0.0.1-1.el9.noarch.rpm --name "My custom repository" --product "My custom product" --organization "Acme Org"
