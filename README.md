# LEDcontrol

A processing applet that communicates with an arduino running Firmata to control RGB LEDs.

My hardware setup involves using RGB LED light strips and a Metro Mini running Firmata. 

This applet has 3 modes:
  Music- 
    The most complex version: responds to music played from computer speakers or mic input. User has control over many settings such as      smoothness, response rate, intensity and others.
  Fade- 
    Fades throughout different colors in ROYGBIV order.
  Static- 
    Select any RGB color and the lights will stay that color.

To ssh into tablet: 
  ssh sitar@[ip address] -m hmac-md5

To run the app from the command line: 
  C:\processing-3.1.1\processing-java.exe --sketch="C:\Users\Sitar\Documents\LEDcontrol\LightControl" --run
