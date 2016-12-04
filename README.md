# chapel-http
Http server in Chapel language.

## Installation

This module is a thin layer over Libevent2. You should have libevent2 installed in you computer in order to get module compiled.

For more info go to [libevent project site](http://libevent.org/).

For Ubuntu you can type:
```bash
sudo apt-get install libevent-dev
``` 

## Test the example

To compile the example and test this module you should type in the project folder:
```bash
bash build.sh 

```

Run the sever:
```bash
./srv 

```

Go to [localhost:9000/](localhost:9000/).

## A simple Hello World http server in Chapel.
```chapel

module Main{
use Http;

proc main(){

    //Creates A server in the port 9000
    var server =new Server("127.0.0.1",9000);
    //Get  url Router object
    var routerHandler = server.getRouter();
    //Assigns GET / url to a anonymous function 
    routerHandler.Get("/",lambda(req:Request, res:Response):void{
        //req representes the current request, res represents the current response
        //content of the page
    var html="<html><body>\
    <form method='POST' action='/'>\
    Login:</br>\
    <input name='login'>\
    Password:</br>\
    <input name='password'>\
    <button>Ok</button>\
    </form><br/>\
    <a href='/home'>Home</a>\
    </body>\
    </html>";
    // res.Write method puts contents to the response buffer.
    res.Write(html);
    //Send the buffer to the client
    res.Send();
  });
//Assigns POST /url to a anonymous function
 routerHandler.Post("/",lambda(req:Request,  res:Response):void{

     //Gets the parameters from form.
     var login:string = req.Input("login"); 
     var password = req.Input("password");

     if(password=="123456"){
         res.Write("Welcome ", login,"! You are logged");
     }else{
         res.Write("Hi ", login,"Your password is wrong");
     }
     res.Write("<br/><a href='/'>Back</a>");
     res.Send();
  });
   
   // Assign th /home url to home procedure.
  routerHandler.Get("/home",home_page);

// Eventloop for requests;
  server.Listen();
  //Closes resources 
  server.Close();  
  }


//Controller function that will handle the GET /home request.
proc home_page(req:Request,  res:Response):void{
    res.Write("Hello World!! <a href='/'>Back</a>");
    res.Send();
}

}


```

# Warning.
This is the heavly untested. It is not secure nor production ready! 

# TODO

* The Documentation.
* Session Menangement.
* Serve content from filesystem.
* JWT Token.
* Middleware.
* JSON response,request.
* Websocket support.
* HTTPS support.
* Translate to Portuguese.
* Rewrite to the parallel environoment.

Obs. This list is not ordered by priority.

# To Contribute

All are wellcome to contribute with this module.
