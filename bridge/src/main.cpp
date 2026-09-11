#include <fmt/core.h>
#include <Arduino.h>
#include "baud_rate_adapter.h"

enum class Mode {
    BaudRateAdapter,
    InternetBridge,
};

static const Mode MODE = Mode::BaudRateAdapter;

extern "C" void app_main() {
    initArduino();

    switch (MODE) {
        case Mode::BaudRateAdapter:
            BaudRateAdapter::start();
            break;
        case Mode::InternetBridge:
            break;
    }

    vTaskDelete(nullptr);
}
