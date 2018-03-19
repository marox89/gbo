#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <libserialport.h>
#include <rrd.h>
#include "pvl.h"

int pvl_ctx_init(pvl_ctx **ctx)
{
    *ctx = (pvl_ctx *)malloc(sizeof(pvl_ctx));
    if (*ctx == NULL) return EXIT_FAILURE;

    (*ctx)->rrd = (char **)calloc(4, sizeof(char *));
    if ((*ctx)->rrd == NULL) return EXIT_FAILURE;

    (*ctx)->rrd[0] = (char *)malloc(1024);
    if ((*ctx)->rrd[0] == NULL) return EXIT_FAILURE;

    (*ctx)->rrd[1] = (char *)malloc(1024);
    if ((*ctx)->rrd[1] == NULL) return EXIT_FAILURE;

    (*ctx)->rrd[2] = (char *)malloc(1024);
    if ((*ctx)->rrd[2] == NULL) return EXIT_FAILURE;

    (*ctx)->rrd[3] = (char *)malloc(1024);
    if ((*ctx)->rrd[3] == NULL) return EXIT_FAILURE;

    (*ctx)->in_buffer = (char *)malloc(255);
    if ((*ctx)->in_buffer == NULL) return EXIT_FAILURE;

    (*ctx)->out_buffer = (char *)malloc(255);
    if ((*ctx)->out_buffer == NULL) return EXIT_FAILURE;

    (*ctx)->data = (pvl_data *)malloc(sizeof(pvl_data));
    if ((*ctx)->data == NULL) return EXIT_FAILURE;

    strcpy((*ctx)->rrd[0], RRD_CMD);
    strcpy((*ctx)->rrd[1], RRD_PATH);
    (*ctx)->rrd[3] = NULL;

    return EXIT_SUCCESS;
}

int pvl_open_port(pvl_ctx *ctx)
{
    if (sp_get_port_by_name(PORT_NAME, &(ctx->port)) != SP_OK) return EXIT_FAILURE;

    sp_set_baudrate(ctx->port, PORT_RATE);
    sp_set_bits(ctx->port, PORT_BITS);
    sp_set_parity(ctx->port, SP_PARITY_NONE);
    sp_set_stopbits(ctx->port, PORT_STOPBITS);

    if (sp_open(ctx->port, SP_MODE_READ_WRITE) != SP_OK) return EXIT_FAILURE;

    return EXIT_SUCCESS;
}

int pvl_init(pvl_ctx *ctx)
{
    debug_msg("Flushing port buffers before init.");
    sp_flush(ctx->port, SP_BUF_BOTH);

    debug_msg("Invertor init:");
    if (write_read(INIT_STR, ctx, 11, 0) != SP_OK) return EXIT_FAILURE;

    debug_msg("Request serial number:");
    if (write_read(GET_SERIAL_STR, ctx, 11, 21) != SP_OK) return EXIT_FAILURE;

    debug_msg("Confirm serial number:");
    if (write_read(CONF_SERIAL_STR, ctx, 22, 12) != SP_OK) return EXIT_FAILURE;

    debug_msg("Version request:");
    if (write_read(GET_VERSION_STR, ctx, 11, 75) != SP_OK) return EXIT_FAILURE;

    debug_msg("Parameter format:");
    if (write_read(SET_PARAM_FORMAT_STR, ctx, 11,
                   17) != SP_OK) return EXIT_FAILURE;

    debug_msg("Request parameters:");
    if (write_read(GET_PARAM_STR, ctx, 11, 23) != SP_OK) return EXIT_FAILURE;

    debug_msg("Data format:");
    if (write_read(SET_DATA_FORMAT_STR, ctx, 11, 38) != SP_OK) return EXIT_FAILURE;

    debug_msg("Flushing port buffers before data loop.");
    sp_flush(ctx->port, SP_BUF_BOTH);

    return EXIT_SUCCESS;
}

int write_read(const char *msg, pvl_ctx *ctx, int count_out, int count_in)
{
    int rc;

    struct sp_port *port = ctx->port;
    char *out_buffer = ctx->out_buffer;
    char *in_buffer = ctx->in_buffer;

    hex_to_raw(msg, out_buffer);
    rc = sp_blocking_write(port, out_buffer, count_out, 1000);
    if (rc == count_out) {
        debug_msg("Successfully written.");
        debug_msg(msg);
    } else {
        fprintf(stderr, "ERROR: Could not write all chars: %d written.\n", rc);
        return EXIT_FAILURE;
    }

    sleep(2);

    if (sp_input_waiting(port) == count_in) {
        debug_msg("Correct number of chars in input buffer.");
    } else {
        fprintf(stderr,
                "ERROR: Wrong number of chars in input buffer: %d\n",
                sp_input_waiting(port));
        return EXIT_FAILURE;
    }

    rc = sp_blocking_read_next(port, in_buffer, sp_input_waiting(port),
                                        1000);

    if (count_in != 0) {
        if (rc == count_in) {
            debug_msg("Read all chars from input buffer.");
        } else {
            fprintf(stderr,
                    "ERROR: Could not read all chars from input buffer: %d\n",
                    rc);
            return EXIT_FAILURE;
        }
    }

    return SP_OK;
}

int pvl_get_data(pvl_ctx *ctx)
{
    int rc;

    struct sp_port *port = ctx->port;
    char *out_buffer = ctx->out_buffer;
    char *in_buffer = ctx->in_buffer;
    pvl_data *data = ctx->data;

    hex_to_raw(GET_DATA_STR, out_buffer);
    sp_blocking_write(port, out_buffer, 11, 1000);

    sleep(5);

    if (sp_input_waiting(port) == 65) {
        debug_msg("All data are waiting in buffer.");
    } else {
        fprintf(stderr, "ERROR: Not complete data waiting was expecting 65 got: %d\n",
                sp_input_waiting(port));
        return EXIT_FAILURE;
    }

    sp_blocking_read_next(port, in_buffer, sp_input_waiting(port),
                                        1000);
    format_data(in_buffer, data);

    if (DEBUG) {
        printf("\nPV Data:\n\n");
        printf("Temp:\t\t%.1f degrees C\n", (float)data->temp / 10);
        printf("U Panel:\t%.1f V\n", (float)data->u_panel1 / 10);
        printf("I Panel:\t%.1f A\n", (float)data->i_panel1 / 10);
        printf("W Dnes:\t\t%.2f kWh\n", (float)data->e_today / 100);
        printf("U Siet:\t\t%.1f V\n", (float)data->u_grid / 10);
        printf("I Siet:\t\t%.1f A\n", (float)data->i_grid / 10);
        printf("Frekvencia:\t%.2f Hz\n", (float)data->freq / 100);
        printf("Vykon:\t\t%d W\n", data->e_now);
        printf("Celkovy vykon:\t%d kWh\n", (float)data->e_total / 10);
        printf("Celkova doba:\t%d hodin\n", data->t_total);
        printf("Avg celej doby:\t%f kW\n",
               (float)(((float)data->e_total / (float)data->t_total) / 10));
        printf("\n");
    }

    sprintf(ctx->rrd[2], "N:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d",
            data->temp,
            data->u_panel1,
            data->i_panel1,
            data->u_panel2,
            data->i_panel2,
            data->u_panel3,
            data->i_panel3,
            data->e_today,
            data->u_grid,
            data->i_grid,
            data->freq,
            data->e_now,
            data->e_total,
            data->t_total
           );

    if (DEBUG) {
        printf("Will be written to rrd\n");

        printf("[0]: %s\n", ctx->rrd[0]);
        printf("[1]: %s\n", ctx->rrd[1]);
        printf("[2]: %s\n", ctx->rrd[2]);
    }

    rrd_update(3, ctx->rrd);

    return SP_OK;
}

void debug_msg(const char *msg)
{
    if (DEBUG) {
        printf("DEBUG: %s\n", msg);
    }
}

void hex_to_raw(const char *hex, char *raw)
{
    int i;
    const char *hex_pointer;

    i = 0;
    hex_pointer = hex;

    while (sscanf(hex_pointer, "%02x", &raw[i++])) {
        hex_pointer += 2;
        if (hex_pointer >= hex + strlen(hex)) break;
    }
}

void format_data(const char *raw, pvl_data *data)
{
    data->temp = (raw[9] * 256) + raw[10];
    data->u_panel1 = (raw[15] * 256) + raw[16];
    data->i_panel1 = (raw[21] * 256) + raw[22];
    data->e_today = (raw[23] * 256) + raw[24];
    data->i_grid = (raw[27] * 256) + raw[28];
    data->u_grid = (raw[29] * 256) + raw[30];
    data->freq = (raw[31] * 256) + raw[32];
    data->e_now = (raw[33] * 256) + raw[34];
    data->e_total = ((raw[37] * 256) + raw[38]) * 65536 + ((
                        raw[39] * 256) + raw[40]);
    data->t_total = ((raw[41] * 256) + raw[42]) * 65536 + ((
                        raw[43] * 256) + raw[44]);
}

