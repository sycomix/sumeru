#include <sys/ioctl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <err.h>

#include <bluetooth.h>
#include <hci.h>
#include <hci_lib.h>

#include <glib.h>
#include <uuid.h>
#include <sdp.h>

#include <att.h> 
#include <gattrib.h>
#include <btio.h>
#include <gatttool.h>
#include <util.h>

#include "gatt.h"

#define TX_MTU          24
#define LINEFEED        0x0a
#define CARRIAGE_RETURN 0x0d

static GMainLoop *event_loop;
static volatile gboolean write_complete = 1;
static volatile gboolean response_received = 1;
static volatile gboolean jmp_addr_done = 0;
static volatile gboolean jmp_initiated = 0;
static gchar write_buf[TX_MTU];
static unsigned int write_addr = (0x10000 - 16);
static unsigned int jmp_addr = 0x10000;
static gchar *write_filename = "./unknown";
static GIOChannel *wchan;
static GAttrib *wattrib;

static void
write_complete_cb(gpointer data)
{
    write_complete = 1;
}


static guint
write_cmd(GAttrib *attrib, uint16_t handle, const uint8_t *value,
          int vlen, GDestroyNotify notify, gpointer user_data)
{
    gatt_write_cmd(attrib, handle, value, vlen, write_complete_cb, NULL);        
}


enum RESPONSE_STATE { R_EXPECT_OK };

static unsigned int w_addr_set = 0;
static enum RESPONSE_STATE resp_state;

static void
write_bootloader_initiate_jmp(GAttrib *attrib)
{
    write_buf[0] = 'j';
    resp_state = R_EXPECT_OK;
    write_cmd(attrib, 0x25, write_buf, 1, NULL, NULL);
    write_complete = 1;
}

static int
compute_16b_cksum(unsigned char *buf)
{
    unsigned int c = 0;
    for (int i = 0; i < 16; ++i)
        c ^= buf[i];
    return c;
}

static void
write_bootloader_data(GAttrib *attrib)
{
    write_buf[0] = 'w';
    write_buf[17] = compute_16b_cksum(write_buf+1);
    resp_state = R_EXPECT_OK;
    write_cmd(attrib, 0x25, write_buf, 18, NULL, NULL);
    write_complete = 1;
}

static void
write_bootloader_addr(GAttrib *attrib, unsigned int addr)
{
    memcpy(write_buf + 1, &addr, 4);
    write_buf[0] = 'a';
    write_buf[5] = write_buf[1] ^ write_buf[2] ^ write_buf[3] ^ write_buf[4];
    resp_state = R_EXPECT_OK;
    write_cmd(attrib, 0x25, write_buf, 6, NULL, NULL);
    write_complete = 1;
}

static gboolean 
write_cb(GIOChannel *source, GIOCondition cond, gpointer user_data)
{
    gsize rlen;
    GError *err = 0;
    GAttrib *attrib = user_data;
    GIOStatus status;

    if (write_complete != 1 || response_received != 1) {
        g_printerr("Invalid state for write_cb, programmer error\n");
        exit(1);
    }

    write_complete = 0;
    response_received = 0;

    write_addr += 16;

    if ((write_addr & 0xff) == 0) 
        g_printerr("Status: writing to location 0x%x\n", write_addr);

    if (w_addr_set != 1) {
        w_addr_set = 1;
        write_bootloader_addr(attrib, write_addr);
    } else {
        memset(write_buf, '0', 16);
        status = g_io_channel_read_chars(source, write_buf + 1, 16, &rlen, &err);

        if (status != G_IO_STATUS_NORMAL) {
            if (status == G_IO_STATUS_EOF) {
                write_bootloader_addr(attrib, jmp_addr);
                jmp_addr_done = 1;
            } else {
                g_printerr("Error reading source file\n");
                exit(1);
            }
        } else {
            write_bootloader_data(attrib);
        }
    }

    return false;
}

static void
process_response(const uint8_t *data, uint16_t len)
{
    if (write_complete == 1 && response_received == 0) {
        if (resp_state == R_EXPECT_OK) {
            if (data[0] == 'O') {
                response_received = 1;
                if (jmp_addr_done != 1) {
                    g_io_add_watch(wchan, G_IO_IN, write_cb, wattrib);
                } else if (jmp_initiated == 0) {
                    write_complete = 0;
                    response_received = 0;
                    write_bootloader_initiate_jmp(wattrib);
                    jmp_initiated = 1;
                } else {
                    g_printerr("Status: Programming completed!\n");
                    g_main_loop_quit(event_loop);
                }
            } else {
                g_printerr("Invalid response: expecting O got %c\n", data[0]);
                exit(1);
            }
        } else
            g_printerr("Unhandled respose state %d\n", (int)resp_state);
    }
}


static void
events_handler(const uint8_t *pdu, uint16_t len, gpointer user_data)
{
    GAttrib *attrib = user_data;
    uint8_t *opdu;
    uint16_t handle, i, olen = 0;
    size_t plen;

    handle = get_le16(&pdu[1]);
    switch (pdu[0]) {
    case ATT_OP_HANDLE_NOTIFY:
        process_response(pdu + 3, len - 3);
        return;
    case ATT_OP_HANDLE_IND:
        g_printerr("\nIndication   handle = 0x%04x value: ", handle);
        for (i = 3; i < len; i++) 
            g_printerr("%02x ", pdu[i]);
        g_printerr("\n");
        break;
    default:
        g_printerr("\nInvalid opcode\n");
        return;
    }

    if (pdu[0] == ATT_OP_HANDLE_NOTIFY)
        return;

    opdu = g_attrib_get_buffer(attrib, &plen);
    olen = enc_confirmation(opdu, plen);
    if (olen > 0)
        g_attrib_send(attrib, 0, opdu, olen, NULL, NULL, NULL);

    return;
}


static gboolean
listen_start(gpointer user_data)
{
    GAttrib *attrib = user_data;
    g_attrib_register(
        attrib, ATT_OP_HANDLE_NOTIFY, GATTRIB_ALL_HANDLES,
        events_handler, attrib, NULL);
    g_attrib_register(
        attrib, ATT_OP_HANDLE_IND, GATTRIB_ALL_HANDLES,
        events_handler, attrib, NULL);
    return FALSE;
}

static void
connect_cb(GIOChannel *chan, GError *err, gpointer user_data)
{
    if (err) {
        g_printerr("%s\n", err->message);
        g_main_loop_quit(event_loop);
        g_error_free(err);
        return;
    }

    uint16_t mtu, cid;
    bt_io_get(chan, &err, 
                BT_IO_OPT_IMTU, &mtu,
                BT_IO_OPT_CID, &cid, 
                BT_IO_OPT_INVALID);
    if (err) {
        g_error_free(err);
        mtu = ATT_DEFAULT_LE_MTU;
    }

    if (cid == ATT_CID) 
        mtu = ATT_DEFAULT_LE_MTU;

    g_printerr("Status: Connected: MTU=%d\n", (int)mtu);    

    wattrib = g_attrib_new(chan, mtu, false);
    g_idle_add(listen_start, wattrib); 

    err = NULL;
    wchan = g_io_channel_new_file(write_filename, "r", &err);
    g_io_channel_set_encoding(wchan, NULL, &err);
    if (wchan == NULL) {
        g_printerr("Error opening file: %s\n", write_filename);
        exit(1);
    }
    //g_io_channel_set_flags(wchan, G_IO_FLAG_NONBLOCK, &err);
    g_io_add_watch(wchan, G_IO_IN, write_cb, wattrib);
    g_printerr("Status: Programming started.\n");
}


int
main(int argc, char **argv)
{
    GIOChannel *chan = NULL;
    GError *err = NULL;

    if (argc != 2) {
        g_printerr("Usage: %s <filename>\n", argv[0]);
        exit(1);
    }
    write_filename = strdup(argv[1]);

    g_printerr("Status: Connecting.\n");
    chan = gatt_connect(
                "hci0", "00:25:83:00:52:20",
                //"hci0", "50:F1:4A:6F:82:F7",
                "public", "low", 0, 0,
                connect_cb, &err);

    event_loop = g_main_loop_new(NULL, FALSE);
    g_main_loop_run(event_loop);
    g_main_loop_unref(event_loop);
    return 0;
}
