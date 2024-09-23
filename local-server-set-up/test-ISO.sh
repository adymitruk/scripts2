#!/bin/bash

list_vms() {
    echo "Listing VMs:"
    vms=$(vboxmanage list vms)
    running_vms=$(vboxmanage list runningvms)
    IFS=$'\n'
    vm_array=($vms)
    for i in "${!vm_array[@]}"; do
        vm_name=$(echo "${vm_array[$i]}" | awk -F'"' '{print $2}')
        if echo "$running_vms" | grep -q "$vm_name"; then
            status="Running"
        else
            status="Stopped"
        fi
        echo "$((i+1)). ${vm_array[$i]} - Status: $status"
    done
}

delete_vm() {
    echo "Select VM to delete:"
    vms=$(vboxmanage list vms)
    IFS=$'\n'
    vm_array=($vms)
    for i in "${!vm_array[@]}"; do
        echo "$((i+1)). ${vm_array[$i]}"
    done
    read -p "Enter VM number to delete: " vm_num
    if [[ $vm_num -ge 1 && $vm_num -le ${#vm_array[@]} ]]; then
        vm_name=$(echo "${vm_array[$((vm_num-1))]}" | awk -F'"' '{print $2}')
        # Get the list of attached disks
        disks=$(vboxmanage showvminfo "$vm_name" --machinereadable | grep '^"SATA Controller-ImageUUID-0' | awk -F'=' '{print $2}' | tr -d '"')
        vboxmanage unregistervm "$vm_name" --delete
        echo "VM $vm_name deleted."
        # Delete the associated disks
        for disk in $disks; do
            vboxmanage closemedium disk "$disk" --delete
            echo "Disk $disk deleted."
        done
    else
        echo "Invalid VM number."
    fi
}

create_vm() {
    read -p "Enter name for new VM: " new_vm_name
    vboxmanage createvm --name "$new_vm_name" --register
    echo "VM $new_vm_name created."

    # Add 1 GB of RAM
    vboxmanage modifyvm "$new_vm_name" --memory 2048
    echo "1 GB of RAM allocated to VM $new_vm_name."

    # Prompt for ISO selection
    echo "Select an ISO file:"
    select iso_file in $(ls -1 *.iso 2>/dev/null); do
        if [[ -n $iso_file ]]; then
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done

    if [[ -z $iso_file ]]; then
        echo "No ISO files found in the current directory"
        return 1
    fi

    # Set up VM with the selected ISO
    vboxmanage storagectl "$new_vm_name" --name "IDE Controller" --add ide
    vboxmanage storageattach "$new_vm_name" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$iso_file"
    echo "ISO $iso_file attached to VM $new_vm_name."

    # Create a virtual hard drive of 5GB
    vboxmanage createhd --filename "$new_vm_name.vdi" --size 5120
    vboxmanage storagectl "$new_vm_name" --name "SATA Controller" --add sata --controller IntelAhci
    vboxmanage storageattach "$new_vm_name" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$new_vm_name.vdi"
    echo "5GB virtual hard drive created and attached to VM $new_vm_name."

    # Add networking
    vboxmanage modifyvm "$new_vm_name" --nic1 nat
    vboxmanage modifyvm "$new_vm_name" --nictype1 82540EM
    vboxmanage modifyvm "$new_vm_name" --cableconnected1 on
    echo "Networking configured for VM $new_vm_name."
}

start_vm() {
    echo "Select VM to start:"
    vms=$(vboxmanage list vms)
    running_vms=$(vboxmanage list runningvms)
    IFS=$'\n'
    vm_array=($vms)
    for i in "${!vm_array[@]}"; do
        vm_name=$(echo "${vm_array[$i]}" | awk -F'"' '{print $2}')
        if echo "$running_vms" | grep -q "$vm_name"; then
            status="Running"
        else
            status="Stopped"
        fi
        echo "$((i+1)). ${vm_array[$i]} - Status: $status"
    done
    read -p "Enter VM number to start: " vm_num
    if [[ $vm_num -ge 1 && $vm_num -le ${#vm_array[@]} ]]; then
        vm_name=$(echo "${vm_array[$((vm_num-1))]}" | awk -F'"' '{print $2}')
        if echo "$running_vms" | grep -q "$vm_name"; then
            echo "VM $vm_name is already running."
        else
            vboxmanage startvm "$vm_name"
            echo "VM $vm_name started."
        fi
    else
        echo "Invalid VM number."
    fi
}

stop_vm() {
    echo "Select VM to stop:"
    running_vms=$(vboxmanage list runningvms)
    IFS=$'\n'
    vm_array=($running_vms)
    if [ ${#vm_array[@]} -eq 0 ]; then
        echo "No VMs are currently running."
    else
        for i in "${!vm_array[@]}"; do
            echo "$((i+1)). ${vm_array[$i]}"
        done
        read -p "Enter VM number to stop: " vm_num
        if [[ $vm_num -ge 1 && $vm_num -le ${#vm_array[@]} ]]; then
            vm_name=$(echo "${vm_array[$((vm_num-1))]}" | awk -F'"' '{print $2}')
            vboxmanage controlvm "$vm_name" poweroff
            echo "VM $vm_name stopped."
        else
            echo "Invalid VM number."
        fi
    fi
}

# Main command loop for managing VirtualBox VMs
while true; do
    echo "VirtualBox VM Management: 1. List VMs | 2. Delete VM | 3. Create VM | 4. Start VM | 5. Stop VM | 6. Exit"
    read -p "Enter your choice (1-6): " choice

    case $choice in
        1) list_vms ;;
        2) delete_vm ;;
        3) create_vm ;;
        4) start_vm ;;
        5) stop_vm ;;
        6)
            echo "Exiting VM management."
            break
            ;;
        *)
            echo "Invalid choice. Please enter a number between 1 and 6."
            ;;
    esac
done