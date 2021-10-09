/**
 * A client library for rofication.
 * 
 * This client, once constructed, can only send one command.
 */
namespace Lago {
    enum ROFICATION_COMMAND {
        COUNT
    }

    public errordomain ROFICATION_ERROR {
        RPC_ERROR
    }

    public class NotificationDesc {
        public int64 id { get; private set; }
        public string summary { get; private set; }
        public string body { get; private set; }
        public string application { get; private set; }
        public int64 urgency { get; private set; }
        // TODO add 'actions' (list of string)

        internal NotificationDesc (Json.Object responseJson) {
            id = responseJson.get_int_member ("id");
            summary = responseJson.get_string_member ("summary");
            body = responseJson.get_string_member ("body");
            application = responseJson.get_string_member ("application");
            urgency = responseJson.get_int_member ("urgency");
        }
    }

    public class Client {
        private Socket socket;
        private int buffer_size = 1024 * 512;

        public Client (string socket_str) throws GLib.Error {
            var socketAddress = new UnixSocketAddress (socket_str);

            socket = new Socket (SocketFamily.UNIX, SocketType.STREAM, SocketProtocol.DEFAULT);
            assert (socket != null);

            socket.connect (socketAddress);
            socket.set_blocking (true);
        }

        ~Client () {
            if (socket != null) {
                socket.close ();
            }
        }

        public List<NotificationDesc> get_notifications () throws ROFICATION_ERROR, GLib.Error {
            ssize_t sent = socket.send ("list\n".data);

            debug ("Sent " + sent.to_string () + " bytes to notification backend.\n");

            uint8[] buffer = new uint8[buffer_size];

            ssize_t len = socket.receive (buffer);

            debug ("Received  " + len.to_string () + " bytes from notification backend.\n");

            string payload = (string) buffer;

            stdout.printf("%s\n", payload);

            Json.Parser parser = new Json.Parser ();
            parser.load_from_data (payload);

            var doc = parser.get_root ().get_array ();

            var list = new List<NotificationDesc> ();

            foreach (var notificationDoc in doc.get_elements ()) {
                list.append (new NotificationDesc (notificationDoc.get_object ()));
            }

            return list;
        }

        public void delete_notification_by_id (int64 id) throws GLib.Error {
            var message = "del:" + id.to_string () + "\n";
            debug (message);

            ssize_t sent = socket.send (message.data);

            debug ("Sent " + sent.to_string () + " bytes to notification backend.\n");
        }

        public void delete_notification_by_app (string app) throws GLib.Error {
            ssize_t sent = socket.send (("dela:" + app + "\n").data);

            debug ("Sent " + sent.to_string () + " bytes to notification backend.\n");
        }
    }
}
