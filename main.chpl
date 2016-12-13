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
  * Simple hello world http in chapel language.
  *
  *
  *
  */
module Main{
use Http;


//This middleware logs uri in console.
class TestMiddleware:Middleware{

    proc Run(ref req:Request, ref res:Response){
        writeln("Middleware3::  My Uri =",req.getUri() );
    }
}

//This middleware class 
class TestMiddleware2:Middleware{


    proc Run(ref req:Request, ref res:Response){
       
      var cc = req.ListCookies();
      
      for k in cc.domain{
            writeln("Middleware2:: Cookie:",k,">>",cc[k]);
      }

    }
}
//This middleware class logs user agent
class TestMiddleware3:Middleware{


    proc Run(ref req:Request, ref res:Response){

        writeln("Middleware3:: User Agent:",req.GetHeader("User-Agent"));
       
    }
}

proc main(){
    //Creates A server in the port 9000
    var server =new Server("127.0.0.1",9000);
    //Get  url Router object
    var routerHandler = server.getRouter();

    //Register the middlewares object
    routerHandler.Middlewares((new TestMiddleware()):Middleware,new TestMiddleware2(),new TestMiddleware3());


    //Assigns GET / url to a anonymous function 
    routerHandler.Get("/",lambda(req:Request, res:Response):void{
        //req representes the current request, res represents the current response
        //content of the page
   var html="<html><body>\
    <form method='POST' action='/'>\
    Login:</br>\
    <input name='login'>\
    <br/>Password:\
    <input name='password'>\
    <button>Ok</button>\
    </form><br/>\
    <a href='/home'>Home</a>\
    </body>\
    </html>";


    res.SetCookie("Teste1","1");
    res.SetCookie("Teste2","2");


  
    // res.Write method puts contents to the response buffer.
    res.Write(html);
 
 
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

   writeln( req.GetCookie("Teste1"));
   writeln( req.GetCookie("Teste2"));

    res.Write("Hello World!! <a href='/'>Back</a>");
    res.Send();
}

}
