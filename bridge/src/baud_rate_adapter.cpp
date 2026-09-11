#include "baud_rate_adapter.h"

#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/stream_buffer.h>

static const uint16_t BUFFER_SIZE = 2048;
static const uint32_t HOST_BAUD_RATE = 115200;
static const uint32_t WL55_BAUD_RATE = 13722;

static StreamBufferHandle_t wl55_to_host_stream = nullptr;
static StreamBufferHandle_t host_to_wl55_stream = nullptr;

static auto host_serial = Serial;
static auto wl55_serial = Serial1;

static void wl55_to_buffer(void* _) {
    while (true) {
        if (wl55_serial.available() > 0) {
            uint8_t data = wl55_serial.read();
            xStreamBufferSend(wl55_to_host_stream, &data, 1, portMAX_DELAY);
        }

        usleep(1000);
    }
}

static void buffer_to_host(void* _) {
    while (true) {
        uint8_t data;
        if (xStreamBufferReceive(wl55_to_host_stream, &data, 1, portMAX_DELAY) >= 1) {
            host_serial.write(data);
        }

        usleep(1000);
    }
}

static void host_to_buffer(void* _) {
    while (true) {
        if (host_serial.available() > 0) {
            uint8_t data = host_serial.read();
            xStreamBufferSend(host_to_wl55_stream, &data, 1, portMAX_DELAY);
        }

        usleep(1000);
    }
}

static void buffer_to_wl55(void* _) {
    while (true) {
        uint8_t data;
        if (xStreamBufferReceive(host_to_wl55_stream, &data, 1, portMAX_DELAY) >= 1) {
            wl55_serial.write(data);
        }

        usleep(1000);
    }
}

void BaudRateAdapter::start() {
    wl55_to_host_stream = xStreamBufferCreate(BUFFER_SIZE, 1);
    host_to_wl55_stream = xStreamBufferCreate(BUFFER_SIZE, 1);

    host_serial.begin(HOST_BAUD_RATE);
    wl55_serial.begin(WL55_BAUD_RATE, SERIAL_8N1, 2, 3);

    xTaskCreate(wl55_to_buffer, "wl55_to_buffer", 1024, nullptr, 10, nullptr);
    xTaskCreate(buffer_to_host, "buffer_to_host", 1024, nullptr, 10, nullptr);
    xTaskCreate(host_to_buffer, "host_to_buffer", 1024, nullptr, 10, nullptr);
    xTaskCreate(buffer_to_wl55, "buffer_to_wl55", 1024, nullptr, 10, nullptr);
}
