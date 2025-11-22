function handler(event) {
  var request = event.request;
  var uri = request.uri;

  // Redirect /foo → /foo/
  if (!uri.includes('.') && !uri.endsWith('/')) {
    return {
      statusCode: 301,
      statusDescription: 'Moved Permanently',
      headers: {
        location: { value: uri + '/' }
      }
    };
  }

  // Rewrite /foo/ → /foo/index.html
  if (uri.endsWith('/')) {
    request.uri += 'index.html';
  }

  return request;
}

