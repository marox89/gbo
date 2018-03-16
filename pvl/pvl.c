#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>

#include <libserialport.h>
#include <rrd.h>

#define DEBUG 0

struct Data {
    unsigned int temp;
    unsigned int u_panel1;
    unsigned int i_panel1;
    unsigned int u_panel2;
    unsigned int i_panel2;
    unsigned int u_panel3;
    unsigned int i_panel3;
    unsigned int e_today;
    unsigned int i_grid;
    unsigned int u_grid;
    unsigned int freq;
    unsigned int e_now;
    unsigned long e_total;
    unsigned long t_total;
};

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

    hex_pointer = hex;
    i = 0;

    while (sscanf(hex_pointer, "%02x", &raw[i++])) {
        hex_pointer += 2;
        if (hex_pointer >= hex + strlen(hex)) break;
    }
}

void format_data(const char *raw, struct Data *data)
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

int init(struct sp_port *port, char *buffer, char *raw)
{
    const char *init_string = "aaaa010000000004000159";
    const char *serial_string = "aaaa010000000000000155";
    const char *confirm_serial = "aaaa0100000000010b31313032444130313433010373";
    const char *data_format = "aaaa010000010100000157";

    enum sp_return return_code;

    debug_msg("Flushing port buffers.");
    sp_flush(port, SP_BUF_BOTH);

    // Inverter init...

    hex_to_raw(init_string, raw);
    return_code = sp_blocking_write(port, raw, 11, 1000);

    if (return_code == 11) {
        debug_msg("Successfully written init string.");
        debug_msg(init_string);
    } else {
        fprintf(stderr, "ERROR: Could not write init string: %d\n", return_code);
        return -1;
    }

    sleep(1);

    // Get serial...
    hex_to_raw(serial_string, raw);
    return_code = sp_blocking_write(port, raw, 11, 1000);

    if (return_code == 11) {
        debug_msg("Successfully written serial string.");
        debug_msg(serial_string);
    } else {
        fprintf(stderr, "ERROR: Could not write serial string: %d\n", return_code);
        return -1;
    }

    sleep(1);

    if (sp_input_waiting(port) == 21) {
        debug_msg("Right number of waiting chars for serial number from PV.");
    } else {
        fprintf(stderr,
                "ERROR: Wrong number of waiting chars for read serial number from PV: %d\n",
                sp_input_waiting(port));
        return -1;
    }

    // Read serial...
    return_code = sp_blocking_read_next(port, buffer, sp_input_waiting(port),
                                        1000);

    if (return_code == 21) {
        debug_msg("Read right number of chars for serial number from PV.");
    } else {
        fprintf(stderr,
                "ERROR: Read wrong number of chars for read serial number from PV: %d\n",
                return_code);
        return -1;
    }

    // Confirm serial number...
    hex_to_raw(confirm_serial, raw);
    return_code = sp_blocking_write(port, raw, 22, 1000);

    if (return_code == 22) {
        debug_msg("Successfully written confirmation of serial number.");
        debug_msg(confirm_serial);
    } else {
        fprintf(stderr, "ERROR: Could not write confirmation of serial number: %d\n", return_code);
        return -1;
    }

    sleep(1);

    if (sp_input_waiting(port) == 12) {
        debug_msg("Right number of waiting chars for confirmation of serial number.");
    } else {
        fprintf(stderr,
                "ERROR: Wrong number of waiting chars for confirmation of serial number: %d\n",
                sp_input_waiting(port));
        return -1;
    }

    // Read confirmation of serial...
    return_code = sp_blocking_read_next(port, buffer, sp_input_waiting(port),
                                        1000);

    if (return_code == 12) {
        debug_msg("Read right number of chars for confirmation of serial number.");
    } else {
        fprintf(stderr,
                "ERROR: Read wrong number of chars for confirmation of serial number: %d\n",
                return_code);
        return -1;
    }

    // Set Data format

    hex_to_raw(data_format, raw);
    return_code = sp_blocking_write(port, raw, 22, 1000);

    if (return_code == 22) {
        debug_msg("Successfully written data format request.");
        debug_msg(data_format);
    } else {
        fprintf(stderr, "ERROR: Could not write data format request: %d\n", return_code);
        return -1;
    }

    sleep(1);

    if (sp_input_waiting(port) == 38) {
        debug_msg("Right number of waiting chars for data format request.");
    } else {
        fprintf(stderr,
                "ERROR: Wrong number of waiting chars for data format request: %d\n",
                sp_input_waiting(port));
        return -1;
    }

    // Read confirmation of serial...
    return_code = sp_blocking_read_next(port, buffer, sp_input_waiting(port),
                                        1000);

    if (return_code == 38) {
        debug_msg("Read right number of chars for confirmation of data format.");
    } else {
        fprintf(stderr,
                "ERROR: Read wrong number of chars for confirmation of data format: %d\n",
                return_code);
        return -1;
    }

    debug_msg("Flushing port buffers before data loop.");
    sp_flush(port, SP_BUF_BOTH);

    return SP_OK;
}

int data(struct sp_port *port, char *buffer, char *raw, char **params)
{
    const char *data_string = "aaaa010000010102000159";
    enum sp_return return_code;
    struct Data data;

    hex_to_raw(data_string, raw);

    return_code = sp_blocking_write(port, raw, 11, 1000);

    sleep(5);

    if (sp_input_waiting(port) == 65) {
        debug_msg("All data are waiting in buffer.");
    } else {
        fprintf(stderr, "ERROR: Not complete data waiting was expecting 65 got: %d\n",
            sp_input_waiting(port));
        return -1;
    }

    return_code = sp_blocking_read_next(port, buffer, sp_input_waiting(port),
                                        1000);
    format_data(buffer, &data);

    if (DEBUG) {
        printf("\nPV Data:\n\n");
        printf("Temp:\t\t%.1f degrees C\n", (float)data.temp / 10);
        printf("U Panel:\t%.1f V\n", (float)data.u_panel1 / 10);
        printf("I Panel:\t%.1f A\n", (float)data.i_panel1 / 10);
        printf("W Dnes:\t\t%.2f kWh\n", (float)data.e_today / 100);
        printf("U Siet:\t\t%.1f V\n", (float)data.u_grid / 10);
        printf("I Siet:\t\t%.1f A\n", (float)data.i_grid / 10);
        printf("Frekvencia:\t%.2f Hz\n", (float)data.freq / 100);
        printf("Vykon:\t\t%d W\n", data.e_now);
        printf("Celkovy vykon:\t%d kWh\n", (float)data.e_total / 10);
        printf("Celkova doba:\t%d hodin\n", data.t_total);
        printf("Avg celej doby:\t%f kW\n",
               (float)(((float)data.e_total / (float)data.t_total) / 10));
        printf("\n");
    }

    sprintf(params[2], "N:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d",
            data.temp,
            data.u_panel1,
            data.i_panel1,
            data.u_panel2,
            data.i_panel2,
            data.u_panel3,
            data.i_panel3,
            data.e_today,
            data.u_grid,
            data.i_grid,
            data.freq,
            data.e_now,
            data.e_total,
            data.t_total
           );

    if (DEBUG) {
        printf("Will be written to rrd\n");

        printf("[0]: %s\n", params[0]);
        printf("[1]: %s\n", params[1]);
        printf("[2]: %s\n", params[2]);
    }

    rrd_update(3, params);

    return SP_OK;
}

int main(int argc, char *argv[])
{
    int i, counter;
    int data_error_flag;
    char *params[4];
    enum sp_return return_code;

    struct sp_port *port;

    const char *port_name =
        "/dev/serial/by-id/usb-Prolific_Technology_Inc._USB-Serial_Controller_D-if00-port0";

    // Alloc memory

    char *buffer = (char *)calloc(255, sizeof(char));
    char *raw = (char *)calloc(255, sizeof(char));

    for (i = 0; i < 4; i++) {
        params[i] = (char *)malloc(1024);
    }

    strcpy(params[0], "rrdupdate");
    strcpy(params[1], "/var/local/pvl.rrd");
    params[3] = NULL;

    // Obtain port

    return_code = sp_get_port_by_name(port_name, &port);

    if (return_code == SP_OK) {
        debug_msg("Port obtained successfully.");
    } else {
        fprintf(stderr, "ERROR: Could not obtain port: %s\n", port_name);
        return return_code;
    }

    // Port configuration

    sp_set_baudrate(port, 9600);
    sp_set_bits(port, 8);
    sp_set_parity(port, SP_PARITY_NONE);
    sp_set_stopbits(port, 1);

    // Opening port

    return_code = sp_open(port, SP_MODE_READ_WRITE);

    if (return_code == SP_OK) {
        debug_msg("Port opened successfully.");
    } else {
        fprintf(stderr, "ERROR: Could not open port!\n");
        return return_code;
    }

    debug_msg("Starting main loop.");
    while (1) {
        do {
            return_code = init(port, buffer, raw);

            if (return_code == SP_OK) {
                debug_msg("PV initialized successfully.");
            } else {
                fprintf(stderr, "ERROR: Could not init PV! Sleeping...\n");
                sleep(60);
            }
        } while (return_code != SP_OK);

        do {
            return_code = data(port, buffer, raw, params);
        } while (return_code != -1);
    }

    exit(EXIT_SUCCESS);
}
