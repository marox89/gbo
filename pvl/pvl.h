#ifndef PVL_H_
#define PVL_H_

#define DEBUG 0

#define PORT_NAME "/dev/serial/by-id/usb-Prolific_Technology_Inc._USB-Serial_Controller_D-if00-port0"
#define RRD_CMD "rrdupdate"
#define RRD_PATH "/var/local/pvl.rrd"

#define PORT_RATE 9600
#define PORT_BITS 8
#define PORT_STOPBITS 1

#define INIT_STR "aaaa010000000004000159"
#define GET_SERIAL_STR "aaaa010000000000000155"
#define CONF_SERIAL_STR "aaaa0100000000010b31313032444130313433010373"
#define SET_DATA_FORMAT_STR "aaaa010000010100000157"
#define GET_VERSION_STR "aaaa01000001010300015a"
#define SET_PARAM_FORMAT_STR "aaaa010000010101000158"
#define GET_DATA_STR "aaaa010000010102000159"
#define GET_PARAM_STR "aaaa01000001010400015b"

typedef struct pvl_data {
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
} pvl_data;

typedef struct pvl_ctx {
    pvl_data *data;
    struct sp_port *port;
    char **rrd;
    char *in_buffer;
    char *out_buffer;
} pvl_ctx;

int pvl_ctx_init(pvl_ctx **);

int pvl_open_port(pvl_ctx *);

void debug_msg(const char *msg);

void hex_to_raw(const char *hex, char *raw);

void format_data(const char *raw, pvl_data *data);

int write_read(const char *, pvl_ctx *, int out, int in);

int pvl_init(pvl_ctx *);

int pvl_get_data(pvl_ctx *);
#endif // PVL_H_
