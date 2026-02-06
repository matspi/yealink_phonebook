## Phonebook

A small web-app for maintaining a phone book

### Frontend

Data shall be changeable via a web frontend
Not authentiucation or authorization is necessary
Only need a table where we can enter a _name_ and up to 3 associated phone numbers

### Backend
The data shall be kept in an SQlite database

Apart from the endpoints for the frontend, we need to serve the data as an XML file which will be consumed by Yealink IP phones
Details for the XML format can be found here: https://support.yealink.com/document-detail/27505959170c49b9a71938534e666998

### Deployment

The application shall be deployed to a proxmox LXC

### Infrastructre

The code shall be hosted on github.
Crate ci workflows for testing and probably packaging.
ALso create a workflow for using claude code through github issues