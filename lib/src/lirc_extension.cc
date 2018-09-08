#include <lirc/lirc_client.h>
#include <unistd.h>
#include <stdio.h>
#include "dart_api.h"
#include "dart_native_api.h"

struct FunctionLookup {
    const char* name;
    Dart_NativeFunction function;
};

Dart_Handle HandleError(Dart_Handle handle);
Dart_NativeFunction ResolveName(Dart_Handle name, int argc, bool* auto_setup_scope);
void lircReceiverServicePort(Dart_NativeArguments arguments);
void lircTransmitterGetLocalSocket(Dart_NativeArguments arguments);
void lircTransmitterServicePort(Dart_NativeArguments arguments);
void wrappedLircReceiver(Dart_Port dest_port_id, Dart_CObject* message);
void wrappedLircTransmitter(Dart_Port dest_port_id, Dart_CObject* message);
bool sendMessage(const char* msg, bool error, Dart_Port port_id);

DART_EXPORT Dart_Handle lirc_extension_Init(Dart_Handle parent_library) {
    if (Dart_IsError(parent_library)) {
        return parent_library;
    }

    Dart_Handle result_code = Dart_SetNativeResolver(parent_library, ResolveName, NULL);

    if (Dart_IsError(result_code)) {
        return result_code;
    }
    return Dart_Null();
}

Dart_Handle HandleError(Dart_Handle handle) {
    if (Dart_IsError(handle)) {
        Dart_PropagateError(handle);
    }
    return handle;
}

FunctionLookup function_list[] = {
    {"LircReceiver_ServicePort", lircReceiverServicePort},
    {"LircTransmitter_GetLocalSocket", lircTransmitterGetLocalSocket},
    {"LircTransmitter_ServicePort", lircTransmitterServicePort},
    {NULL, NULL}};

Dart_NativeFunction ResolveName(Dart_Handle name, int argc, bool* auto_setup_scope) {
    if (!Dart_IsString(name)) {
        return NULL;
    }

    Dart_NativeFunction result = NULL;

    if (auto_setup_scope == NULL) {
        return NULL;
    }

    Dart_EnterScope();
    const char* cname;
    HandleError(Dart_StringToCString(name, &cname));

    for (int i=0; function_list[i].name != NULL; ++i) {
        if (strcmp(function_list[i].name, cname) == 0) {
            *auto_setup_scope = true;
            result = function_list[i].function;
            break;
        }
    }

    Dart_ExitScope();
    return result;
}

/**
 ** SendPort _getLircReceiverServicePort() native "LircReceiver_ServicePort";
 **/
void lircReceiverServicePort(Dart_NativeArguments arguments) {
    Dart_EnterScope();
    Dart_SetReturnValue(arguments, Dart_Null());
    Dart_Port service_port = Dart_NewNativePort("LircReceiverService", wrappedLircReceiver, false);

    if (service_port != ILLEGAL_PORT) {
        Dart_Handle send_port = HandleError(Dart_NewSendPort(service_port));
        Dart_SetReturnValue(arguments, send_port);
    }

    Dart_ExitScope();
}

/**
 ** int _getLircTransmitterLocalSocket(String path) native "LircTransmitter_GetLocalSocket";
 **/
void lircTransmitterGetLocalSocket(Dart_NativeArguments arguments) {
    Dart_EnterScope();
    Dart_Handle path_object = HandleError(Dart_GetNativeArgument(arguments, 0));

    int fd;
    const char* path = NULL;

    if (Dart_IsString(path_object)) {
        Dart_StringToCString(path_object, &path);
    }

    fd = lirc_get_local_socket(path, false);

    Dart_SetReturnValue(arguments, HandleError(Dart_NewInteger(fd)));
    Dart_ExitScope();
}

/**
 ** SendPort _getLircTransmitterServicePort() native "LircTransmitter_ServicePort";
 **/
void lircTransmitterServicePort(Dart_NativeArguments arguments) {
    Dart_EnterScope();
    Dart_SetReturnValue(arguments, Dart_Null());
    Dart_Port service_port = Dart_NewNativePort("LircTransmitterService", wrappedLircTransmitter, false);

    if (service_port != ILLEGAL_PORT) {
        Dart_Handle send_port = HandleError(Dart_NewSendPort(service_port));
        Dart_SetReturnValue(arguments, send_port);
    }

    Dart_ExitScope();
}

void wrappedLircReceiver(Dart_Port dest_port_id, Dart_CObject* message) {
    Dart_Port reply_port_id = ILLEGAL_PORT;

    if (message->type == Dart_CObject_kArray && message->value.as_array.length == 3) {
        Dart_CObject* param0 = message->value.as_array.values[0]; // Name of client in logging contexts (LIRC)
        Dart_CObject* param1 = message->value.as_array.values[1]; // Path to lircrc config file. If NULL the default file is used. (LIRC)
        Dart_CObject* param2 = message->value.as_array.values[2]; // Sendport (Dart)

        if (param0->type == Dart_CObject_kString &&
            (param1->type == Dart_CObject_kString || param1->type == Dart_CObject_kNull) &&
            param2->type == Dart_CObject_kSendPort) {

            // Data from Dart vm
            char* progname = param0->value.as_string;
            char* configPath = (param1->type == Dart_CObject_kString) ? param1->value.as_string : NULL;
            reply_port_id = param2->value.as_send_port.id;

            if (lirc_init(progname, 1) == -1) {
                sendMessage("Whoops could not run lirc_init!", true, reply_port_id);
                return;
            }

            struct lirc_config *config;
            char *code;
            char *c;
            int ret;
            bool sendport_online = true;

            if (lirc_readconfig(configPath, &config, NULL) == 0) {
                while (lirc_nextcode(&code) == 0 && sendport_online) {
                    if (code == NULL) continue;

                    while ((ret = lirc_code2char(config, code, &c)) == 0 && c != NULL && sendport_online) {
                        sendport_online = sendMessage(c, false, reply_port_id);
                    }
                    free(code);
                    if(ret == -1 || sendport_online == false) break;
                }
                lirc_freeconfig(config);
            }
            lirc_deinit();
        }
    }
}

void wrappedLircTransmitter(Dart_Port dest_port_id, Dart_CObject* message) {
    if (message->type == Dart_CObject_kArray && message->value.as_array.length == 2) {
        Dart_CObject* param0 = message->value.as_array.values[0]; // File Descriptor for LIRC sending (int)
        Dart_CObject* param1 = message->value.as_array.values[1]; // LIRC command to send to LIRC

        if ((param0->type == Dart_CObject_kInt32  || param0->type == Dart_CObject_kInt64) &&
            (param1->type == Dart_CObject_kString || param1->type == Dart_CObject_kNull)) {

            int fd;
            switch (param0->type) {
                case Dart_CObject_kInt32:
                    fd = param0->value.as_int32;
                    break;
                case Dart_CObject_kInt64:
                    fd = param0->value.as_int32;
                    break;
                default:
                    fprintf(stderr, "Expected an int64 or int32 as the second argument, is: %d.\n", param0->type);
                    return;
            }

            if (param1->type == Dart_CObject_kNull) {
                close(fd);
            } else {
                int r;
                char* lircCommand = param1->value.as_string;
                lirc_cmd_ctx command;

                r = lirc_command_init(&command, lircCommand);
                if (r != 0) {
                    fprintf(stderr, "Whops, lirc_command_init returned: %d.\n", r);
                    return;
                }

                do
                    r = lirc_command_run(&command, fd);
                while (r == EAGAIN);

                if (r != 0) {
                    fprintf(stderr, "Whops, lirc_command_run returned: %d.\n", r);
                    return;
                }
            }
        }
    }
}

bool sendMessage(const char* msg, bool error, Dart_Port port_id) {
    Dart_CObject dartMsg;
    dartMsg.type = Dart_CObject_kString;
    dartMsg.value.as_string = (char*) msg;

    Dart_CObject dartError;
    dartError.type = Dart_CObject_kBool;
    dartError.value.as_bool = error;

    Dart_CObject dartArray;
    dartArray.type = Dart_CObject_kArray;
    dartArray.value.as_array.length = 2;
    dartArray.value.as_array.values = new Dart_CObject*[2];
    dartArray.value.as_array.values[0] = &dartMsg;
    dartArray.value.as_array.values[1] = &dartError;

    return Dart_PostCObject(port_id, &dartArray);
}
