#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>

#include <modbus.h>
#include <rrd.h>

#define DEBUG 0

#define DS_NUM 6
#define ADDR 8
#define C_NUM 4
#define PARAMS_NUM 3

#define CLOCKID CLOCK_REALTIME
#define SIG SIGUSR1

#define MAX_PARAM_SIZE 500
#define RRD_FILE "/var/local/gbo.rrd"

#define errExit(msg)    do { perror(msg); exit(EXIT_FAILURE); \
    } while (0)

modbus_t *ctx;
char *params[PARAMS_NUM + 1];
uint16_t ans[DS_NUM];
uint16_t rele;
int i;
int c[C_NUM];
float percentage;

void gbl_data()
{
    //char rrd_update_cmd[MAX_CMD_SIZE];

    modbus_read_input_registers(ctx, ADDR, DS_NUM, ans);
    modbus_read_registers(ctx, 10, 1, &rele);

    rele = rele - 54784;

    /* convert to negative values FFFF(hex) is -1(dec) */

    for (i = 0; i < C_NUM; i++) {
        if (ans[i] > 30000) {
            c[i] = ans[i] - 65536;
        } else {
            c[i] = ans[i];
        }
    }

    percentage = MODBUS_GET_LOW_BYTE(ans[5]);
    percentage = (percentage / 255) * 100;

    sprintf(params[2], "N:%d:%d:%d:%d:%d:%.2f:%d",
            c[0], c[1], c[2], c[3], ans[4], percentage, rele);

    rrd_update(PARAMS_NUM, params);
    if (DEBUG) {
    printf("%s\n", params[2]);
    }
}

int
main(int argc, char *argv[])
{
    int i;

    /* Check for arguments */

    if (argc != 2) {
        fprintf(stderr, "Usage: %s <freq-secs>\n",
                argv[0]);
        exit(EXIT_FAILURE);
    }

    /* Allocate and set parameters for rrd_update */

    for (i = 0; i < PARAMS_NUM + 1; i++) {
        params[i] = (char *)malloc(MAX_PARAM_SIZE);
    }

    strcpy(params[0], "rrdupdate");
    strcpy(params[1], RRD_FILE);
    params[3] = NULL;

    /* Init modbus */

    ctx = modbus_new_rtu("/dev/serial/by-id/usb-FTDI_FT232R_USB_UART_AJ03KXCR-if00-port0",
                         9600, 'N', 8, 2);

    if (ctx == NULL) {
        errExit("modbus_new_rtu");
    }

    modbus_rtu_set_serial_mode(ctx, MODBUS_RTU_RS485);

    modbus_set_slave(ctx, 200);

    if (modbus_connect(ctx) == -1) {
        errExit("modbus_connect");
    }

    // modbus_set_debug(ctx, TRUE);

    /* Establish handler for timer signal */

    while (1) {
        gbl_data();
        sleep(2);
    }

    exit(EXIT_SUCCESS);
}
