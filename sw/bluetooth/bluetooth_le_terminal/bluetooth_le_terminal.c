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

#define TX_MTU          16
#define LINEFEED        0x0a
#define CARRIAGE_RETURN 0x0d

static GMainLoop *event_loop;
static volatile gboolean write_complete = 1;


static void
write_complete_cb(gpointer data)
{
    write_complete = 1;
}


static guint
write_cmd(GAttrib *attrib, uint16_t handle, const uint8_t *value,
          int vlen, GDestroyNotify notify, gpointer user_data)
{
    write_complete = 0;
    gatt_write_cmd(attrib, handle, value, vlen, write_complete_cb, NULL);        
}

static gchar pending_buf[TX_MTU + 4];
static int pending_len = 0;

static gboolean 
write_cb(GIOChannel *source, GIOCondition cond, gpointer user_data)
{
    gchar buf[TX_MTU + 4];
    gsize rlen;
    GError *err = 0;

    if (write_complete != 1)
        return true;

    if (pending_len == 0) {
        g_io_channel_read_chars(source, buf, TX_MTU, &rlen, &err);
    } else {
        memcpy(buf, pending_buf, pending_len);
        rlen = pending_len;
        pending_len = 0;
    }

    if (rlen == 0) {
        /*g_main_loop_quit(event_loop);*/
        return false; 
        /*return true;*/
    } else {
        GAttrib *attrib = user_data;
        write_cmd(attrib, 0x25, buf, rlen, NULL, NULL);
#if XXX_NOTYET
        int offset = 0;
        int i;
        for (i = 0; i < rlen; ++i) {
            if (buf[i] == LINEFEED) {
                gchar save = buf[i + 1];
                buf[i] = CARRIAGE_RETURN;
                buf[i + 1] = LINEFEED;
                write_cmd(
                    attrib, 0x25, 
                    buf + offset, i - offset + 2, 
                    NULL, NULL);        

                pending_len = rlen - (i + 1);
                memcpy(pending_buf, buf + (i + 1), pending_len); 
                return true;
            }
        }

        if (offset != i)
            write_cmd(
                    attrib, 0x25,
                    buf + offset, i - offset,
                    NULL, NULL);
#endif
    }
    return true;
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
        write(STDOUT_FILENO, pdu + 3, len - 3);
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
char_read_cb(
        guint8 status, const guint8 *pdu, guint16 plen,
        gpointer user_data)
{
        uint8_t value[plen];
        ssize_t vlen;

        if (status != 0) {
                g_printerr("Characteristic value/descriptor read failed: %s\n",
                        att_ecode2str(status));
                goto done;
        }

        vlen = dec_read_resp(pdu, plen, value, sizeof(value));
        if (vlen < 0) {
                g_printerr("Protocol error\n");
                goto done;
        }
        g_print("Characteristic value/descriptor: ");
        for (int i = 0; i < vlen; i++)
            g_print("%02x ", value[i]);
        g_print("\n");
done:
    return;
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

    g_printerr("Connected: MTU=%d\n", (int)mtu);    

    GAttrib *attrib = g_attrib_new(chan, mtu, false);
    g_idle_add(listen_start, attrib); 

    GIOChannel *wchan = g_io_channel_unix_new(STDIN_FILENO);
    err = NULL;
    g_io_channel_set_flags(wchan, G_IO_FLAG_NONBLOCK, &err);
    g_io_add_watch(wchan, G_IO_IN, write_cb, attrib);
}


int
main(int argc, char **argv)
{
    GIOChannel *chan = NULL;
    GError *err = NULL;

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
