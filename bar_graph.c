#include <stdio.h>
#include <string.h>
#include "font8x8_basic.h"
#include <sys/ioctl.h>
#include <malloc.h>

#define ROWS 8
#define PIXEL "\u2588"
#define SPACE "\u205F"
#define CHAR_LEN 2

// Use the 8x8 representation of each character from font8x8_basic.h
char (*characters)[8] = font8x8_basic;

int main(int argc, char *argv[]) {

    struct winsize w;
    ioctl(0, TIOCGWINSZ, &w);
    int COLS = w.ws_col;
    char *message;
    if (argc > 1) {
        message = argv[1];
    } else {
        message = "hello world";
    }

    int messageLength = strlen(message);
    int padding = COLS; // Padding is equal to COLS
    size_t totalCols = 2 * padding + messageLength * 8; // Total columns including padding and message

    // Initialize the matrix with padding, message, and padding
    char matrix[ROWS][totalCols];
    for (int i = 0; i < ROWS; i++) {
        for (int j = 0; j < totalCols; j++) {
            if (j < padding || j >= padding + messageLength * 8) {
                matrix[i][j] = ' '; // Padding
            } else {
                int charIndex = (j - padding) / 8;
                int charCol = (j - padding) % 8;
                matrix[i][j] = (characters[message[charIndex]][i] & (1 << charCol)) ? 'x' : ' '; // Message
            }
        }
    }

    // row size in frames includes a new line character at the end
    int row_size = COLS * CHAR_LEN + 1;
    // frame size contains enough space for each unicode character, a new line per row and a null terminator at the end
    int frame_size = COLS * ROWS * CHAR_LEN + ROWS + 1;
    // frames are the width of COL. They will cover all offsets of the matrix
    int frame_count = padding * 2 + messageLength * 8;

    // array of length frame_count containing frame_size of chars
    char (*frames)[frame_size] = malloc(sizeof(char) * CHAR_LEN * frame_count * frame_size);

    for (int i = 0; i < frame_count; ++i) {
        for (int row = 0; row < ROWS; row++) {
            for (int col = i; col < COLS + i; col++) {
                if (matrix[row][col]=='x') {
                    frames[i][row * COLS + col * 2] = PIXEL[0];
                    frames[i][row * COLS + col * 2 + 1] = PIXEL[1];
                } else {
                    frames[i][row * COLS + col * 2] = SPACE[0];
                    frames[i][row * COLS + col * 2 + 1] = SPACE[1];
                }
            }
            frames[i][ row_size - 1 ] = '\n';
        }
        frames[i][row_size * ROWS] = 0;
    }

    // Show the animation 5 times
    for (int times = 0; times < 5; ++times){
        // Print each frame and then move up to clear the previous one
        for (int i = 0; i < frame_count; ++i) {
            printf("%s", frames[i]);
            printf("\033[%dA", ROWS); // This line moves cursor up to overwrite the previous frame
            //usleep(100000); // uncomment this if you want to slow down the animation
     }

    free(frames);
    return 0;
}