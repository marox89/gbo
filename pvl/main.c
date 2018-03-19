#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include "pvl.h"

int main(int argc, char *argv[])
{
    pvl_ctx *ctx;

    int initialized;

    // Alloc

    if (pvl_ctx_init(&ctx) == EXIT_SUCCESS) {
        debug_msg("Memory allocated.");
    } else {
        fprintf(stderr, "ERROR: Could not allocate memory.\n");
        exit(EXIT_FAILURE);
    }

    // Obtain port

    if (pvl_open_port(ctx) == EXIT_SUCCESS) {
        debug_msg("Port opened.");
    } else {
        fprintf(stderr, "ERROR: Could not open port.\n");
        exit(EXIT_FAILURE);
    }

    // Main loop

    debug_msg("Starting main loop.");

    while (1) {
        do {
            if (pvl_init(ctx) == EXIT_SUCCESS) {
                initialized = 1;
                debug_msg("PV initialized successfully.");
            } else {
                initialized = 0;
                fprintf(stderr, "ERROR: Could not init PV! Sleeping...\n");
                sleep(60);
            }
        } while (!initialized);

        do {
        } while (pvl_get_data(ctx) == EXIT_SUCCESS);
    }

    exit(EXIT_SUCCESS);
}
