# automatic upload script for imx6 phyflex module and yocto build on Ubuntu 14.04"
# author: Miroslav Kopecek @LittleHill, Medical Technologies CZ a.s.

UART_PORT="/dev/ttyUSB0"
UART_SPEED="115200"
SERVER_IP="10.250.30.202"

TFTP_DLFOLDER_PATH="/tftpboot"  #needs to be absolute
YOCTO_PATH="/yocto-btl"         #needs to be absolute

#relative links and names:
IMAGES_SRC_PATH="build/deploy/images/phyflex-imx6-2"
BAREBOX_BIN="barebox.bin"
BAREBOX_CFG="barebox.config"
KERNEL_BIN="zImage"
KERNEL_CFG="zImage.config"
KERNEL_DTB="zImage-dtf088-52masterimx6k001.dtb"
ROOT_UBIFS="btl-main-image-phyflex-imx6-2.ubifs"
TMPFOLDERNAME="TMP_IMAGES_LINK"

#local pc definitions
DLSCRNAME="download_script" #download script name



#---------------------------------------------------------------------------------
echo "## init uart line" > $UART_PORT

while true; do
    echo "init dhcp at start ?"
    read -p ": " yn
    case $yn in
        [Yy]* ) 
                DHCP_EN=true;
                break;;
        [Nn]* ) 
                DHCP_EN=false;
                break;;
        * ) echo "Error reading selection. Please answer y/n.";;
    esac
done

#DHCP_EN=true
if [ $DHCP_EN == true ]
then
        echo "setting dhcp"
        echo "global.dhcp.vendor_id=barebox-\${global.hostname}" >> $UART_PORT
        echo "dhcp" >> $UART_PORT
        sleep 4
        echo "eth0.serverip=$SERVER_IP" >> $UART_PORT
        echo "ifup" >> $UART_PORT
        echo "ping $SERVER_IP" >> $UART_PORT
fi
#---------------------------------------------------------------------------------
#load bootstrap_script for image rewrite in NAND
#echo "download tftp file"
#echo "tftp testfile" > $UART_PORT
#detect HWtype
#sleep 1 #waiting to download
#echo "sh /testfile" > $UART_PORT

#---------------------------------------------------------------------------------
#create symbolic links in tftp servers folder to image folders and files
if [ -e $TFTP_DLFOLDER_PATH/$TMPFOLDERNAME ]
 then
        rm $TFTP_DLFOLDER_PATH/$TMPFOLDERNAME
fi
ln -s $YOCTO_PATH/$IMAGES_SRC_PATH $TFTP_DLFOLDER_PATH/$TMPFOLDERNAME
if [ $? -eq 0 ]
 then
        echo "symbolic folder created;"
 else
        echo "error: symbolic folder creation failed."
        echo "tip: try deleting the temp symbolic folder ( rm -rf $TFTP_DLFOLDER_PATH/$TMPFOLDERNAME )"        
        #exit;
fi


if [[ -e $TFTP_DLFOLDER_PATH/$TMPFOLDERNAME/$BAREBOX_BIN && 
      -e $TFTP_DLFOLDER_PATH/$TMPFOLDERNAME/$BAREBOX_CFG &&
      -e $TFTP_DLFOLDER_PATH/$TMPFOLDERNAME/$KERNEL_BIN &&
      -e $TFTP_DLFOLDER_PATH/$TMPFOLDERNAME/$KERNEL_CFG &&
      -e $TFTP_DLFOLDER_PATH/$TMPFOLDERNAME/$KERNEL_DTB &&
      -e $TFTP_DLFOLDER_PATH/$TMPFOLDERNAME/$ROOT_UBIFS ]]
 then
        echo "all image-files found"
        #ls $TFTP_DLFOLDER_PATH/$TMPFOLDERNAME
        echo "loading images:"
           


        #User input section - only sets variables to decide in upload and install process
        echo "-- DEVICE TREE FILE --"
        VERSION=$(readlink $TFTP_DLFOLDER_PATH/$TMPFOLDERNAME/$KERNEL_DTB)   
                while true; do
                    echo "upload and rewrite device-tree ? (available ver: $VERSION)"
                    read -p ": " yn
                    case $yn in
                        [Yy]* ) 
                                DTF_INSTALL=true;
                                break;;
                        [Nn]* ) 
                                DTF_INSTALL=false;
                                break;;
                        * ) echo "Error reading selection. Please answer y/n.";;
                    esac
                done        

        echo "-- BAREBOX --"
        VERSION=$(readlink $TFTP_DLFOLDER_PATH/$TMPFOLDERNAME/$BAREBOX_BIN)   
                while true; do
                    echo "upload and rewrite barebox ? (available ver: $VERSION)"
                    read -p ": " yn
                    case $yn in
                        [Yy]* ) 
                                BARE_INSTALL=true;
                                break;;
                        [Nn]* ) 
                                BARE_INSTALL=false;
                                break;;
                        * ) echo "Error reading selection. Please answer y/n.";;
                    esac
                done

        echo "-- KERNEL --"
        VERSION=$(readlink $TFTP_DLFOLDER_PATH/$TMPFOLDERNAME/$KERNEL_BIN)   
                while true; do
                    echo "upload and rewrite kernel ? (available ver: $VERSION)"
                    read -p ": " yn
                    case $yn in
                        [Yy]* ) 
                                KERNEL_INSTALL=true;
                                break;;
                        [Nn]* ) 
                                KERNEL_INSTALL=false;
                                break;;
                        * ) echo "Error reading selection. Please answer y/n.";;
                    esac
                done

        echo "-- ROOTFS --"
        VERSION=$(readlink $TFTP_DLFOLDER_PATH/$TMPFOLDERNAME/$ROOT_UBIFS)   
                while true; do
                    echo "upload and rewrite root file-system ? (available ver: $VERSION)"
                    read -p ": " yn
                    case $yn in
                        [Yy]* ) 
                                ROOTFS_INSTALL=true;
                                break;;
                        [Nn]* ) 
                                ROOTFS_INSTALL=false;
                                break;;
                        * ) echo "Error reading selection. Please answer y/n.";;
                    esac
                done

        #send all images to device - todo: loading waiting on signal
        echo "#script to run on target device, upload sum" > $TFTP_DLFOLDER_PATH/$DLSCRNAME
        if [ $DTF_INSTALL == true ]  #work on rhis
         then
                echo "devicetree file rw initiated"
                if [ -e $(pwd)/include/flash_devicetree ]
                 then              
                        cp $(pwd)/include/flash_devicetree $TFTP_DLFOLDER_PATH
                        echo "tftp flash_devicetree" >> $TFTP_DLFOLDER_PATH/$DLSCRNAME
                        echo "time sh flash_devicetree $TMPFOLDERNAME $KERNEL_DTB" >> $TFTP_DLFOLDER_PATH/$DLSCRNAME
                 else
                        echo "error: 'include/flash_devicetree' file not found"
                fi

        fi 
        if [ $BARE_INSTALL == true ] 
         then
                echo "barebox rw initiated"
                if [ -e $(pwd)/include/flash_barebox ]
                 then              
                        cp $(pwd)/include/flash_barebox $TFTP_DLFOLDER_PATH
                        echo "tftp flash_barebox" >> $TFTP_DLFOLDER_PATH/$DLSCRNAME
                        echo "time sh flash_barebox $TMPFOLDERNAME $BAREBOX_BIN $BAREBOX_CFG" >> $TFTP_DLFOLDER_PATH/$DLSCRNAME
                 else
                        echo "error: 'include/flash_barebox' file not found"
                fi

        fi      
        if [ $KERNEL_INSTALL == true ] 
         then
                echo "kernel rw initiated"
                if [ -e $(pwd)/include/flash_kernel ]
                 then                
                        echo "tftp $TMPFOLDERNAME/$KERNEL_BIN" >> $TFTP_DLFOLDER_PATH/$DLSCRNAME
                        echo "tftp $TMPFOLDERNAME/$KERNEL_CFG" >> $TFTP_DLFOLDER_PATH/$DLSCRNAME
                        echo "tftp $TMPFOLDERNAME/$KERNEL_DTB"  >> $TFTP_DLFOLDER_PATH/$DLSCRNAME
        
                        cp $(pwd)/include/flash_kernel $TFTP_DLFOLDER_PATH
                        echo "tftp flash_kernel" >> $TFTP_DLFOLDER_PATH/$DLSCRNAME >> $TFTP_DLFOLDER_PATH/$DLSCRNAME
                        echo "time sh flash_kernel $KERNEL_BIN $KERNEL_CFG $KERNEL_DTB" >> $TFTP_DLFOLDER_PATH/$DLSCRNAME
                 else
                        echo "error: 'include/flash_kernel' file not found"
                fi
        fi
        if [ $ROOTFS_INSTALL == true ] 
         then
                echo "instaluju rootfs"        
        # !!! replace direct download with direct rewrite !!!!
                #echo "tftp $TMPFOLDERNAME/$ROOT_UBIFS" >> $TFTP_DLFOLDER_PATH/$DLSCRNAME 
                if [ -e $(pwd)/include/flash_rootf ]
                 then                
                        cp $(pwd)/include/flash_rootfs $TFTP_DLFOLDER_PATH
                        echo "tftp flash_rootfs" >> $TFTP_DLFOLDER_PATH/$DLSCRNAME
                        echo "time sh flash_rootfs $ROOT_UBIFS"
                 else
                        echo "error: 'include/flash_rootfs' file not found"
                fi
        fi

#TODO create and compilator for script files upload and modification, run them with parameter - which will be the name of kernel file (folder include)
                
        echo  "tftp $DLSCRNAME" >> $UART_PORT #require the script
        sleep 1
        echo  "time sh $DLSCRNAME" >> $UART_PORT #run the download script, remove the time measurement after debug done
        sleep 1        
      

        
 else  #else to checking if file exist
        echo "ERROR checking files, some of the sources could not be found."
        echo "searched folder was: $TFTP_DLFOLDER_PATH/TMP_IMAGES_LINK"
fi

#rm -rf $TFTP_DLFOLDER_PATH/$TMPFOLDERNAME #just clean-up, next run fails if symbolic link already exists

#---------------------------------------------------------------------------------
#run the bootstrap script

#---------------------------------------------------------------------------------
#wait for confirmation (report file through ethernet is used for now) 


#---------------------------------------------------------------------------------
#exit process, clean-up for next board

