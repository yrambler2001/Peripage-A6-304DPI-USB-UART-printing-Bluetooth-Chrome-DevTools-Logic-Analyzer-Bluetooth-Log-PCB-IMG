
#ifdef PIN_NEOPIXEL
#define BUILTIN_RGBLED_PIN PIN_NEOPIXEL
#else
#define BUILTIN_RGBLED_PIN 12  // ESP32 has no builtin RGB LED (PIN_NEOPIXEL)
#endif

#define NR_OF_LEDS     8 * 4
#define NR_OF_ALL_BITS 24 * NR_OF_LEDS

//
// Note: This example uses Neopixel LED board, 32 LEDs chained one
//      after another, each RGB LED has its 24 bit value
//      for color configuration (8b for each color)
//
//      Bits encoded as pulses as follows:
//
//      "0":
//         +-------+              +--
//         |       |              |
//         |       |              |
//         |       |              |
//      ---|       |--------------|
//         +       +              +
//         | 0.4us |   0.85 0us   |
//
//      "1":
//         +-------------+       +--
//         |             |       |
//         |             |       |
//         |             |       |
//         |             |       |
//      ---+             +-------+
//         |    0.8us    | 0.4us |

rmt_data_t led_data[NR_OF_ALL_BITS];

void setup() {
  Serial.begin(115200);
  if (!rmtInit(BUILTIN_RGBLED_PIN, RMT_TX_MODE, RMT_MEM_NUM_BLOCKS_1, 80000000)) {
    Serial.println("init sender failed\n");
  }
  Serial.println("real tick set to: 100ns");
}

int color[] = {0x55, 0x11, 0x77};  // Green Red Blue values
int led_index = 0;

void loop() {
  // Init data with only one led ON
  int led, col, bit;
  int i = 0;
  for (led = 0; led < NR_OF_LEDS; led++) {
    for (col = 0; col < 3; col++) {
      for (bit = 0; bit < 8; bit++) {
        // if ((color[col] & (1 << (7 - bit))) && (led == led_index)) {
          // led_data[i].level0 = 1;
          // led_data[i].duration0 = 8;
          // led_data[i].level1 = 0;
          // led_data[i].duration1 = 4;
        // } else {
          led_data[i].level0 = 1;
          led_data[i].duration0 = 1;
          led_data[i].level1 = 0;
          led_data[i].duration1 = 1;
        // }
        // i++;
      }
    }
  }
  // make the led travel in the panel
  if ((++led_index) >= NR_OF_LEDS) {
    led_index = 0;
  }
  // Send the data and wait until it is done
  rmtWrite(BUILTIN_RGBLED_PIN, led_data, NR_OF_ALL_BITS, RMT_WAIT_FOR_EVER);
  delay(100);
}