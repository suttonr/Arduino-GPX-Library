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
#include <SdFatUtil.h>
#include <SdFat.h>

#include <TinyGPS.h>
#include <NewSoftSerial.h>

NewSoftSerial gps(9,8);
TinyGPS gpsParser;

Sd2Card card;
SdVolume volume;
SdFile root;
SdFile file;

// store error strings in flash to save RAM
// From SdFatPrint Example
#define error(s) error_P(PSTR(s))
void error_P(const char* str) {
  PgmPrint("error: ");
  SerialPrintln_P(str);
  if (card.errorCode()) {
    digitalWrite(3, HIGH);
    PgmPrint("SD error: ");
    Serial.print(card.errorCode(), HEX);
    Serial.print(',');
    Serial.println(card.errorData(), HEX);
  }
  while(1);
}

void setup() {
  Serial.begin(9600);
  gps.begin(9600);
  pinMode(2, OUTPUT);
  pinMode(3, OUTPUT);
  digitalWrite(2, LOW);
  digitalWrite(3, LOW);
  if (!card.init(SPI_HALF_SPEED)) error("card.init failed");
  if (!volume.init(&card)) error("volume.init failed");
  if (!root.openRoot(&volume)) error("openRoot failed");
  // create a new file
  char name[] = "GPSDAT00.TXT";
  for (uint8_t i = 0; i < 100; i++) {
    name[6] = i/10 + '0';
    name[7] = i%10 + '0';
    // only create new file for write
    if (file.open(&root, name, O_CREAT | O_EXCL | O_WRITE)) break;
  }
  if (!file.isOpen()) error ("file.create");
}

void loop(){
  long lat, lon;
  unsigned long fix_age, time, date, speed, course;
  unsigned long chars;
  unsigned short sentences, failed_checksum;

  digitalWrite(3, LOW);
  if(gps.available()) {
    int c = gps.read();
    if (gpsParser.encode(c)){
      digitalWrite(3, HIGH);
      gpsParser.get_position(&lat, &lon, &fix_age);
      file.print(lat);
      file.print(",");
      file.print(lon);
      file.print("\n");
      gps.print(lat);
      gps.print(",");
      gps.print(lon);
      gps.print("\r");
      if (file.writeError || !file.sync()) error ("print or sync");
      
    }
    
    //Serial.print(c,BYTE);
  }

}
