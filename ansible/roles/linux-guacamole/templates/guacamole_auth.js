import querystring from "querystring";

// This function runs when the /api/tokens endpoint is requested
// It calls the proxied service, injecting the known credentials
const getApiTokenResponse = (req) => {
  if (req.method.toLowerCase() === "post") {
    const upstreamURL = `http://127.0.0.1:8080/guacamole/api/tokens`;
    const headers = { "Content-Type": "application/x-www-form-urlencoded" };
    const body = querystring.stringify({
      username: "portal",
      password: "portal",
    });
    /* eslint-disable no-undef */
    ngx
      .fetch(upstreamURL, { method: "POST", headers, body: Buffer.from(body) })
      .then((resp) => resp.text().then((text) => [resp.status, text]))
      .then((args) => req.return(args[0], args[1]));
    /* eslint-enable no-undef */
  } else {
    req.return(400);
  }
};

// Export functions for querying the user and groups
export default { getApiTokenResponse };
