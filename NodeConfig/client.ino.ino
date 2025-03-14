#include <RadioHead.h>

// rf95_client.pde
// -*- mode: C++ -*-
// Example sketch showing how to create a simple messageing client
// with the RH_RF95 class. RH_RF95 class does not provide for addressing or
// reliability, so you should only use RH_RF95 if you do not need the higher
// level messaging abilities.
// It is designed to work with the other example rf95_server
// Tested with Anarduino MiniWirelessLoRa, Rocket Scream Mini Ultra Pro with
// the RFM95W, Adafruit Feather M0 with RFM95

#include <SPI.h>
#include <RH_RF95.h>

// Singleton instance of the radio driver
RH_RF95 rf95;
//RH_RF95 rf95(5, 2); // Rocket Scream Mini Ultra Pro with the RFM95W
//RH_RF95 rf95(8, 3); // Adafruit Feather M0 with RFM95 

// Need this on Arduino Zero with SerialUSB port (eg RocketScream Mini Ultra Pro)
//#define Serial SerialUSB

uint8_t cnt = 0;
// char cnt_str[3];

unsigned long startTime; // 用于记录开始时间
unsigned long endTime;   // 用于记录结束时间
 
void startTimer() {
  startTime = millis(); // 记录开始时间
}
 
void stopTimer() {
  endTime = millis(); // 记录结束时间
}
 
unsigned long getElapsedTime() {
  return endTime - startTime; // 返回经过的毫秒数
}
 

void setup() 
{
  // Rocket Scream Mini Ultra Pro with the RFM95W only:
  // Ensure serial flash is not interfering with radio communication on SPI bus
//  pinMode(4, OUTPUT);
//  digitalWrite(4, HIGH);

  Serial.begin(9600);
  while (!Serial) ; // Wait for serial port to be available
  if (!rf95.init())
    Serial.println("init failed");
  // Defaults after init are 434.0MHz, 13dBm, Bw = 125 kHz, Cr = 4/5, Sf = 128chips/symbol, CRC on

  // You can change the modulation parameters with eg
  // rf95.setModemConfig(RH_RF95::Bw500Cr45Sf128);
  rf95.setFrequency(920);
  rf95.setSignalBandwidth(125000);
  rf95.setSpreadingFactor(8);
  rf95.setCodingRate4(8);
  rf95.setTxPower(0,false);
  rf95.setPreambleLength(8);
  // setCodingRate4(4/8);
  
  // The default transmitter power is 13dBm, using PA_BOOST.
  // If you are using RFM95/96/97/98 modules which uses the PA_BOOST transmitter pin, then 
  // you can set transmitter powers from 2 to 20 dBm:
//  rf95.setTxPower(20, false);
  // If you are using Modtronix inAir4 or inAir9, or any other module which uses the
  // transmitter RFO pins and not the PA_BOOST pins
  // then you can configure the power transmitter power for 0 to 15 dBm and with useRFO true. 
  // Failure to do that will result in extremely low transmit powers.
//  rf95.setTxPower(14, true);


}

void loop()
{
  Serial.println("Sending to rf95_server");
  // Send a message to rf95_server
  uint8_t data[] = "Hello world! #";
  cnt = cnt + 1;
  uint8_t data[] = {cnt};
  Serial.print("Attempt: #");
  Serial.print(data[0],DEC);
  Serial.print("\n");
  //uint8_t data[20] = {0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa};
  rf95.setSpreadingFactor(8);
  rf95.send(data, sizeof(data));
  rf95.waitPacketSent();
  startTimer();
//  rf95.setSpreadingFactor(10);
//  rf95.send(data, sizeof(data));
//  rf95.waitPacketSent();
  // Now wait for a reply
  uint8_t buf[RH_RF95_MAX_MESSAGE_LEN];
  uint8_t len = sizeof(buf);
  // rf95.setSpreadingFactor(12);
  if (rf95.waitAvailableTimeout(8000))
  { 
    // Should be a reply message for us now   
    if (rf95.recv(buf, &len))
   {
      stopTimer();
      unsigned long elapsed = getElapsedTime();
      Serial.print("got reply: ");
      Serial.println((char*)buf);
      //for(ii = 0; ii < 20; ii++) {
      //  Serial.print(buf[ii],HEX);
      //  Serial.print(" ");
      //}
//      Serial.print("\n");/
      // Serial.print("\n");
      Serial.print("Response time: ");
      Serial.print(elapsed);
      Serial.print("ms\n");
//      Serial.print("RSSI: ");
//      Serial.println(rf95.lastRssi(), DEC);    
    }
    else
    {
      stopTimer();
      Serial.println("recv failed");
    }
  }
  else
  {
    stopTimer();
    Serial.println("No reply, is rf95_server running?");
  }
  delay(1000);
}


