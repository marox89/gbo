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

void debug_msg(const char *state, enum sp_return return_code)
{
    if (DEBUG) {
        printf("DEBUG: %s: %d\n", state, return_code);
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

int init(struct sp_port **port, char *buffer, char *raw)
{
    const char *init_string = "aaaa010000000004000159";
    const char *serial_string = "aaaa010000000000000155";
    const char *confirm_serial = "aaaa0100000000010b31313032444130313433010373";

    const char *port_name =
        "/dev/serial/by-id/usb-Prolific_Technology_Inc._USB-Serial_Controller_D-if00-port0";

    enum sp_return return_code;

    // Obtain port

    return_code = sp_get_port_by_name(port_name, port);
    debug_msg("Obtain port", return_code);

    if (return_code != SP_OK) {
        return return_code;
    }

    // Port configuration

    sp_set_baudrate(*port, 9600);
    sp_set_bits(*port, 8);
    sp_set_parity(*port, SP_PARITY_NONE);
    sp_set_stopbits(*port, 1);

    // Opening port

    return_code = sp_open(*port, SP_MODE_READ_WRITE);
    debug_msg("Open port", return_code);

    if (return_code != SP_OK) {
        return return_code;
    }

    // Inverter init...

    hex_to_raw(init_string, raw);
    return_code = sp_blocking_write(*port, raw, 11, 1000);
    debug_msg("Inverter init", return_code);

    // Get serial...
    hex_to_raw(serial_string, raw);
    return_code = sp_blocking_write(*port, raw, 11, 1000);
    debug_msg("Obtain serial number", return_code);

    sleep(1);

    if (sp_input_waiting(*port) < 0) {
        return -1;
    }

    // Read serial...
    return_code = sp_blocking_read_next(*port, buffer, sp_input_waiting(*port),
                                        1000);
    // Confirm serial number...

    hex_to_raw(confirm_serial, raw);
    return_code = sp_blocking_write(*port, raw, 22, 1000);
    debug_msg("Confirmed serial number", return_code);

    sleep(1);

    if (sp_input_waiting(*port) < 0) {
        return -1;
    }

    // Read confirmation of serial...
    return_code = sp_blocking_read_next(*port, buffer, sp_input_waiting(*port),
                                        1000);

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

    if (sp_input_waiting(port) < 65) {
        printf("Less than 65 chars! %d waiting...\n", sp_input_waiting(port));
        return -1;
    }

    return_code = sp_blocking_read_next(port, buffer, sp_input_waiting(port),
                                        1000);
    format_data(buffer, &data);

    if (DEBUG) {
        printf("Read: %d\n\n", return_code);

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
    } else {
        printf("before sprintf...\n");
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

        printf("Will be written to rrd\n");

        printf("[0]: %s\n", params[0]);
        printf("[1]: %s\n", params[1]);
        printf("[2]: %s\n", params[2]);
        rrd_update(3, params);
        printf("after rrd_update...\n");
    }

    return SP_OK;
}

int main(int argc, char *argv[])
{
    int i;
    char *params[4];
    enum sp_return return_code;

    struct sp_port *port;

    char *buffer = (char *)calloc(255, sizeof(char));
    char *raw = (char *)calloc(255, sizeof(char));

    for (i = 0; i < 4; i++) {
        params[i] = (char *)malloc(1024);
    }

    strcpy(params[0], "rrdupdate");
    strcpy(params[1], "/var/local/pvl.rrd");
    params[3] = NULL;

    while (1) {
        return_code = init(&port, buffer, raw);

        if (return_code == SP_OK) {
            do {
        printf("before data...\n");
                return_code = data(port, buffer, raw, params);
        printf("after after...\n");
            } while (return_code != -1);
        } else {
            sleep(60);
        }
    }

    exit(EXIT_SUCCESS);
}
