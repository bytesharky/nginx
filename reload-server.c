/*
 * Simple HTTP server to handle reload requests.
 * Listens on a specified port and path, executes "nginx -s reload" on valid requests.
 * 
 * Because acme.sh runs in a container, it cannot execute "nginx -s reload" directly.
 * This simple HTTP service handles reload requests for Nginx.
 * After acme.sh successfully updates certificates, it can call this service via curl to reload Nginx.
 * 
 * The listening port and path can be configured via Docker environment variables:
 *   RELOAD_PORT  - default: 8080
 *   RELOAD_PATH  - default: /reload
 * 
 * Do not expose this service to the public internet for security reasons.
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <netinet/in.h>

#define BUFFER_SIZE 4096

int main() {
    int server_fd, client_fd;
    struct sockaddr_in addr;
    char buffer[BUFFER_SIZE];

    const char* port_env = getenv("RELOAD_PORT");
    const char* path_env = getenv("RELOAD_PATH");

    int PORT = port_env ? atoi(port_env) : 8080;
    const char* RELOAD_PATH = path_env ? path_env : "/reload";

    server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) { perror("socket"); return 1; }

    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        perror("bind"); return 1;
    }

    if (listen(server_fd, 5) < 0) { perror("listen"); return 1; }

    printf("Reload server listening on port %d, path %s\n", PORT, RELOAD_PATH);

    while (1) {
        client_fd = accept(server_fd, NULL, NULL);
        if (client_fd < 0) { perror("accept"); continue; }

        int n = read(client_fd, buffer, BUFFER_SIZE - 1);
        if (n > 0) {
            buffer[n] = '\0';

            if (strstr(buffer, RELOAD_PATH) != NULL) {
                FILE *fp = popen("nginx -s reload 2>&1", "r");
                char output[BUFFER_SIZE] = {0};
                size_t len = 0;

                if (fp) {
                    while (fgets(output + len, sizeof(output) - len, fp) != NULL) {
                        len = strlen(output);
                    }
                    int status = pclose(fp);

                    char response[BUFFER_SIZE * 2];
                    if (WIFEXITED(status) && WEXITSTATUS(status) == 0) {
                        snprintf(response, sizeof(response),
                            "HTTP/1.1 200 OK\r\n"
                            "Content-Type: text/html; charset=utf-8\r\n\r\n"
                            "<html><head><title>Nginx Reload</title></head><body>"
                            "<p style='color:green;font-weight:bold;'>Nginx reloaded successfully</p>"
                            "<pre>%s</pre>"
                            "</body></html>",
                            output
                        );
                    } else {
                        snprintf(response, sizeof(response),
                            "HTTP/1.1 500 Internal Server Error\r\n"
                            "Content-Type: text/html; charset=utf-8\r\n\r\n"
                            "<html><head><title>Nginx Reload</title></head><body>"
                            "<p style='color:red;font-weight:bold;'>Failed to reload Nginx</p>"
                            "<pre>%s</pre>"
                            "</body></html>",
                            output
                        );
                    }
                    write(client_fd, response, strlen(response));
                } else {
                    const char *response =
                        "HTTP/1.1 500 Internal Server Error\r\n"
                        "Content-Type: text/html; charset=utf-8\r\n\r\n"
                        "<html><head><title>Nginx Reload</title></head><body>"
                        "<p style='color:red;font-weight:bold;'>Failed to execute reload</p>"
                        "</body></html>";
                    write(client_fd, response, strlen(response));
                }
            } else {
                const char *response =
                    "HTTP/1.1 404 Not Found\r\n"
                    "Content-Type: text/html; charset=utf-8\r\n\r\n"
                    "<html><head><title>Nginx Reload</title></head><body>"
                    "<p style='color:red;font-weight:bold;'>Not Found</p>"
                    "</body></html>";
                write(client_fd, response, strlen(response));
            }
        }

        close(client_fd);
    }

    close(server_fd);
    return 0;
}
