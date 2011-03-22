const int PEOPLE_WIDTH = 12;
const int PEOPLE_HEIGHT = 11;
const int PEOPLE_CHARS = 24;
const int PEOPLE_SEQ_CHARS = PEOPLE_CHARS * 7;

const dog_pgm_uint8_t IN_PEOPLE_BITMAPS[] = {
  0x0, 0x0,
  0x0E, 0x00,
  0x11, 0x00,
  0x11, 0x00,
  0xE, 0x00,
  0x8, 0x00,
  0x1C, 0x00,
  0x2B, 0x80,
  0x48, 0x00,
  0x34, 0x00,
  0x42, 0x00,
  0xE1, 0xC0,
  0x0, 0x0,
  0xE, 0x00,
  0x11, 0x00,
  0x11, 0x00,
  0xE, 0x00,
  0x8, 0x00,
  0x1C, 0x00,
  0x2F, 0x00,
  0x28, 0x00,
  0x14, 0x00,
  0xE2, 0x00,
  0xC3, 0x80,
  0x1C, 0x00,
  0x22, 0x00,
  0x22, 0x00,
  0x1C, 0x00,
  0x8, 0x00,
  0x18, 0x00,
  0x2E, 0x00,
  0x18, 0x00,
  0x8, 0x00,
  0x74, 0x00,
  0x44, 0x00,
  0x7, 0x00,
  0x1C, 0x00,
  0x22, 0x00,
  0x22, 0x00,
  0x1C, 0x00,
  0x8, 0x00,
  0x18, 0x00,
  0x1C, 0x00,
  0x18, 0x00,
  0x8, 0x00,
  0x18, 0x00,
  0x28, 0x00,
  0x1E, 0x00,
  0x1C, 0x00,
  0x22, 0x00,
  0x22, 0x00,
  0x1C, 0x00,
  0x8, 0x00,
  0x18, 0x00,
  0x1C, 0x00,
  0xC, 0x00,
  0x8, 0x00,
  0xC, 0x00,
  0x17, 0x00,
  0x1C, 0x00,
  0x0, 0x00,
  0x1C, 0x00,
  0x22, 0x00,
  0x22, 0x00,
  0x1C, 0x00,
  0x8, 0x00,
  0x18, 0x00,
  0x2E, 0x00,
  0x28, 0x00,
  0xC, 0x00,
  0x13, 0x80,
  0x38, 0x00,
  0x0, 0x00,
  0xE, 0x00,
  0x11, 0x00,
  0x11, 0x00,
  0xE, 0x00,
  0x8, 0x00,
  0x1C, 0x00,
  0x2F, 0x00,
  0x28, 0x00,
  0x14, 0x00,
  0x22, 0x00,
  0x73, 0x80
};

const dog_pgm_uint8_t OUT_PEOPLE_BITMAPS[] = {
  0x00, 0x00,
  0x70, 0x00,
  0x88, 0x00,
  0x88, 0x00,
  0x70, 0x00,
  0x10, 0x00,
  0x38, 0x00,
  0xD4, 0x01,
  0x12, 0x00,
  0x2C, 0x00,
  0x42, 0x00,
  0x87, 0x03,
  0x00, 0x00,
  0x70, 0x00,
  0x88, 0x00,
  0x88, 0x00,
  0x70, 0x00,
  0x10, 0x00,
  0x38, 0x00,
  0xF4, 0x00,
  0x14, 0x00,
  0x28, 0x00,
  0x47, 0x00,
  0xC3, 0x01,
  0x38, 0x00,
  0x44, 0x00,
  0x44, 0x00,
  0x38, 0x00,
  0x10, 0x00,
  0x18, 0x00,
  0x74, 0x00,
  0x18, 0x00,
  0x10, 0x00,
  0x2E, 0x00,
  0x22, 0x00,
  0xE0, 0x00,
  0x38, 0x00,
  0x44, 0x00,
  0x44, 0x00,
  0x38, 0x00,
  0x10, 0x00,
  0x18, 0x00,
  0x38, 0x00,
  0x18, 0x00,
  0x10, 0x00,
  0x18, 0x00,
  0x14, 0x00,
  0x78, 0x00,
  0x38, 0x00,
  0x44, 0x00,
  0x44, 0x00,
  0x38, 0x00,
  0x10, 0x00,
  0x18, 0x00,
  0x38, 0x00,
  0x30, 0x00,
  0x10, 0x00,
  0x30, 0x00,
  0xE8, 0x00,
  0x38, 0x00,
  0x00, 0x00,
  0x38, 0x00,
  0x44, 0x00,
  0x44, 0x00,
  0x38, 0x00,
  0x10, 0x00,
  0x18, 0x00,
  0x74, 0x00,
  0x14, 0x00,
  0x30, 0x00,
  0xC8, 0x01,
  0x1C, 0x00,
  0x00, 0x00,
  0x70, 0x00,
  0x88, 0x00,
  0x88, 0x00,
  0x70, 0x00,
  0x10, 0x00,
  0x38, 0x00,
  0xF4, 0x00,
  0x14, 0x00,
  0x28, 0x00,
  0x44, 0x00,
  0xCE, 0x01
};

