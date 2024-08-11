vTaskSuspendAll(); and xTaskResumeAll





#include "soc/rtc_wdt.h"
static portMUX_TYPE my_mutex;

// the setup function runs once when you press reset or power the board
void setup() {
  // initialize digital pin LED_BUILTIN as an output.
  pinMode(13, OUTPUT);
  rtc_wdt_protect_off(); 
  // esp_task_wdt_delete(NULL)
rtc_wdt_disable();
disableCore0WDT();
disableLoopWDT();
// WiFi.disconnect();
// WiFi.persistent(false);
// WiFi.mode(WIFI_OFF);
  vPortCPUInitializeMutex(&my_mutex);

}

// the loop function runs over and over again forever
void loop() {
  uint32_t volatile register ilevel = XTOS_DISABLE_ALL_INTERRUPTS;
//critical section
while(true){


  portENTER_CRITICAL(&my_mutex);

  digitalWrite(13, HIGH);  // turn the LED on (HIGH is the voltage level)
  digitalWrite(13, LOW);   // turn the LED off by making the voltage LOW
  portEXIT_CRITICAL(&my_mutex);
}
XTOS_RESTORE_INTLEVEL(ilevel);

}











// https://narodstream.ru/esp8266-urok-12-spi-drajver-indikatora-max7219/
