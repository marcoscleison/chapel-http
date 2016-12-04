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
