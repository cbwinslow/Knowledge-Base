#!/bin/bash

# Disk Management and Formatting Script
echo "Setting up disk management..."

# Install required tools
apt update
apt install -y smartmontools hdparm lvm2 mdadm

# Function to identify and categorize disks
identify_disks() {
    echo "Identifying available disks..."
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL
    
    echo "Checking disk health..."
    for disk in $(lsblk -d -o NAME | grep -E 'sd[a-z]|nvme[0-9]n[0-9]'); do
        echo "Checking $disk..."
        smartctl -H /dev/$disk
    done
}

# Function to format and mount disks based on criteria
setup_disks() {
    echo "Setting up disks based on criteria..."
    
    # Get list of unmounted disks
    UNMOUNTED_DISKS=$(lsblk -rno NAME,MOUNTPOINT,SIZE | awk '$2=="" && $1!~"loop" && $1!~"sr" {print $1,$3}')
    
    echo "Unmounted disks found:"
    echo "$UNMOUNTED_DISKS"
    
    # Ask user for disk configuration
    echo "Disk configuration options:"
    echo "1. Individual disks - Mount each disk separately"
    echo "2. RAID array - Create RAID configuration"
    echo "3. LVM - Logical Volume Management"
    echo "4. Mixed - Some disks for specific purposes"
    
    read -p "Choose configuration (1-4): " CONFIG_CHOICE
    
    case $CONFIG_CHOICE in
        1)
            setup_individual_disks
            ;;
        2)
            setup_raid_array
            ;;
        3)
            setup_lvm
            ;;
        4)
            setup_mixed
            ;;
        *)
            echo "Invalid choice, setting up individual disks..."
            setup_individual_disks
            ;;
    esac
}

# Setup individual disks
setup_individual_disks() {
    echo "Setting up individual disks..."
    
    for disk in $(lsblk -rno NAME,MOUNTPOINT | awk '$2=="" && $1!~"loop" && $1!~"sr" {print $1}'); do
        if [[ $disk =~ ^sd[a-z]$|^nvme[0-9]n[0-9]$ ]]; then
            echo "Processing disk: $disk"
            
            # Ask for disk purpose
            echo "Disk purposes:"
            echo "1. Data storage"
            echo "2. Backup storage"
            echo "3. Media storage"
            echo "4. Database storage"
            echo "5. Cache/Temp storage"
            
            read -p "Choose purpose for $disk (1-5): " PURPOSE
            
            case $PURPOSE in
                1)
                    MOUNT_POINT="/mnt/data"
                    ;;
                2)
                    MOUNT_POINT="/mnt/backup"
                    ;;
                3)
                    MOUNT_POINT="/mnt/media"
                    ;;
                4)
                    MOUNT_POINT="/mnt/database"
                    ;;
                5)
                    MOUNT_POINT="/mnt/cache"
                    ;;
                *)
                    MOUNT_POINT="/mnt/$disk"
                    ;;
            esac
            
            # Create mount point
            mkdir -p $MOUNT_POINT
            
            # Format disk (ext4 by default, xfs for database)
            if [ "$PURPOSE" = "4" ]; then
                mkfs.xfs -f /dev/$disk
                echo "/dev/$disk $MOUNT_POINT xfs defaults 0 2" >> /etc/fstab
            else
                mkfs.ext4 -F /dev/$disk
                echo "/dev/$disk $MOUNT_POINT ext4 defaults 0 2" >> /etc/fstab
            fi
            
            # Mount disk
            mount /dev/$disk $MOUNT_POINT
            
            # Set permissions
            chmod 755 $MOUNT_POINT
            chown root:root $MOUNT_POINT
            
            echo "Disk $disk mounted at $MOUNT_POINT"
        fi
    done
}

# Setup RAID array
setup_raid_array() {
    echo "Setting up RAID array..."
    
    # List available disks
    echo "Available disks for RAID:"
    lsblk -d -o NAME,SIZE | grep -E 'sd[a-z]|nvme[0-9]n[0-9]'
    
    read -p "Enter disks to include in RAID (space-separated, e.g., sdb sdc sdd): " RAID_DISKS
    read -p "Enter RAID level (0, 1, 5, 10): " RAID_LEVEL
    read -p "Enter mount point (e.g., /mnt/raid): " MOUNT_POINT
    
    # Create RAID array
    case $RAID_LEVEL in
        0|1|5|10)
            echo "Creating RAID $RAID_LEVEL with disks: $RAID_DISKS"
            mdadm --create --verbose /dev/md0 --level=$RAID_LEVEL --raid-devices=$(echo $RAID_DISKS | wc -w) $RAID_DISKS
            
            # Format RAID array
            mkfs.ext4 /dev/md0
            
            # Create mount point
            mkdir -p $MOUNT_POINT
            echo "/dev/md0 $MOUNT_POINT ext4 defaults 0 2" >> /etc/fstab
            mount /dev/md0 $MOUNT_POINT
            
            # Save RAID configuration
            mdadm --detail --scan >> /etc/mdadm/mdadm.conf
            update-initramfs -u
            
            echo "RAID $RAID_LEVEL created and mounted at $MOUNT_POINT"
            ;;
        *)
            echo "Invalid RAID level"
            return 1
            ;;
    esac
}

# Setup LVM
setup_lvm() {
    echo "Setting up LVM..."
    
    # List available disks
    echo "Available disks for LVM:"
    lsblk -d -o NAME,SIZE | grep -E 'sd[a-z]|nvme[0-9]n[0-9]'
    
    read -p "Enter disks to include in LVM (space-separated): " LVM_DISKS
    read -p "Enter volume group name: " VG_NAME
    read -p "Enter logical volume name: " LV_NAME
    read -p "Enter size for logical volume (e.g., 100G, 50%FREE): " LV_SIZE
    read -p "Enter mount point: " MOUNT_POINT
    
    # Create physical volumes
    for disk in $LVM_DISKS; do
        pvcreate /dev/$disk
    done
    
    # Create volume group
    vgcreate $VG_NAME $LVM_DISKS
    
    # Create logical volume
    lvcreate -L $LV_SIZE -n $LV_NAME $VG_NAME
    
    # Format logical volume
    mkfs.ext4 /dev/$VG_NAME/$LV_NAME
    
    # Create mount point and mount
    mkdir -p $MOUNT_POINT
    echo "/dev/$VG_NAME/$LV_NAME $MOUNT_POINT ext4 defaults 0 2" >> /etc/fstab
    mount /dev/$VG_NAME/$LV_NAME $MOUNT_POINT
    
    echo "LVM setup completed. Mounted at $MOUNT_POINT"
}

# Setup mixed configuration
setup_mixed() {
    echo "Setting up mixed disk configuration..."
    
    # Process each disk individually
    for disk in $(lsblk -rno NAME,MOUNTPOINT | awk '$2=="" && $1!~"loop" && $1!~"sr" {print $1}'); do
        if [[ $disk =~ ^sd[a-z]$|^nvme[0-9]n[0-9]$ ]]; then
            echo "Processing disk: $disk"
            
            # Ask for disk purpose
            echo "Disk purposes for $disk:"
            echo "1. Data storage"
            echo "2. Backup storage"
            echo "3. Media storage"
            echo "4. Database storage"
            echo "5. Cache/Temp storage"
            echo "6. Skip this disk"
            
            read -p "Choose purpose (1-6): " PURPOSE
            
            if [ "$PURPOSE" = "6" ]; then
                continue
            fi
            
            case $PURPOSE in
                1)
                    MOUNT_POINT="/mnt/data/$disk"
                    FS_TYPE="ext4"
                    ;;
                2)
                    MOUNT_POINT="/mnt/backup/$disk"
                    FS_TYPE="ext4"
                    ;;
                3)
                    MOUNT_POINT="/mnt/media/$disk"
                    FS_TYPE="ext4"
                    ;;
                4)
                    MOUNT_POINT="/mnt/database/$disk"
                    FS_TYPE="xfs"
                    ;;
                5)
                    MOUNT_POINT="/mnt/cache/$disk"
                    FS_TYPE="ext4"
                    ;;
            esac
            
            # Create mount point
            mkdir -p $MOUNT_POINT
            
            # Format disk
            if [ "$FS_TYPE" = "xfs" ]; then
                mkfs.xfs -f /dev/$disk
            else
                mkfs.ext4 -F /dev/$disk
            fi
            
            # Add to fstab
            echo "/dev/$disk $MOUNT_POINT $FS_TYPE defaults 0 2" >> /etc/fstab
            
            # Mount disk
            mount /dev/$disk $MOUNT_POINT
            
            # Set permissions
            chmod 755 $MOUNT_POINT
            chown root:root $MOUNT_POINT
            
            echo "Disk $disk mounted at $MOUNT_POINT"
        fi
    done
}

# Create disk monitoring script
cat > /opt/scripts/disk-monitor.sh << 'EOF'
#!/bin/bash

# Disk Monitoring Script

LOG_FILE="/var/log/disk-monitor.log"
ALERT_THRESHOLD=90

# Check disk usage
check_disk_usage() {
    df -h | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 " " $6 }' | while read output;
    do
        usage=$(echo $output | awk '{ print $1}' | cut -d'%' -f1)
        partition=$(echo $output | awk '{ print $2 }')
        mountpoint=$(echo $output | awk '{ print $3 }')
        
        if [ $usage -ge $ALERT_THRESHOLD ]; then
            echo "$(date): ALERT - Partition $partition mounted on $mountpoint is ${usage}% full" >> $LOG_FILE
            # Send alert (implement as needed)
        fi
    done
}

# Check disk health
check_disk_health() {
    for disk in $(lsblk -d -o NAME | grep -E 'sd[a-z]|nvme[0-9]n[0-9]'); do
        health=$(smartctl -H /dev/$disk | grep "test result" | awk '{print $NF}')
        if [ "$health" != "PASSED" ]; then
            echo "$(date): ALERT - Disk /dev/$disk health check failed: $health" >> $LOG_FILE
        fi
    done
}

# Run checks
check_disk_usage
check_disk_health

echo "$(date): Disk monitoring completed" >> $LOG_FILE
EOF

chmod +x /opt/scripts/disk-monitor.sh

# Add to cron for regular monitoring
echo "0 */6 * * * root /opt/scripts/disk-monitor.sh" > /etc/cron.d/disk-monitor

# Run disk setup
identify_disks
setup_disks

echo "Disk management setup completed."