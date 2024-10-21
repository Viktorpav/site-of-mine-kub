function handler(event) {
    const request = event.request;
    const headers = request.headers;
    const host = headers.host.value;
    const uri = request.uri;
    console.log('Host:', host);
    console.log('URI:', uri);
    console.log('Request:', JSON.stringify(request, null, 2));

    try {
        // If it's an API request, pass it through without modification
        if (uri.startsWith("/api")) {
            console.log('API request detected, passing through');
            return request;
        }

        // Redirect www requests to non-www for non-API requests
        if (host.startsWith("www.") && !host.startsWith("api.")) {
            console.log('Redirecting www to non-www');
            return {
                statusCode: 301,
                statusDescription: "Permanently moved",
                headers: {
                    location: {
                        value: `https://${host.replace("www.", "")}${uri}`,
                    },
                },
            };
        }

        // For all other requests, return the request as-is
        console.log('Non-API request, returning as-is');
        return request;
    } catch (err) {
        console.error('Error in CloudFront function:', err);
        return {
            statusCode: 500,
            statusDescription: "Internal Server Error",
            headers: {
                "content-type": {
                    value: "text/plain"
                },
            },
            body: "An error occurred: " + (err instanceof Error ? err.message : JSON.stringify(err)),
        };
    }
}