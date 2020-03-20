#!/bin/bash
# Setup - creates the local repo which will be mirrored up to S3, then back-fill it. Your
#         future deploys will eliminate all old versions without these backfill steps:
#   aptly repo create spaycle-desktop
#   aptly mirror create -ignore-signatures backfill-mirror https://updates.signal.org/desktop/apt xenial
#   aptly mirror update -ignore-signatures backfill-mirror
#   aptly repo import backfill-mirror spaycle-desktop spaycle-desktop spaycle-desktop-beta
#   aptly repo show -with-packages spaycle-desktop
#
# First run on a machine - uncomment the first set of 'aptly publish snapshot' commands,
#   comment the other two. Sets up the two publish channels, one local, one to S3.
#
# Testing - comment out the lines with s3:$ENDPOINT to publish only locally. To eliminate
#          effects of testing, remove package from repo, then move back to old snapshot:
#   aptly repo remove spaycle-desktop spaycle-desktop_1.0.35_amd64
#   aptly publish switch -gpg-key=57F6FB06 xenial spaycle-desktop_v1.0.34
#
# Pruning package set - we generally want 2-3 versions of each stream available,
#                       production and beta. You can remove old packages like this:
#   aptly repo show -with-packages spaycle-desktop
#   aptly repo remove spaycle-desktop spaycle-desktop_1.0.34_amd64
#
# Release:
#   NAME=spaycle-desktop(-beta) VERSION=X.X.X ./aptly.sh

echo "Releasing $NAME build version $VERSION"

REPO=spaycle-desktop
CURRENT=xenial
# PREVIOUS=xenial
ENDPOINT=spaycle-desktop-apt # Matches endpoint name in .aptly.conf
SNAPSHOT=spaycle-desktop_v$VERSION
GPG_KEYID=57F6FB06

aptly repo add $REPO release/$NAME\_$VERSION\_*.deb
aptly snapshot create $SNAPSHOT from repo $REPO

# run these only on first release to a given repo from a given machine. the first set is
# for local testing, the second set is to set up the production server.
#   https://www.aptly.info/doc/aptly/publish/snapshot/
# aptly publish snapshot -gpg-key=$GPG_KEYID -distribution=$CURRENT $SNAPSHOT
# aptly publish snapshot -gpg-key=$GPG_KEYID -distribution=$PREVIOUS $SNAPSHOT
# aptly publish snapshot -gpg-key=$GPG_KEYID -distribution=$CURRENT -config=.aptly.conf $SNAPSHOT s3:$ENDPOINT:
# aptly publish snapshot -gpg-key=$GPG_KEYID -distribution=$PREVIOUS -config=.aptly.conf $SNAPSHOT s3:$ENDPOINT:

# these update already-published repos, run every time after that
#   https://www.aptly.info/doc/aptly/publish/switch/
aptly publish switch -gpg-key=$GPG_KEYID $CURRENT $SNAPSHOT
# aptly publish switch -gpg-key=$GPG_KEYID $PREVIOUS $SNAPSHOT
aptly publish switch -gpg-key=$GPG_KEYID -config=.aptly.conf $CURRENT s3:$ENDPOINT: $SNAPSHOT
# aptly publish switch -gpg-key=$GPG_KEYID -config=.aptly.conf $PREVIOUS s3:$ENDPOINT: $SNAPSHOT

