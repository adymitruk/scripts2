#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include "font8x8_basic.h"
#include <sys/ioctl.h>
#include <unistd.h>

#define ROWS 8
#define PIXEL "\u2588"
#define GREEN "\033[38;5;2m"
#define RESET "\033[0m"

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
    int totalCols = 2 * padding + messageLength * 8; // Total columns including padding and message

    // Initialize the matrix with padding, message, and padding
    char matrix[ROWS][totalCols];
    for (int i = 0; i < ROWS; i++) {
        for (int j = 0; j < totalCols; j++) {
            if (j < padding || j >= padding + messageLength * 9) {
                matrix[i][j] = ' '; // Padding
            } else {
                int charIndex = (j - padding) / 8;
                int charCol = (j - padding) % 8;
                matrix[i][j] = (characters[message[charIndex]][i] & (1 << charCol)) ? 'x' : ' '; // Message
            }
        }
    }
    // Print empty lines to create space for the marquee
    for (int i = 0; i < ROWS; i++) {
        printf("\n");
    }
    // Print the matrix with a moving window of size COLS
    for (int offset = 0; offset < totalCols - COLS + 1; offset++) {
        printf("\033[%dA", ROWS); // Move cursor up to clear lines
        for (int i = 0; i < ROWS; i++) {
            for (int j = offset; j < offset + COLS; j++) {
                if (matrix[i][j] == 'x') {
                    printf(GREEN PIXEL RESET);
                } else {
                    printf(" ");
                }
            }
            printf("\n");
        }
        usleep(10000); // Delay for animation
    }

    return 0;
}
