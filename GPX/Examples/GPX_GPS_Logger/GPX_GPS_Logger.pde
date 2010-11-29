#include <Flash.h>

/* 
 * GPS Logger -- GPX-GPS-Logger.pde
 * Created by: Ryan M Sutton
 *  
 * Summary:  Uses GPX Lib, TinyGPS, and SdFat libs to collect GPS Data and
 *           write it to the SD card.
 *
 * Hardware: GPS RX line connected to pin 9 @ 9600 baud
 *           LCD (for debugging) on ping 8 @ 9600 baud
 *           SD Card connected to SPI bus, and CS on pin 10
 *
 * Copyright (c) 2010, Ryan M Sutton
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the Ryan M Sutton nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL Ryan M Sutton BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
*/

#include <Fat16.h>
#include <Fat16util.h> 

#include <GPX.h>

#include <TinyGPS.h>
#include <NewSoftSerial.h>

#define   ERROR_LED      2
#define   SDWRITE_LED    3
#define   ENABLED_LED    4
#define   DONE_LED       5

#define   COLLECT_SW     7

#define   WRDELAY        100



// serial,gpx and gps globals
NewSoftSerial gps(9,8);
TinyGPS gpsParser;
GPX myGPX;

SdCard card;
Fat16 file;

//state global
unsigned short state = 0;

int LoadAvailMem(){ // works with ATmega168, ATmega328 and ATmega644
#if defined(__AVR_ATmega644P__) || defined(__AVR_ATmega644__)
  int size = 4096;                      // if ATMega644
#elif defined(__AVR_ATmega328P__)
  int size = 2048;                      // if ATmega328
#elif defined(__AVR_ATmega168__)
  int size = 1024;                      // if ATmega168
#endif
  byte *buf;
  //memset(FreeChar,0,sizeof(FreeChar));
  //memset(message,0,sizeof(message));
  while ((buf = (byte *) malloc(--size)) == NULL);
  free(buf);
  return size;
}


// store error strings in flash to save RAM
// From fat16print example
// http://code.google.com/p/fat16lib/
#define error(s) error_P(PSTR(s))
void error_P(const char* str) {
  PgmPrint("error: ");
  SerialPrintln_P(str);
  if (card.errorCode) {
    digitalWrite(ERROR_LED, HIGH);
    PgmPrint("SD error: ");
    Serial.print(card.errorCode, HEX);
  }
  while(1);
}

void openElement(){
  file.print(myGPX.getOpen());
  //Serial << F(_GPX_HEAD);
  delay(WRDELAY);
  //myGPX.setName("TestName");
  //myGPX.setDesc("foofoofoo");
  //file.print(myGPX.getMetaData());
  //delay(WRDELAY);
  //myGPX.setName("track name");
  //myGPX.setDesc("Track description");
  //myGPX.setSrc("SUP500Ff");
  //Serial.print(myGPX.getMetaData());
  //delay(WRDELAY);
  file.print(myGPX.getTrakOpen());
  delay(WRDELAY);
  //file.print(myGPX.getInfo());
  //delay(WRDELAY);
  file.print(myGPX.getTrakSegOpen());
  if (file.writeError || !file.sync()) error ("print or sync");
}

void closeElement(){
  file.print(myGPX.getTrakSegClose());
  file.print(myGPX.getTrakClose());
  file.print(myGPX.getClose());
  if (file.writeError || !file.sync()) error ("print or sync");
}

void setup() {
  // Setup serial port
  Serial.begin(9600);
  gps.begin(9600);
  
  //setup pins & init to low
  pinMode(ERROR_LED, OUTPUT);
  pinMode(SDWRITE_LED, OUTPUT);
  pinMode(ENABLED_LED, OUTPUT);
  pinMode(DONE_LED, OUTPUT);
  pinMode(COLLECT_SW, INPUT);
  digitalWrite(ERROR_LED, LOW);
  digitalWrite(SDWRITE_LED, LOW);
  digitalWrite(ENABLED_LED, LOW);
  digitalWrite(DONE_LED, LOW);
 
  // initialize the SD card
  // from fat16print example
  // http://code.google.com/p/fat16lib/
  if (!card.init()) error("card.init");
  if (!Fat16::init(&card)) error("Fat16::init");
  
  // create a new file
  char name[] = "PRINT00.TXT";
  for (uint8_t i = 0; i < 100; i++) {
    name[5] = i/10 + '0';
    name[6] = i%10 + '0';
    // O_CREAT - create the file if it does not exist
    // O_EXCL - fail if the file exists
    // O_WRITE - open for write
    if (file.open(name, O_CREAT | O_EXCL | O_WRITE)) break;
  }
  if (!file.isOpen()) error ("create");
  PgmPrint("Printing to: ");
  Serial.println(name);
  
  // clear write error
  file.writeError = false;
  
}

void loop(){
  long lat, lon;
  unsigned long fix_age, time, date, speed, course;
  unsigned long chars;
  unsigned short sentences, failed_checksum;
  
  
  //decide if we need to open or close the GPX element
  if ((state == 0 )&&(digitalRead(COLLECT_SW)==LOW)){
    openElement();
    state=1;
    digitalWrite(ENABLED_LED, HIGH);
  }
  if ((state == 1 )&&(digitalRead(COLLECT_SW)==HIGH)){
    closeElement();
    state=0;
    digitalWrite(ENABLED_LED, LOW);
    digitalWrite(DONE_LED, HIGH);
  }
  
  digitalWrite(SDWRITE_LED, LOW);
  if(gps.available() && state) {
    int c = gps.read();
    if (gpsParser.encode(c)){
      digitalWrite(SDWRITE_LED, HIGH);
      gpsParser.get_position(&lat, &lon, &fix_age);
      
      file.print(myGPX.getPt(GPX_TRKPT,lat,lon));
      
      gps.print(lat);
      gps.print(",");
      gps.print(lon);
      gps.print("\r");
      //Serial.print(String(lat)+"\n");
      if (file.writeError || !file.sync()) error ("print or sync");
      
    }
    
  } 
}
