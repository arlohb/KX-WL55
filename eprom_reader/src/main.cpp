#include <Arduino.h>

// Set lower to only use x address pins
const uint8_t addrLen = 17;

// A0 - A18
uint8_t A[] = {
    23, 25, 27, 29,
    31, 33, 35, 37,
    39, 41, 43, 45,
    47, 49, 51, 53,
    22, 24, 26,
};

// D0 - D7
uint8_t D[] = {
    2, 3, 4, 5,
    6, 7, 8, 9,
};

uint32_t addr = 0;

void setup() {
    Serial.begin(115200);
    
    for (uint8_t a : A) {
        pinMode(a, OUTPUT);
    }
    
    for (uint8_t d : D) {
        pinMode(d, INPUT);
    }
}

// 0th bit is the right-most bit
bool getBit(uint32_t x, uint8_t bit) {
    return (x & (1 << bit)) >> bit;
}

uint8_t readAddr(uint32_t addr) {
    // Assumes A0 is right-most (least significant), this assumption may be incorrect
    for (int i = 0; i < addrLen; i++) {
        bool bit = getBit(addr, i);
        digitalWrite(A[i], bit);
    }
    
    delayMicroseconds(1);
    
    uint8_t result = 0;
    
    // Assumes D0 is right-most (least significant), this assumption may be incorrect
    for (int i = 0; i < 8; i++) {
        bool bit = digitalRead(D[i]);
        result |= bit << i;
    }
    
    return result;
}

char nibbleToHex(uint8_t nibble) {
    return nibble >= 10
        ? nibble + 'A' - 10
        : nibble + '0';
}

String byteToHex(uint8_t byte) {
    char l = nibbleToHex((byte & 0xF0) >> 4);
    char r = nibbleToHex(byte & 0x0F);
    return String(l) + String(r);
}

String addrToHex(uint32_t addr) {
    return String(byteToHex((addr & 0x00FF0000) >> 16))
        + String(byteToHex((addr & 0x0000FF00) >> 8))
        + String(byteToHex(addr & 0x000000FF));
}

void loop() {
    if (addr >= ((uint32_t) 1 << addrLen)) {
        delay(1);
        return;
    }

    uint8_t byte = readAddr(addr);
    
    if (addr % 32 == 0) {
        Serial.print('\n');
        Serial.print(addrToHex(addr) + " : ");
    } else {
        Serial.print(' ');
        
    }

    Serial.print(byteToHex(byte));
    
    addr++;
}
