# Satellite 6.19 GCP image comparison

**Date:** 2026-10-30
**Project:** `tmm-instruqt-11-26-2021` (GCP)
**Compared:**

| | New | Current (superseded) |
|---|---|---|
| Image | `satellite-server-1-6-19-10-29-26-2` | `satellite-server-rhdp-1-6-19-09-28-26-150g-image` |
| Role | upstream `satellite.lab` | upstream `satellite.lab` |

The sibling downstream images are `satellite-server-2-6-19-10-29-26-2` (50 GB) and
`satellite-server-rhdp-2-6-19-10-16-26-50g-image` (50 GB); only the image-1 pair was
inspected in detail, but both pairs share the same build lineage and naming shift.

**Outcome:** the new `10-29-26-2` pair is a clean rebuild of the same lab
configuration. It was briefly adopted in `config/instances.yaml` (commit
`78b24b1`) and then reverted (`e175372`) — the lab currently runs
`satellite-server-rhdp` (floating tag) as upstream and
`satellite-server-rhdp-2-6-19-10-16-26-50g-image` as downstream.
Open follow-ups are listed at the end.

## Build metadata

| | New (10-29-26-2) | Old (09-28-26-150g) |
|---|---|---|
| Created | 2026-10-29 12:14 PDT | 2026-09-28 13:49 PDT |
| Disk size | 150 GB | 150 GB |
| Stored image size | 20.2 GiB | 67.2 GiB (3.3x) |
| Origin | fresh build disk `satellite-build-satellite-20261029-113736` (us-east4-c) | shrunk disk `...-09-28-26-150g-v2` (us-central1-a) |
| Family | none | `satellite-rhdp-1-6-19-shrunk` |
| License | RHEL 9 server attached | none |
| Guest OS features | UEFI, VIRTIO_SCSI_MULTIQUEUE, GVNIC, **SEV_CAPABLE** | UEFI, VIRTIO_SCSI_MULTIQUEUE, GVNIC |

## Software

| | New | Old |
|---|---|---|
| RHEL | 9.8 | 9.7 |
| Satellite | **6.19.5** | 6.19.0 |
| Katello / Foreman | 4.20.0 / 3.18 | 4.20.0 / 3.18 |
| Installed RPMs | 1,351 | 1,311 |
| Disk used at boot | 21 G | 80 G |
| `/var/lib/pulp` | 1.7 G (clean) | 61 G (stale artifacts from April build) |

## Content configuration (org "Acme Org")

Identical structure on both: org `Acme Org`, location `Vancouver`, content views
(Default Organization View only), lifecycle environments (Library only), and the
same 4 enabled repositories:

1. RHEL 10 for x86_64 - BaseOS RPMs 10
2. RHEL 10 for x86_64 - AppStream RPMs 10
3. Red Hat Satellite 6.19 (offline, `file:///opt/satellite/Satellite`)
4. Red Hat Satellite Client 6 for RHEL 10

Differences:

| | New | Old |
|---|---|---|
| RHEL 10 BaseOS sync | 7,443 packages, synced at build (Oct 29) | 4,015 packages, last synced April (7 months stale) |
| RHEL 10 AppStream sync | 14,433 packages, Oct 29 | 9,162 packages, April |
| Products (from manifest) | 411 | 357 |
| Manifest subscriptions | Employee SKU (valid to Aug 2027) | Employee SKU + Satellite Maintenance (to 2049) |
| Host registration | not registered (clean image) | still registered with SCA (leftover from build) |

The lab's network-sync module depends on the upstream having RHEL 10 BaseOS
enabled *and* synced - true on the new image.

## SSH configuration

Identical: `PasswordAuthentication no`, `AuthorizedKeysFile .ssh/authorized_keys`,
`ClientAliveInterval 420`, GSSAPI on, UsePAM yes, SELinux Enforcing,
google-sudoers + cloud-user passwordless sudo, guest agent creates
project-metadata users at boot and appends `# Google` keys (including to
root's authorized_keys).

Differences:

| | New | Old |
|---|---|---|
| `PermitRootLogin` (effective) | **prohibit-password** | **no** |
| Where set | drop-in `/etc/ssh/sshd_config.d/00-catalog.conf` overrides the `PermitRootLogin no` in `sshd_config` (drop-ins are included first; first match wins) | `PermitRootLogin no` in `sshd_config`, no drop-in |
| Root key login (verified live) | works (logged in as root with an added key) | refused |
| Keys baked into `/root/.ssh/authorized_keys` | 1 x `ssh-ed25519 satellite-catalog` | 4 x `ssh-rsa foreman-proxy@satellite.lab` (dead - root login disabled) |
| OpenSSH | newer (RHEL 9.8; adds persourcepenalties, channeltimeout, sshdsessionpath) | RHEL 9.7 |
| Guest agents | guest-agent 20261021, osconfig 20260928, cloud-init 24.4-8 | guest-agent 20260329, osconfig 20260119, cloud-init 24.4-7 |
| Stale accounts | none | `ehendricks`, `itguyeric` left over from earlier builds |

Operational note: on the new image the guest agent creates the project-metadata
users sequentially (~16 s each, ~90 s total), so the first SSH attempt after
boot can fail with `Permission denied` until the user exists.

## Cloud-init and hostname handling

Cloud-init is functional on both images (tested with the lab's exact userdata
from `instances.yaml`): `cloud-init status: done`, rc=0, all four units enabled,
zero errors, and `manage_etc_hosts` templated the userdata FQDN into
`/etc/hosts` on both.

| | New | Old |
|---|---|---|
| `preserve_hostname` | false (RHEL default, no drop-in) | **true** - baked drop-in `/etc/cloud/cloud.cfg.d/99-preserve-hostname.cfg` |
| `cc_set_hostname` on userdata | applies it (log: "Setting the hostname to ... SUCCESS") | skips it (log: "'preserve_hostname' is set, not setting the hostname") |
| System hostname | from userdata / datasource | baked `satellite.lab`, userdata ignored |
| Baked `/etc/hosts` | contains `127.0.0.1 satellite.lab satellite` (from build boot) | no `satellite.lab` entry; stale Google entries naming the September build VM |

GCE-specific behavior (does not apply on the lab platform): the
`google_hostname.sh` NetworkManager dispatcher (google-compute-engine RPM)
resets the hostname to the GCE metadata instance name on network events. This
fired successfully on the new image (newer package 20260918) but never
succeeded on the old image (20260223 - no "Added by Google" /etc/hosts entries
appeared). On KubeVirt there is no GCE metadata server, so the dispatcher is a
no-op and the userdata hostname wins on the new image.

Net effect on the lab platform: the old pair kept the correct
`satellite.lab` / `satellite-2.lab` names only because they were baked in at
build time; the new pair applies the names from `instances.yaml` userdata as
designed.

## Boot behavior

- **`foreman-proxy.service` timed out on first boot of the new image**
  (`Result: timeout`, killed at systemd's 90 s `TimeoutStartSec` after ~1 s CPU
  - it was waiting, not working). It starts fine on manual `systemctl restart
  foreman-proxy` once boot settles. The old image's proxy started normally
  during boot. Worth flagging to the image build owners; may cause flaky
  first-boot behavior on slower hardware.
- `iop-cvemap-download.service` fails on both images (known artifact, ignored).
- The new image boots somewhat slower (cloud-init finished at Up 272 s vs
  Up 222 s on the old image, e2-standard-4).

## Open follow-ups for the lab

1. **Location mismatch:** both 6.19 images use location `Vancouver`, but the
   lab text in `04-iss-import.adoc` and `05-configure-network-sync.adoc` still
   says `Kicking Horse` (inherited from the 6.18 advanced-topics lab), and
   `organdloacation.gif` shows the old location.
2. **`lab_name` branding** in `content/antora.yml` still reads
   "Satellite Inter-Satellite Sync 6.18"; screenshots are 6.18-era in general.
3. **foreman-proxy boot timeout** on the new image - report to the image
   build owners.

## Changes made during this work

### Repository (github.com/rhpds/zt-satellite-iss, branch `main`)

| Commit | Change |
|---|---|
| `00955ad` | Initial lab created from the zt-satellite-advanced-topics ISS sections (9 modules, 6.18 image pair) |
| `2053dc3` | Satellite images moved to 6.19 (`rhdp-1-...-150g-image` / `rhdp-2-...-50g-image`), disks 200Gi/100Gi |
| `29357d6` | Satellite image switched to floating tag `satellite-server-rhdp` |
| `48ddb81` | `satellite.lab` route TLS certificate regenerated for the new image |
| `66461fc` | Modules 2+3 merged into `02-iss-export`, modules 4+5 merged into `03-iss-import` (lab is now 7 modules); fixed `runtime-automation/main.yml` host loop (added `satellite`, dropped nonexistent `rhel2`) |
| `d31ce03` | Manifest-expired NOTE box with `error-manifest.png` added to `05-configure-network-sync` (image rendered inside the admonition, collapsible delimiters bumped) |
| `78b24b1` | (user) `instances.yaml` switched to the new image pair `satellite-server-1-6-19-10-29-26-2` / `satellite-server-2-6-19-10-29-26-2` |
| `88a2cca` | (user) this comparison document committed |
| `e175372` | revert of `78b24b1` — `instances.yaml` back to `satellite-server-rhdp` (floating tag) / `satellite-server-rhdp-2-6-19-10-16-26-50g-image` |

### GCP (project `tmm-instruqt-11-26-2021`)

- Ephemeral comparison VMs created and **deleted** after each round
  (`img-compare-*`, `img-ssh-*`, `img-ci-*`, all in `us-east4-c`, disks
  deleted with the VMs). On the `img-ssh-*` pair (deleted), a public key was
  appended to root's `authorized_keys` to verify root-login behavior.
- **Left running** for ongoing investigation (do not delete until the
  investigation is finished):

| VM | Image | Type | Internal | External | Notes |
|---|---|---|---|---|---|
| `img-compare-new` | `satellite-server-1-6-19-10-29-26-2` | e2-standard-8 | 10.150.0.11 | 8.234.237.159 | hostname manually set to `satellite.lab` (2026-10-30); GCE dispatcher may reset it on network events |
| `img-compare-old` | `satellite-server-rhdp-1-6-19-09-28-26-150g-image` | e2-standard-8 | 10.150.0.10 | 34.150.171.128 | hostname `satellite.lab` (baked); `foreman-proxy` active; system `degraded` only due to `iop-cvemap-download` |
