/*
WebRequest - XMLHttpRequest wrapper using promised and ES6 OOP
GET Usage:
	var req = new WebRequest('get','http://my.site/page.html');
	
POST Usage (data argument can be URL encoded string also):
	var req = new WebRequest('post','http://my.site/page.html',{
		data: {
			name : 'bob',
			age : 43
		},
		headers : {
			'Content-type':'text/javascript'
		}
	});
	
Retrieving the response:
	req.response.then(resp => {
		Object.keys(resp.headers).forEach(x =>
			console.log(x + ': ' + resp.headers[x] + '\n');
		});
		console.log(resp.body);
	}).catch(resp => {
		console.log(resp.status + ' - ' + resp.body);
	});
	
Streamlined execution:
	(new WebRequest('get','http://my.site/page.html')).response.then(resp =>
		console.log(resp.body);
	});
	
If using with Node:
	1) Run npm install xmlhttprequest
	2) Uncomment the "const XMLHttpRequest ..." line at the top of this file
*/

//const XMLHttpRequest = require('xmlhttprequest').XMLHttpRequest;

class WebRequest {
        constructor(method,url,payload) {
                this.method = method;
                this.url = url;
		if (payload) {
                  this.data = (Object.keys(payload).indexOf('data') > -1) ? payload.data : false;
		  this.headers = (Object.keys(payload).indexOf('headers') > -1) ? payload.headers : false;
		}
		else {
		  this.data = false;
		  this.headers = false;
		}
                
                this.xhr = new XMLHttpRequest();
                this.xhr.open(this.method,this.url,true);
		
		if (this.headers) {
		        Object.keys(this.headers).forEach(h => {
			        this.xhr.setRequestHeader(h,this.headers[h]);
			});
		}
                
                this.response = new Promise((success,error) => {
                        this.xhr.onload = () => {
                                success({
                                        'status' : this.xhr.status,
                                        'headers' : () => {
                                                var returnValue = {};
                                                this.xhr.getAllResponseHeaders().replace(/\r/g,'').split('\n').filter(x => x.length > 0).forEach(x => {
                                                        var key = x.replace(/^([^:]+):.*$/,"$1");
                                                        var value = x.replace(/^[^:]+:(.*)$/,"$1");
                                                        returnValue[key] = value;
                                                });
                                                return returnValue;
                                        },
                                        'body' : this.xhr.responseText
                                });
                        };
                        			
                        this.xhr.onerror = () => {
                                error({
                                        'status' : this.xhr.status,
                                        'body' : this.xhr.statusText
                                });
                        };
                });
		
                if (this.data)
                        this.xhr.send(this.data);
                else
                        this.xhr.send();
        }
}
