#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <mariadb/mysql.h>
#include <rrd.h>



int main(int argc, char *argv[])
{
    MYSQL *mysql;

    mysql = mysql_init(NULL); 

    if (mysql == NULL) {
        printf("Error init failed...\n");
        exit(EXIT_FAILURE);
    }

    if(mysql_real_connect(mysql,
        "mariadb101.websupport.sk",
        "vdj8hyl0",
        "dM3dyV6942",
        "vdj8hyl0",
        3312,
        "",
        0
        ) == NULL) {
        printf("Error could not connect...\n");
        exit(EXIT_FAILURE);
    }
    
    


    exit(EXIT_SUCCESS);
}
