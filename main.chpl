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



 /* proc ServeFile(filepath:string):func(Request,Response,void){

      return lambda(req:Request, res:Response):void{
  // var filepath:string = "./tmpl/test.html";
   if((exists(filepath)&&(isFile(filepath)))){
      var content:string ="";
      var f = open(filepath, iomode.r,
                 hints=IOHINT_RANDOM|IOHINT_CACHED|IOHINT_PARALLEL);
        for line in f.lines() {
            content+=line;
        }
        res.Write(content);
        }else{
            res.E404();
        }
      
      };


  }
*/
proc main(){
    //Creates A server in the port 9000
    var server =new Server("127.0.0.1",9000);
    //Get  url Router object
    var routerHandler = server.getRouter();

    //Register the middlewares object
    //routerHandler.Middlewares((new TestMiddleware()):Middleware,new TestMiddleware2(),new TestMiddleware3(),new FileMiddleware());
   // routerHandler.AfterMiddlewares(new FileMiddleware():Middleware);
    routerHandler.setFileMiddleware(new FileMiddleware());

    routerHandler.File("/test","./tmpl/test.html");
    
     //routerHandler.Get("/test",ServeFile("./tmpl/test.html"));

    //Assigns GET / url to a anonymous function 
    routerHandler.Get("/",lambda(req:Request, res:Response):void{
        //req representes the current request, res represents the current response
        //content of the page
   var html="<html><link href='/css/bootstrap.css' rel='stylesheet' ><body>\
    <div class='container'>\
\
<div class='row' style='margin-top:20px'>\
    <div class='col-xs-12 col-sm-8 col-md-6 col-sm-offset-2 col-md-offset-3'>\
		<form role='form'>\
			<fieldset>\
				<h2>Chapel Based Social Network</h2>\
				<hr class='colorgraph'>\
				<div class='form-group'>\
                    <input type='email' name='email' id='email' class='form-control input-lg' placeholder='Email Address'>\
				</div>\
				<div class='form-group'>\
                    <input type='password' name='password' id='password' class='form-control input-lg' placeholder='Password'>\
				</div>\
				<span class='button-checkbox'>\
					<button type='button' class='btn' data-color='info'>Remember Me</button>\
                    <input type='checkbox' name='remember_me' id='remember_me' checked='checked' class='hidden'>\
					<a href='' class='btn btn-link pull-right'>Forgot Password?</a>\
				</span>\
				<hr class='colorgraph'>\
				<div class='row'>\
					<div class='col-xs-6 col-sm-6 col-md-6'>\
                        <input type='submit' class='btn btn-lg btn-success btn-block' value='Sign In'>\
					</div>\
					<div class='col-xs-6 col-sm-6 col-md-6'>\
						<a href='' class='btn btn-lg btn-primary btn-block'>Register</a>\
					</div>\
				</div>\
			</fieldset>\
		</form>\
	</div>\
</div>\
\
</div>\
    </body>\
    </html>";


    res.SetCookie("Teste1","1");
    res.SetCookie("Teste2","2");


  
    // res.Write method puts contents to the response buffer.
    res.Write(html);
 
 
 // res.Send();
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
 //    res.Send();
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
   // res.Send();
}

}
