#include <dirent.h>
#include <err.h>
#include <event2/buffer.h>
#include <event2/event.h>
#include <event2/http.h>
#include <event2/keyvalq_struct.h>
#include <event2/util.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <chpl-mem.h>

  static char* mymalloc(int64_t n) {
  char *ret = (char*) chpl_malloc(n);

    return ret;
  }
  static void myfree(char *x) {
    chpl_free(x);
  }


 void http_handler(struct evhttp_request *request, void *privParams);

  void c_http_handler(struct evhttp_request *request, void *privParams) {

  http_handler(request, privParams);
}

void CreateServerCB(struct evhttp* server){
  evhttp_set_gencb(server, c_http_handler, 0);
}
