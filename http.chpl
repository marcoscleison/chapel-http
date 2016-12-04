/*
 * Copyright (C) 2016 Marcos Cleison Silva Santana
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

 /*
  * Http module server for Chapel language.
  */

module Http{
use SysBasic;
use Regexp;
use Random;

require "event2/buffer.h";
require "event2/event.h";
require "event2/http.h";
require "event2/keyvalq_struct.h";
require "event2/util.h";
require "stdio.h";

//This header contains the trampoline for callback needed by libevent
require "callback.h";

extern "struct event_base"record event_base{};
extern "struct evhttp" record evhttp{};
extern "struct evbuffer"  record evbuffer{};
extern "struct evkeyvalq" record evkeyvalq{

};
extern "struct evhttp_request" record evhttp_request{
  var 	output_headers: c_ptr(evkeyvalq);
};
extern "struct evhttp_uri" record evhttp_uri{}; 
//Some C functions bindings.
extern proc mymalloc( n:int):c_ptr(c_char);
extern proc event_base_new():c_ptr(event_base);
extern proc evhttp_new(base):c_ptr(evhttp);
extern proc evhttp_set_allowed_methods(http,  method);
extern proc evhttp_set_cb(server:c_ptr(evhttp), str:c_string, fn: opaque, args:c_void_ptr);
extern proc evhttp_set_cb(server, str:c_string, fn, args);
extern proc evhttp_set_gencb	(http,	cb, arg);	
extern proc evhttp_bind_socket(server,str:c_string, port):c_int;
extern proc event_base_dispatch(ebase);
extern proc evhttp_free(server);
extern proc event_base_free(ebase);
extern proc evbuffer_new():c_ptr(evbuffer);
extern proc	evbuffer_add_printf (buf:c_ptr(evbuffer), fmt:c_string, vals...?numvals):c_int;
extern proc	evhttp_send_reply (req,  code:int, reason:c_string, databuf:c_ptr(evbuffer)):void;
extern proc evhttp_request_get_input_headers (req:c_ptr(evhttp_request) ):c_ptr(evkeyvalq);
extern proc evhttp_find_header	(	const 	headers:c_ptr(evkeyvalq),	key:c_string):c_string;			
extern proc evhttp_find_header	(	const ref 	headers: evkeyvalq,	key:c_string):c_string;			
extern proc evhttp_add_header	(headers:c_ptr(evkeyvalq),key:c_string,value:c_string):c_int;
extern proc evhttp_add_header	( ref headers:evkeyvalq,key:c_string,value:c_string):c_int;
extern proc evhttp_request_get_output_headers (req:c_ptr(evhttp_request)):c_ptr(evkeyvalq);

extern proc evhttp_request_get_command (const req:c_ptr(evhttp_request) ):c_int;
extern proc evhttp_request_get_input_buffer (req:c_ptr(evhttp_request)):c_ptr(evbuffer);
extern proc evbuffer_copyout (buf:c_ptr(evbuffer), data_out:c_ptr(uint(8)),  datlen:int):int;
extern proc evbuffer_get_length (const buf:c_ptr(evbuffer)):int;
extern proc evhttp_parse_query_str	(uri:c_string,ref	headers:evkeyvalq):c_int;			
extern proc evhttp_request_get_uri (const req:c_ptr(evhttp_request) ):c_string;
extern proc evhttp_uri_parse_with_flags	(source_uri:c_string,flags):c_ptr(evhttp_uri);		
extern proc evhttp_uri_get_path(  uri:c_ptr(evhttp_uri)):c_string;
extern proc evhttp_uri_get_query(const uri:c_ptr(evhttp_uri)):c_string;
extern proc printf(fmt:c_string,vals...?numvals);
extern proc chpl_malloc(n:int):c_ptr(c_char);

//Main entry point for requests callback
extern proc CreateServerCB(server:c_ptr(evhttp)):void;


//Global pointer to request handler
extern var c_http_handler:opaque;
extern var c_http_error_handler:opaque;
//Some HTTP verbs
const   EVHTTP_REQ_GET:int(32) = 1 << 0;
const   EVHTTP_REQ_POST:int(32) = 1 << 1;
const   EVHTTP_REQ_HEAD:int(32) = 1 << 2;
const   EVHTTP_REQ_PUT:int(32) = 1 << 3;
const   EVHTTP_REQ_DELETE:int(32) = 1 << 4;
const   EVHTTP_REQ_OPTIONS:int(32) = 1 << 5;
const   EVHTTP_REQ_TRACE:int(32) = 1 << 6;
const   EVHTTP_REQ_CONNECT:int(32) = 1 << 7;
const   EVHTTP_REQ_PATCH:int(32) = 1 << 8;
extern const  HTTP_OK:int;

var handlerDomain:domain(string);
var handlerList:[handlerDomain] Server;


/*
Http server class.
*/
class Server{
  
  var ebase : c_ptr(event_base);
  var server : c_ptr(evhttp);
  var routerHandler:Router;
  var addr:string;
  var port:int; 
  var address:string;

  proc Server(addr:string, port:int){

    this.addr = addr;
    this.port = port;
    this.address = this.addr+":"+this.port;
    writeln(this.address);
    this.ebase = event_base_new();
    this.server = evhttp_new(this.ebase);
    evhttp_set_allowed_methods(this.server, EVHTTP_REQ_GET|EVHTTP_REQ_POST);
    CreateServerCB(this.server);
    this.routerHandler = new Router(); 
  }
  //Get Router of urls for this server
  proc getRouter():Router{
    return this.routerHandler;
  }
  /*
  Gets ip binding  Address
  */
  proc getAddress(){
    return this.address;
  }

/*
TODO: Load content from filesystem
*/
  proc File(uri:string, path:string){

   
  }
/*
Listens connections and eventloop
*/
  proc Listen(){
    RegisterServer(this);

    if (evhttp_bind_socket(server, this.addr.localize().c_str(), this.port) != 0){
      writeln("Could not bind");
    }
    
  }
/*
Free server resources
TODO: Create a destructor
*/
  proc Close(){
    event_base_dispatch(this.ebase);
    evhttp_free(this.server);
    event_base_free(this.ebase);
  }

}

/*
Register this instance to an ip address
*/
proc RegisterServer(server:Server){
  handlerList[server.getAddress()] = server;
}

/*
Url router class.
This class registers and routes the requests to chapel function accoriding to http verbs and registred urls.

*/

class Router{

var MiddleWareDomain:domain(string);
var MiddleWareList:[MiddleWareDomain]func(Request,  Response, func(Request,  Response) ,void);

var GetRouterDomain: domain(string);
var GetList:[GetRouterDomain]func(Request,  Response,void);

var PostRouterDomain: domain(string);
var PostList:[PostRouterDomain]func(Request,  Response,void);

var PutRouterDomain: domain(string);
var PutList:[PutRouterDomain]func(Request,  Response,void);

var DeleteRouterDomain: domain(string);
var DeleteList:[DeleteRouterDomain]func(Request,  Response,void);

var HeadRouterDomain: domain(string);
var HeadList:[HeadRouterDomain]func(Request,  Response,void);

var OptionsRouterDomain: domain(string);
var OptionsList:[OptionsRouterDomain]func(Request,  Response,void);

var TraceRouterDomain: domain(string);
var TraceList:[TraceRouterDomain]func(Request,  Response,void);

var ConnectRouterDomain: domain(string);
var ConnectList:[ConnectRouterDomain]func(Request,  Response,void);

var PatchRouterDomain: domain(string);
var PatchList:[PatchRouterDomain]func(Request,  Response,void);

  proc Router(){
   


  }
/*
TODO: Add middleware request interceptors
*/
  proc Middelware(foo:func(Request,  Response)){

  }

  /*
Assigns GET url to a function handler.
  */

  proc Get(url:string, handler:func(Request,  Response,void) ){
    GetList[url] = handler;   
  }
   
/*
Assigns Post url to a function handler.
  */

  proc Post(url:string, handler:func(Request,  Response,void) ){
    PostList[url] = handler;   
  }
  /*
Assigns Put url to a function handler.
  */

  proc Put(url:string, handler:func(Request,  Response,void) ){
    PutList[url] = handler;   
  }
  /*
Assigns Delete url to a function handler.
  */
  proc Delete(url:string, handler:func(Request,  Response,void) ){
    DeleteList[url] = handler;   
  }
/*
Assigns Head url to a function handler.
  */

proc Head(url:string, handler:func(Request,  Response,void)){
    HeadList[url] = handler;     
}
/*
Assigns Options url to a function handler.
  */

proc Options(url:string, handler:func(Request,  Response,void)){
    OptionsList[url] = handler;     
}
/*
Assigns Trace url to a function handler.
  */

proc Trace(url:string, handler:func(Request,  Response,void)){
    TraceList[url] = handler;     
}
/*
Assigns Connect url to a function handler.
  */

proc Connect(url:string, handler:func(Request,  Response,void)){
    ConnectList[url] = handler;     
}
/*
Assigns Patch url to a function handler.
  */

proc Patch(url:string, handler:func(Request,  Response,void)){
    PatchList[url] = handler;     
}
  
/*

This Method Routes the incoming request to the assigned functions.
*/
proc Process(request:c_ptr(evhttp_request),  privParams:opaque){

    var uris = new string( evhttp_request_get_uri(request));
    var uri =  evhttp_uri_parse_with_flags(uris.localize().c_str(),0);
    var path = new string(evhttp_uri_get_path(uri));
    var req = new  Request(request,privParams);
    var cmd = req.getCommand();
    var res = new Response(request,privParams);

    if(cmd=="GET"){

      writeln(this.GetRouterDomain.member(path)," = ",path);
          if(this.GetRouterDomain.member(path)!=false){
            var controller = this.GetList[path];       
            controller(req,res);
            writeln("Served ", path);
          }else{
            res.E404();
          }      
    }

    if(cmd=="POST"){
          if(this.PostRouterDomain.member(path)!=false){
            var controller = this.PostList[path];       
            controller(req,res);
            writeln("Served ", path);
          }else{
            res.E404();
          }      

    }
    if(cmd=="HEAD"){
          if(this.HeadRouterDomain.member(path)!=false){
            var controller = this.HeadList[path];       
            controller(req,res);
            writeln("Served ", path);
          }else{
            res.E404();
          }      

    }
    if(cmd=="TRACE"){
          if(this.TraceRouterDomain.member(path)!=false){
            var controller = this.TraceList[path];       
            controller(req,res);
            writeln("Served ", path);
          }else{
            res.E404();
          }      

    }
    if(cmd=="CONNECT"){
          if(this.ConnectRouterDomain.member(path)!=false){
            var controller = this.ConnectList[path];       
            controller(req,res);
            writeln("Served ", path);
          }else{
            res.E404();
          }      

    }
    if(cmd=="PATCH"){
          if(this.PatchRouterDomain.member(path)!=false){
            var controller = this.PatchList[path];       
            controller(req,res);
            writeln("Served ", path);
          }else{
            res.E404();
          }      

    }
    if(cmd=="PUT"){
          if(this.PutRouterDomain.member(path)!=false){
            var controller = this.PutList[path];       
            controller(req,res);
            writeln("Served ", path);
          }else{
            res.E404();
          }      

    }
    if(cmd=="DELETE"){
          if(this.DeleteRouterDomain.member(path)!=false){
            var controller = this.DeleteList[path];       
            controller(req,res);
            writeln("Served ", path);
          }else{
            res.E404();
          }      
    }

  delete req;

  }
 
}
/*
Request Class.
This class holds information about Request infomration.
*/
class Request{
  var handle:c_ptr(evhttp_request);
  var Command:string;
  var params:evkeyvalq;
  var buffer:c_ptr(evbuffer);
  var uri:c_ptr(evhttp_uri);
  var uriStr:string;
  var OutHeaders:c_ptr(evkeyvalq);
  proc Request(request:c_ptr(evhttp_request),  privParams:opaque){
    this.handle = request;
    this.buffer = evhttp_request_get_input_buffer(this.handle);
    this.uriStr = new string( evhttp_request_get_uri(this.handle));
    this.uri =  evhttp_uri_parse_with_flags(this.uriStr.localize().c_str(),0);

    this.OutHeaders = evhttp_request_get_input_headers(request);

    //Parses the body of requests
    if(this.getCommand()=="GET"){
      this.ParseUriParams();
    }
    //TODO: Refactor
    if(this.getCommand()=="POST"){
      this.ParseBody();
    }

    if(this.getCommand()=="PUT"){
      this.ParseBody();
    }
 
  }
/*
Parses the uri parametrs
*/
  proc ParseUriParams(){
    var query = evhttp_uri_get_query(this.uri);
    evhttp_parse_query_str(query, this.params);
  }
/*
Parses the body of POST,PUT etc. requests
*/
  proc ParseBody(){
    var len = evbuffer_get_length(this.buffer);
    var data = c_calloc(uint(8), (len+1):size_t);
    evbuffer_copyout(this.buffer, data, len);
    var dados = new string(buff=data, length=len, size=len+1, owned=true, needToCopy=false);
    evhttp_parse_query_str(dados.localize().c_str(), this.params);
  }

/*
Gets request parameter by name.
*/
  proc Input(key:string):string{
      return new string(evhttp_find_header(this.params, key.localize().c_str()));
  }
/*
Gets Request Command Verb.
*/
  proc getCommand():string{
    var cmd = evhttp_request_get_command (this.handle);

    select( cmd ){
 
      when EVHTTP_REQ_GET do return "GET";
      when EVHTTP_REQ_POST do return "POST";
      when EVHTTP_REQ_PUT do return "PUT";
      when EVHTTP_REQ_HEAD do return "HEAD";
      when EVHTTP_REQ_OPTIONS do return "OPTIONS";
      when EVHTTP_REQ_TRACE do return "TRACE";
      when EVHTTP_REQ_CONNECT do return "CONNECT";
      when EVHTTP_REQ_PATCH do return "PATCH";     
      otherwise {
       return "UNKNOWN";
     }
    }
  }

/*
Gets a content of a HTTP header.
*/
proc GetHeader(header:string ):string{
   return new string(evhttp_find_header(this.OutHeaders,header.localize().c_str()));
}
/*
Gets Cookie
TODO: Pares cookie content.
*/
  proc GetCookie(){
    writeln(this.GetHeader("Cookie"));
  }

}
/*
Response Class.
This class has the information to be sent to the cliente as a response. 

*/
class Response{

var buffer:c_ptr(evbuffer);
var handle:c_ptr(evhttp_request);

  proc Response(request:c_ptr(evhttp_request),  privParams:opaque){
    this.handle = request;
    this.buffer = evbuffer_new();
  }
  /*
  
  Writes contents
  */
  proc Write(str ...?vparams){
    for param el in 1..vparams{     
         this._print(str[el]);
    }
  }
  proc _print(str:?eltType){
    select eltType{
      when int{
        evbuffer_add_printf(this.buffer, "%d".localize().c_str(), str);
      }
      when real{
        evbuffer_add_printf(this.buffer, "%f".localize().c_str(), str);
      }
      when string{
        evbuffer_add_printf(this.buffer, "%s".localize().c_str(), str.localize().c_str());
      }
      otherwise{
      }
    }
  }
/*
Sends the content to the client
*/
  proc Send(code:int=HTTP_OK,motiv:string="OK"){
    this.AddHeader("X-Powered-By","Chapel Http");
    evhttp_send_reply(this.handle, code, motiv.localize().c_str(), this.buffer);
    //evhttp_clear_headers(&headers);
    //evbuffer_free(buffer);
  }
  /*
  Error msg
  */
  proc E404(str:string=""){
    this.Write("Not Found");
    this.Send(404,"Not Found");
  }
  /*
  
  Adds a HTTP header to response
  */
  proc AddHeader(header:string,value:string):int{     
     return evhttp_add_header(evhttp_request_get_output_headers(this.handle) ,header.localize().c_str(),value.localize().c_str()):int;
  }
/*
Sets Cookie.
TODO: Add options.
*/
  proc SetCookie(key:string, value:string, path:string ="/"){
    //Set-Cookie: sessionid=38afes7a8; httponly; Path=/
      this.AddHeader("Set-Cookie", key+"="+value+"; httponly; Path="+path);
  } 

}

/*
This function is a trampoline for the callback.
*/
export proc http_handler( request:c_ptr(evhttp_request), privParams:opaque){
    for hd in handlerDomain{
      //Calls all routers
      handlerList[hd].getRouter().Process(request, privParams);
    }
 }
}

