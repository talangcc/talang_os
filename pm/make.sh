if [ $# -eq 1 ]; then
nasm $1 -o pm.com
sudo mount -o loop pm.img /mnt/floppy
sudo cp pm.com /mnt/floppy
sudo umount /mnt/floppy
rm pm.com
echo "OK!"
else
echo "Usage: ./make.sh <filename>"
fi
