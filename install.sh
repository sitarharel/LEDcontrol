#sudo apt-get install -y git
#git clone https://github.com/sitarharel/LEDcontrol.git
#git checkout headless-mode
#cd LEDcontrol
#touch run-lights
#echo "#! /bin/sh
#DISPLAY=:0 processing-java --sketch=\"/home/pi/LEDcontrol/LightControl\" --run" > run-lights

#chmod +x run-lights
#cd ..

sudo apt-get install libxrender1 libxtst6 libxi6
sudo apt-get install -y xvfb
#curl https://processing.org/download/install-arm.sh | sudo sh
echo "#!/bin/sh -e

# Print the IP address
_IP=$(hostname -I) || true
if [ \"$_IP\" ]; then
  printf \"My IP address is %s\n\" \"$_IP\"
fi

sudo su -c \"sudo xvfb-run /usr/local/bin/processing-java --sketch=/home/pi/LEDcontrol/LightControl --run > /home/pi/start.log &\" pi
#xvfb-run /home/pi/LEDcontrol/LightControl/runnable/LightControl > /home/pi/start.log &

exit 0" >> /etc/rc.local

# also edit /usr/share/alsa/alsa.conf to:
# defaults.ctl.card 1
# defaults.pcm.card 1

echo "see script file for more comments"
