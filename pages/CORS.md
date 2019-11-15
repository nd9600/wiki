# What's the problem?

You'll probably see something like
```
CORS header 'Access-Control-Allow-Origin' missing
```
in the console when making a request

[CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS), Cross-Origin Resource Sharing, is a way for browsers to make requests from one [origin](https://developer.mozilla.org/en-US/docs/Glossary/Origin) to another (_cross-origin_) - we get this when we make a request from `messaging.freetobook.com` to `freetobook.com` (if two URLs have a different scheme, domain, or port, they've a different origin), or even locally, from `https://localhost` to `https://localhost:85`

Browsers by default won't let you make an AJAX request from one origin to another, unless the server you're making the request to  explicitly allows it to, _from_ the specific origin you're making the request from: it has to say, "yes, you're allowed to make a request from foo.bar.com".

# When does the browser allow cross-origin requests?
Generally, your request will need to come from an origin that the server allows, which it says by having its response to the request include an `Access-Control-Allow-Origin` HTTP header that matches the request's origin.

## Simple/preflight requests
Some requests will first need a [preflight requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#Preflighted_requests) request to made first, if they're not [simple requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#Simple_requests).

If the preflight request fails, you won't be able to make the actual CORS request.

A simple request must match all of these conditions (there are others):
* Is `GET`, `HEAD` or `POST`
* No headers that haven't been set by the user agent, apart from
```
Accept
Accept-Language
Content-Language
Content-Type (but note the additional requirements below)
DPR
Downlink
Save-Data
Viewport-Width
Width
```
* `Content-Type` must be
```
application/x-www-form-urlencoded
multipart/form-data
text/plain
``` 

So if your content type is different, or you have a CSRF token in the request, for example, the browser will make a preflight request first.

**A preflight request is to the same URL** as the resource you want, but with the `OPTIONS` HTTP method.
**You must return a HTTP success**  to the preflight request.

# How do you fix it?
On the server, you must allow a specific origin to make requests to the server/that specific endpoint.

You do that by having the response to the request include these HTTP headers:
```
Access-Control-Allow-Origin
Access-Control-Allow-Headers
Access-Control-Allow-Methods
```
All these headers must match your request: your origin must match whatever `Access-Control-Allow-Origin` is, your HTTP headers must be in `Access-Control-Allow-Headers`, and your HTTP method must match one of `Access-Control-Allow-Methods`:

## HTTP Headers

### `Access-Control-Allow-Origin`
This can either be `*`, or a **single** specific origin.
If you want to allow requests from multiple different origins, you should check if the origin in the request matches one in your approved list, then set `Access-Control-Allow-Origin` to be that origin, if it does.

### `Access-Control-Allow-Headers`
This can be a comma-separated list, or `*` again:
```
Access-Control-Allow-Headers: Authorization, Content-Type, X-Requested-With, x-csrf-token, Access-Control-Allow-Origin
```

### `Access-Control-Allow-Methods`
This can be a comma-separated list, or `*`
