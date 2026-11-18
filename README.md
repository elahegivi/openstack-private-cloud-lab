
# OpenStack Private Cloud Lab

### Cloud Infrastructure | Compute | Networking | Storage | Identity

## Overview

A technical portfolio focused on OpenStack private cloud architecture, infrastructure administration, virtual networking, compute, storage, identity management, and operational troubleshooting.

The project draws on academic hands-on experience with OpenStack at Hochschule Fulda (Fulda University of Applied Sciences), Germany, and broader IT infrastructure engineering experience.

It provides architecture documentation, administration procedures, OpenStack CLI examples, and reusable operational scripts.

## Technology Stack

| Technology | Purpose |
|---|---|
| Keystone | Identity and access management |
| Nova | Virtual machine lifecycle management |
| Neutron | Virtual networking and routing |
| Glance | Virtual machine image management |
| Cinder | Block storage and volume management |
| Horizon | Web-based cloud administration |
| OpenStackClient | Command-line administration |
| KVM / libvirt | Virtualization infrastructure |
| Bash | Operational scripting |

## Architecture

The reference architecture covers:

- OpenStack controller services
- Compute nodes and hypervisors
- Management and tenant networking
- External/provider network connectivity
- Image and block storage services
- Identity, authentication, and authorization

[Explore OpenStack Architecture](docs/architecture.md)

## Technical Documentation

| Module | Description |
|---|---|
| [Architecture](docs/architecture.md) | Private cloud components, topology, and service interactions |
| [Keystone Identity](docs/keystone-identity.md) | Users, projects, roles, and authentication |
| [Nova Compute](docs/nova-compute.md) | VM provisioning, flavors, lifecycle operations |
| [Neutron Networking](docs/neutron-networking.md) | Networks, subnets, routers, security groups, and floating IPs |
| [Glance Images](docs/glance-images.md) | Image upload, formats, verification, and management |
| [Cinder Storage](docs/cinder-storage.md) | Volumes, attachments, snapshots, and capacity expansion |
| [Troubleshooting](docs/troubleshooting.md) | Service health checks, incident investigation, and diagnostics |

## Operational Scripts

### OpenStack Health Check

[View Health Check Script](scripts/openstack-health-check.sh)

Read-only checks for:

- Keystone authentication
- OpenStack service catalog
- Nova Compute API
- Neutron Networking API
- Glance Image API
- Cinder Block Storage API

Example usage:

```bash
bash scripts/openstack-health-check.sh
```

### OpenStack Inventory Reporting

[View Inventory Reporting Script](scripts/openstack-inventory-report.sh)

Collects project-accessible resource information in JSON format:

- Instances
- Networks
- Subnets
- Routers
- Images
- Volumes
- Security groups

Example usage:

```bash
bash scripts/openstack-inventory-report.sh
```

Both scripts require OpenStackClient and an authenticated OpenStack environment.

## Network Design

The networking documentation covers a reference topology with private tenant networks, virtual routers, security groups, and external connectivity.

It also compares OpenStack Neutron concepts with traditional enterprise networking technologies.

[Explore Neutron Networking](docs/neutron-networking.md)

## Operations & Troubleshooting

Operational procedures cover common infrastructure incidents:

- Authentication failures
- VM scheduling and provisioning issues
- Virtual network connectivity failures
- Floating IP routing problems
- Image provisioning errors
- Storage attachment failures
- Service availability and log investigation

[Explore Troubleshooting Guide](docs/troubleshooting.md)

## Repository Structure

```text
openstack-private-cloud-lab/
├── docs/
│   ├── architecture.md
│   ├── keystone-identity.md
│   ├── nova-compute.md
│   ├── neutron-networking.md
│   ├── glance-images.md
│   ├── cinder-storage.md
│   └── troubleshooting.md
├── scripts/
│   ├── openstack-health-check.sh
│   └── openstack-inventory-report.sh
├── .gitignore
└── README.md
```

## Security Considerations

- Use dedicated project-scoped accounts.
- Apply role-based access control.
- Restrict management and administrative access.
- Protect authentication credentials and tokens.
- Use trusted operating system images.
- Apply security groups to control traffic.
- Avoid publishing private keys and infrastructure secrets.
- Review generated reports before sharing.

## Academic Background

The portfolio builds on academic exposure to OpenStack private cloud technologies during the Global Software Development master's program at Hochschule Fulda, Germany.

The public examples use generic configurations and documentation-only addresses rather than university or enterprise infrastructure details.

## About

A technical portfolio covering OpenStack private cloud administration, infrastructure operations, virtualization, networking, storage, troubleshooting, and automation.
