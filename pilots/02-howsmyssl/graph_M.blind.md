## Symptom

`https://www.howsmytls.com/a/check` returns a `301 Moved Permanently` redirect to the canonical `howsmyssl.com` host, but the redirect response itself has `Content-Type: text/html; charset=utf-8` and an HTML body even when the client sends `Accept: application/json`.

## Localization (file:line + quoted snippet)

`howsmyssl.go:316-329`

```go
func tlsMux(routeHost, redirectHost, acmeRedirectURL string, staticHandler http.Handler, webHandleFunc http.HandlerFunc, oa *originAllower, requestLogger *slog.Logger, allowLogger *slog.Logger) http.Handler {
	acmeRedirectURL = strings.TrimRight(acmeRedirectURL, "/")
	m := http.NewServeMux()
	m.Handle(routeHost+"/s/", staticHandler)
	m.Handle(routeHost+"/a/check", &apiHandler{oa: oa, allowLogger: allowLogger})
	m.HandleFunc(routeHost+"/", webHandleFunc)
	m.HandleFunc(routeHost+"/healthcheck", healthcheck)
	if routeHost != "" {
		m.HandleFunc("/healthcheck", healthcheck)
	}
	m.Handle(routeHost+"/.well-known/acme-challenge/", acmeRedirect(acmeRedirectURL))
	if routeHost != "" {
		m.Handle("/", commonRedirect(redirectHost))
	}
```

`howsmyssl.go:482-490`

```go
func commonRedirect(redirectHost string) http.Handler {
	hf := func(w http.ResponseWriter, r *http.Request) {
		commonRedirects.Add(1)
		u := r.URL
		// Never set by the Go HTTP library.
		u.Scheme = "https"
		u.Host = redirectHost
		http.Redirect(w, r, u.String(), http.StatusMovedPermanently)
	}
```

`howsmyssl.go:381-393`

```go
func allowedRenderJSON(r *http.Request, data *clientInfo) ([]byte, int, string, error) {
	callback := r.FormValue("callback")
	sanitizedCallback := nonAlphaNumeric.ReplaceAll([]byte(callback), []byte(""))

	marshalled, err := json.Marshal(data)
	if err != nil {
		return nil, 0, htmlContentType, err
	}
	if len(sanitizedCallback) > 0 {
		return fmt.Appendf(nil, "%s(%s);", sanitizedCallback, marshalled), http.StatusOK, "application/javascript", nil
	}

	return marshalled, http.StatusOK, "application/json", nil
}
```

## Root-cause hypothesis

The request to `www.howsmytls.com/a/check` is not reaching `apiHandler`.

`tlsMux` registers the API endpoint as a host-specific ServeMux pattern: `routeHost + "/a/check"`. When the configured `routeHost` is the canonical `www.howsmyssl.com`, a request whose Host is `www.howsmytls.com` does not match that API route. Because `routeHost != ""`, the mux also installs the generic fallback pattern `/`, which sends all non-canonical host traffic through `commonRedirect`.

`commonRedirect` then calls Go's `http.Redirect` without pre-setting `Content-Type`. Go's redirect helper sets `Content-Type` to `text/html; charset=utf-8` and writes a small HTML body when no content type has already been set. Since `commonRedirect` does not inspect `Accept` and does not special-case `/a/check`, the JSON endpoint alias redirect inherits the default HTML redirect body.

## Rivals considered and killed

1. The JSON API renderer ignores `Accept: application/json`.

Killed by routing evidence. `allowedRenderJSON` always returns `application/json` for normal `/a/check` responses, and `disallowedRenderJSON` also returns `application/json` for non-JSONP disallowed requests. The bad response is a `301`, while the API renderer returns `200` or `400`; therefore the request has already missed `apiHandler` and landed in `commonRedirect`.

2. The web handler is producing HTML for `/a/check`.

Killed by host-specific route setup. `handleWeb` is registered as `routeHost + "/"`, so it only catches canonical-host web paths. The non-canonical host is caught by the plain `/` fallback at `howsmyssl.go:328`, which calls `commonRedirect`, not `handleWeb`.

## Predicted fix shape

Make `commonRedirect` content-type-aware, or add an API-specific redirect path before the generic fallback.

The minimal shape is to set the redirect response `Content-Type` before calling `http.Redirect` when the request is for `/a/check` or when the request advertises JSON, and optionally write a tiny JSON body such as `{}` or an error object. Because Go's `http.Redirect` suppresses its default HTML body when `Content-Type` has already been set, this can preserve the existing `301 Location` behavior while making the redirect body MIME-compatible for API clients.

A slightly more explicit shape is to register a non-host-specific `/a/check` handler that performs the canonical-host redirect with `application/json`, leaving the existing generic `/` redirect unchanged for browser/web traffic.
