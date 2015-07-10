#!/bin/sh

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# This script will wipe and repartion the target drive that's connnected to the host via Thunderbolt.

# List of attached drives
DRIVE_LIST=$(diskutil list | grep /dev/disk)

# Locate the target drive
for DRIVE in $DRIVE_LIST ; do
	THUNDERBOLT=$(diskutil info $DRIVE | grep Protocol | grep Thunderbolt | awk '{print $2}')
	if [[  "${THUNDERBOLT}" == "Thunderbolt" ]] ; then
		TARGET=$(echo $DRIVE | sed 's/\/dev\///g')
	fi
done

if [[  "${TARGET}" == "" ]] ; then
	echo "Target drive not found."
	exit 134
fi

# Locate the recovery partition on the Target drive
RECOVERY_PARTITION_ID=$(diskutil list | grep Apple_Boot | grep $TARGET | awk '{print $7}')

# Check the status of FileVault of the Target drive
FILEVAULT_ON=$(diskutil cs list | grep $TARGET -A 11 | grep "Fully Secure" | sed 's/\|//g' | awk '{print $3}')

# If the drive is encrypted with FileVault, just the recovery partition will be wiped.
# If FileValult is not enabled, the entire drive will be wiped.

if [[  "${FILEVAULT_ON}" == "Yes" ]] ; then
	echo "Wiping the recovery partition /dev/"${RECOVERY_PARTITION_ID}
	diskutil zeroDisk /dev/${RECOVERY_PARTITION_ID} || {
		echo "Failed to wipe the recovery partition /dev/"${RECOVERY_PARTITION_ID}
		exit 131
	}
	echo "The recovery partition has been wiped."
else
	echo "FileVault is not enabled, wiping the entire drive."
	diskutil zeroDisk /dev/$TARGET || {
		echo "Failed to wipe drive /dev/$TARGET"
		exit 132
	}
	echo "The entire drive has been wiped."

fi

diskutil partitionDisk /dev/$TARGET GPT JHFS+ "Mac HD" 0b || {
	echo "Failed to format drive /dev/$TARGET"
	exit 133
}

echo "The drive has been formatted."
