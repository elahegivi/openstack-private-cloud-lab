
# OpenStack Cinder — Block Storage Management

## 1. Overview

Cinder is the OpenStack Block Storage service responsible for provisioning and managing persistent block storage volumes.

Cinder volumes can be attached to virtual machine instances and managed independently from their ephemeral storage.

This document covers block storage architecture, volume provisioning, attachment, snapshots, capacity expansion, operational security, and troubleshooting.

## 2. Cinder Architecture

```mermaid
flowchart TD
    ADMIN["Cloud Administrator"]
    CLIENT["Horizon / OpenStack CLI"]
    API["Cinder API"]
    SCHED["Cinder Scheduler"]
    VOL["Cinder Volume Service"]
    BACKEND["Storage Backend"]
    NOVA["Nova Compute"]
    VM["Virtual Machine"]

    ADMIN --> CLIENT
    CLIENT --> API
    API --> SCHED
    SCHED --> VOL
    VOL --> BACKEND
    NOVA <--> VOL
    NOVA --> VM
    VM -. "Block Storage Access" .-> BACKEND
```

The diagram illustrates logical service relationships. Actual storage data paths depend on the selected storage driver, backend, and attachment protocol.

## 3. Core Components

| Component | Responsibility |
|---|---|
| Cinder API | Processes block storage API requests |
| Cinder Scheduler | Selects suitable storage backends |
| Cinder Volume | Manages storage volumes and backend operations |
| Storage Backend | Provides physical or virtual block storage |
| Volume Type | Defines storage capabilities and backend selection |
| Nova Compute | Coordinates volume attachment to instances |

Supported storage technologies may include LVM, Ceph RBD, iSCSI storage, and compatible enterprise storage arrays.

## 4. Block Storage Administration Scenario

The following configuration demonstrates persistent storage management for a Linux virtual machine.

| Resource | Example |
|---|---|
| Project | infrastructure-lab |
| Instance | lab-vm01 |
| Volume | lab-data-volume |
| Initial Capacity | 10 GiB |
| Expanded Capacity | 20 GiB |
| Snapshot | lab-data-snapshot |
| Restored Volume | lab-restored-volume |
| Purpose | Persistent application data |

The data volume is separate from the virtual machine's root disk.

## 5. Prerequisites

Volume administration requires:

- A working OpenStack Block Storage service
- Valid OpenStack authentication
- A configured storage backend
- Sufficient storage capacity and quota
- Appropriate volume management permissions
- An available virtual machine for attachment

Verify authentication:

```bash
openstack token issue
```

List volumes:

```bash
openstack volume list
```

List volume types:

```bash
openstack volume type list
```

Inspect storage services where authorized:

```bash
openstack volume service list
```

## 6. Volume Creation

Create a 10 GiB data volume:

```bash
openstack volume create \
  --size 10 \
  --description "Persistent storage for lab-vm01" \
  lab-data-volume
```

Verify:

```bash
openstack volume show lab-data-volume
```

A successfully provisioned, unattached volume normally reaches the `available` status.

Inspect all volumes:

```bash
openstack volume list
```

## 7. Volume Attachment

Attach the volume to a virtual machine:

```bash
openstack server add volume \
  lab-vm01 lab-data-volume
```

Verify the attachment:

```bash
openstack volume show lab-data-volume
openstack server volume list lab-vm01
```

An attached volume normally reports the `in-use` status.

The guest operating system must detect the newly attached block device before it can be used.

## 8. Linux Filesystem Configuration

Connect to the virtual machine and inspect available disks:

```bash
lsblk -f
```

Identify the newly attached, empty data volume.

**Warning:** Formatting a disk destroys existing filesystem data. Confirm the correct device before continuing.

The following example assumes the data disk appears as `/dev/vdb`.

Create an ext4 filesystem:

```bash
sudo mkfs.ext4 /dev/vdb
```

Create a mount point:

```bash
sudo mkdir -p /mnt/lab-data
```

Mount the filesystem:

```bash
sudo mount /dev/vdb /mnt/lab-data
```

Verify:

```bash
df -h /mnt/lab-data
lsblk -f
```

Device names can vary between virtualization environments.

For persistent mounting, use the filesystem UUID in `/etc/fstab` rather than relying on a device name.

## 9. Data Persistence Verification

Write a test file to the attached volume:

```bash
echo "OpenStack Cinder persistent storage test" \
  | sudo tee /mnt/lab-data/test.txt
```

Verify its contents:

```bash
cat /mnt/lab-data/test.txt
```

Confirm that the file resides on the expected mounted volume:

```bash
df -h /mnt/lab-data
```

A volume can be safely detached and attached again to verify that stored data remains accessible.

## 10. Volume Snapshots

Cinder snapshots represent point-in-time copies of volume data.

For application-consistent snapshots, coordinate with the application and ensure that pending writes are handled appropriately.

A straightforward procedure uses a detached volume.

First, stop application writes and unmount the filesystem inside the guest:

```bash
sudo umount /mnt/lab-data
```

Detach the volume from OpenStack:

```bash
openstack server remove volume \
  lab-vm01 lab-data-volume
```

Confirm the volume reaches `available`:

```bash
openstack volume show lab-data-volume
```

Create the snapshot:

```bash
openstack volume snapshot create \
  --volume lab-data-volume \
  lab-data-snapshot
```

List snapshots:

```bash
openstack volume snapshot list
```

Inspect the snapshot:

```bash
openstack volume snapshot show lab-data-snapshot
```

Some storage backends support snapshots of attached volumes with additional capabilities or options.

Snapshots should not be treated as a replacement for independent backups.

## 11. Restore a Volume from a Snapshot

Create a new volume from the snapshot:

```bash
openstack volume create \
  --snapshot lab-data-snapshot \
  --size 10 \
  lab-restored-volume
```

Inspect the restored volume:

```bash
openstack volume show lab-restored-volume
```

Attach the restored volume to a suitable instance:

```bash
openstack server add volume \
  lab-vm01 lab-restored-volume
```

Inspect available devices inside the guest:

```bash
lsblk -f
```

Identify the restored filesystem and mount it using its actual device path or UUID.

Do not format the restored volume, because doing so would destroy the recovered filesystem.

Verify that the test file and expected data are present.

## 12. Volume Capacity Expansion

Increasing a volume's capacity involves two separate operations:

1. Expand the Cinder volume.
2. Expand the guest-side partition or filesystem.

### Step 1 — Expand the Cinder Volume

For a detached volume in the `available` state:

```bash
openstack volume set \
  --size 20 \
  lab-data-volume
```

Verify the new capacity:

```bash
openstack volume show lab-data-volume
```

The requested size must be greater than the existing size.

### Step 2 — Expand the Guest Filesystem

Attach the expanded volume to the virtual machine:

```bash
openstack server add volume \
  lab-vm01 lab-data-volume
```

Inspect the disk:

```bash
lsblk
```

For an ext4 filesystem created directly on `/dev/vdb`, expand the filesystem:

```bash
sudo resize2fs /dev/vdb
```

Mount it if necessary:

```bash
sudo mount /dev/vdb /mnt/lab-data
```

Verify the available capacity:

```bash
df -h /mnt/lab-data
```

Different procedures are required for partitioned disks, LVM, XFS, or other filesystem layouts.

Online expansion capabilities also depend on the storage backend and operating system.

## 13. Safe Volume Detachment

Before detaching a data volume:

1. Stop application writes.
2. Confirm that no processes are using the filesystem.
3. Unmount the filesystem.
4. Detach the volume through OpenStack.

Unmount inside the guest:

```bash
sudo umount /mnt/lab-data
```

Detach:

```bash
openstack server remove volume \
  lab-vm01 lab-data-volume
```

Verify:

```bash
openstack volume show lab-data-volume
```

The volume should return to `available` after successful detachment.

Detaching an actively used block device can cause data corruption.

## 14. Volume Deletion

Confirm that the volume is no longer required, is detached, and contains no data that must be retained.

Delete:

```bash
openstack volume delete lab-data-volume
```

Volume deletion is destructive.

Snapshots, backend dependencies, or retention policies may prevent deletion until related resources are addressed.

## 15. Troubleshooting

### Volume Remains in Creating State

Possible causes:

- Unavailable Cinder Volume service
- Insufficient backend capacity
- Storage backend connectivity issues
- Quota restrictions
- Scheduler placement failure
- Storage driver errors

Commands:

```bash
openstack volume show lab-data-volume
openstack volume service list
```

Review Cinder service logs and backend health.

### Volume Attachment Fails

Inspect:

- Virtual machine status
- Volume status
- Compute host connectivity
- Storage backend connectivity
- Volume attachment limitations
- Nova and Cinder service logs

Commands:

```bash
openstack server show lab-vm01
openstack volume show lab-data-volume
openstack server volume list lab-vm01
```

### Attached Disk Is Not Visible Inside Linux

Inspect available devices:

```bash
lsblk
lsblk -f
```

Review recent kernel messages:

```bash
sudo dmesg | tail -n 30
```

Check the Cinder attachment status and compute host storage connectivity before making guest-side changes.

### Filesystem Capacity Is Incorrect

Compare:

- Cinder volume size
- Guest-visible disk size
- Partition size
- Filesystem size
- Mounted filesystem

Commands:

```bash
lsblk
df -h
```

Increasing a Cinder volume does not automatically expand its guest filesystem.

### Snapshot Creation Fails

Check:

- Volume status
- Storage backend snapshot support
- Available snapshot quota
- Snapshot permissions
- Existing storage dependencies
- Cinder service logs

Commands:

```bash
openstack volume show lab-data-volume
openstack volume snapshot list
```

## 16. Operational Best Practices

- Use consistent volume naming conventions.
- Separate persistent data from ephemeral instance storage.
- Monitor volume capacity and storage performance.
- Review storage quotas regularly.
- Maintain tested backup and recovery procedures.
- Document volume ownership and dependencies.
- Restrict administrative storage permissions.
- Coordinate snapshots with application consistency requirements.
- Verify recovered data before completing a restore operation.
- Avoid exposing confidential storage configuration or credentials.

## 17. Operational Verification Checklist

### Block Storage Services

- [ ] Verify Cinder API availability
- [ ] Inspect Cinder Volume service status
- [ ] Confirm storage backend connectivity
- [ ] Review volume types and quotas

### Volume Provisioning

- [ ] Create a data volume
- [ ] Verify the volume reaches `available`
- [ ] Attach the volume to an instance
- [ ] Verify the volume reaches `in-use`
- [ ] Identify the attached disk inside Linux

### Filesystem Management

- [ ] Create and mount a filesystem
- [ ] Verify filesystem capacity
- [ ] Create and read test data
- [ ] Verify persistent storage access

### Snapshots and Recovery

- [ ] Safely detach a data volume
- [ ] Create a volume snapshot
- [ ] Restore a new volume from the snapshot
- [ ] Attach the restored volume
- [ ] Verify recovered data

### Capacity and Troubleshooting

- [ ] Expand a Cinder volume
- [ ] Expand the guest filesystem
- [ ] Verify the updated capacity
- [ ] Investigate an attachment failure
- [ ] Review storage service logs
- [ ] Document diagnostic and recovery procedures

## 18. Related Documentation

- [OpenStack Architecture](architecture.md)
- [Nova Compute Management](nova-compute.md)
- [Glance Image Management](glance-images.md)
- [Keystone Identity Management](keystone-identity.md)
- [Operations and Troubleshooting](troubleshooting.md)

## 19. References

- [OpenStack Cinder Documentation](https://docs.openstack.org/cinder/latest/)
- [OpenStackClient Block Storage Commands](https://docs.openstack.org/python-openstackclient/latest/cli/command-objects/volume/v3/index.html)
- [OpenStackClient Compute Commands](https://docs.openstack.org/python-openstackclient/latest/cli/command-objects/compute/v2/index.html)
