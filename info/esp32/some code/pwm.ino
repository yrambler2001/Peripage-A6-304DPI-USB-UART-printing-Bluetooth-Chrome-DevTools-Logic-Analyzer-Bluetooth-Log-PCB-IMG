#include <MobaTools.h>
MoToStepper myStepper(320, HALFSTEP ); // 3200 is default value // 320 is steps to 1 rotation
rmt_channel_handle_t tx_channels[2] = {NULL}; // declare two channels

void setup() {

  // pinMode(12, OUTPUT);
  // pinMode(13, OUTPUT);
  // pinMode(14, OUTPUT);
  // pinMode(15, OUTPUT);

  // myStepper.attach( 12,13,14,15 ); 
  // myStepper.setSpeed(89); // rpm
  // myStepper.rotate(1);

  pinMode(12, OUTPUT);
  pinMode(13, OUTPUT);
  
rmt_channel_handle_t tx_channels[2] = {NULL}; // declare two channels
int tx_gpio_number[2] = {12, 13};
// install channels one by one
for (int i = 0; i < 2; i++) {
    rmt_tx_channel_config_t tx_chan_config = {
        .clk_src = RMT_CLK_SRC_DEFAULT,       // select source clock
        .gpio_num = tx_gpio_number[i],    // GPIO number
        .mem_block_symbols = 64,          // memory block size, 64 * 4 = 256 Bytes
        .resolution_hz = 1 * 1000 * 1000, // 1 MHz resolution
        .trans_queue_depth = 1,           // set the number of transactions that can pend in the background
    };
    ESP_ERROR_CHECK(rmt_new_tx_channel(&tx_chan_config, &tx_channels[i]));
}
// install sync manager
rmt_sync_manager_handle_t synchro = NULL;
rmt_sync_manager_config_t synchro_config = {
    .tx_channel_array = tx_channels,
    .array_size = sizeof(tx_channels) / sizeof(tx_channels[0]),
};
ESP_ERROR_CHECK(rmt_new_sync_manager(&synchro_config, &synchro));

ESP_ERROR_CHECK(rmt_transmit(tx_channels[0], led_strip_encoders[0], led_data, led_num * 3, &transmit_config));
// tx_channels[0] does not start transmission until call of `rmt_transmit()` for tx_channels[1] returns
ESP_ERROR_CHECK(rmt_transmit(tx_channels[1], led_strip_encoders[1], led_data, led_num * 3, &transmit_config));

}

// the loop function runs over and over again forever
void loop() {
  // delay(1000);                      // wait for a second
// GPIO.out_w1ts = ((uint32_t)1 << 12);
// GPIO.out_w1ts = ((uint32_t)1 << 13);
// GPIO.out_w1tc = ((uint32_t)1 << 13);
// GPIO.out_w1tc = ((uint32_t)1 << 12);

}
